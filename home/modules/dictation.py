import io
import os
import queue
import subprocess
import sys
import tempfile
import threading
import time
import wave
from array import array
from collections import deque
from selectors import EVENT_READ, DefaultSelector

import evdev
from evdev import ecodes

KEY = getattr(ecodes, os.environ.get("DICTATE_KEY", "KEY_VOICECOMMAND"))
URL = os.environ["DICTATE_URL"]
RATE = 16000
FRAME_MS = 30
FRAME_BYTES = RATE * 2 * FRAME_MS // 1000
PAUSE_FRAMES = int(os.environ.get("DICTATE_PAUSE_MS", "500")) // FRAME_MS
PREROLL_FRAMES = 8
TAIL_FRAMES = 8
MIN_SPEECH_FRAMES = 6
# a block with less speech than this is a click or a breath, and whisper answers silence with "Thank you."
MIN_BLOCK_SPEECH = 10
SHORT_BLOCK_SPEECH = 15
HALLUCINATIONS = {"thank you", "thanks", "thanks for watching", "thank you for watching", "you", "bye", "okay"}
MIN_LEVEL = 250
# whisper works in 30s windows, so freeze the text and start a fresh block before a block gets long
MAX_BLOCK_FRAMES = 25000 // FRAME_MS
BACKSPACE = ["14:1", "14:0"]

jobs = queue.Queue()


def level(frame):
    samples = array("h", frame)
    return sum(abs(s) for s in samples) / max(len(samples), 1)


def wav_bytes(frames):
    buf = io.BytesIO()
    with wave.open(buf, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(frames))
    return buf.getvalue()


def transcribe(data):
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        tmp.write(data)
        tmp.flush()
        out = subprocess.run(
            ["curl", "-s", URL, "-F", f"file=@{tmp.name}", "-F", "response_format=text", "-F", "temperature=0.0"],
            capture_output=True,
            text=True,
        )
    return " ".join(out.stdout.split())


class Typist:
    """Keeps the typed text in sync with the latest full transcript by backspacing only what changed."""

    def __init__(self):
        self.lock = threading.Lock()
        self.block = None
        self.frozen = ""
        self.typed = ""

    def freeze(self):
        # called when something else touched the text field, so we must never backspace past this point
        with self.lock:
            self.frozen += self.typed
            self.typed = ""

    def update(self, block, text, final):
        with self.lock:
            if block != self.block:
                self.block = block
                self.frozen = ""
                self.typed = ""
            cut = len(os.path.commonprefix([self.frozen, text]))
            target = text[cut:] + (" " if final else "")
            common = len(os.path.commonprefix([self.typed, target]))
            back = len(self.typed) - common
            if back:
                subprocess.run(["ydotool", "key"] + BACKSPACE * back)
            rest = target[common:]
            if rest:
                subprocess.run(["ydotool", "type", "--key-delay", "3", "--", rest])
            self.typed = "" if final else target
            if final:
                self.frozen = ""


typist = Typist()


def worker():
    while True:
        block, data, final, speech = jobs.get()
        try:
            text = transcribe(data)
            if text and not (speech < SHORT_BLOCK_SPEECH and text.lower().strip(" .!?,") in HALLUCINATIONS):
                typist.update(block, text, final)
        except Exception as err:
            print(f"update failed: {err}", file=sys.stderr, flush=True)


class Session:
    """Records while the key is held and posts the whole block's audio at every pause."""

    next_block = 0

    def __init__(self):
        self.proc = subprocess.Popen(
            ["pw-record", "--raw", "--rate", str(RATE), "--channels", "1", "--format", "s16", "-"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        self.thread = threading.Thread(target=self.run, daemon=True)
        self.thread.start()

    def stop(self):
        self.proc.terminate()
        self.thread.join()
        self.proc.wait()

    def run(self):
        preroll = deque(maxlen=PREROLL_FRAMES)
        floor = None
        frames = []
        last_talk = 0
        fresh = 0
        speech = 0
        quiet = 0
        block = Session.next_block
        Session.next_block += 1

        def post(final):
            nonlocal frames, last_talk, fresh, speech, block
            if speech >= MIN_BLOCK_SPEECH and (fresh >= MIN_SPEECH_FRAMES or final):
                jobs.put((block, wav_bytes(frames[: last_talk + TAIL_FRAMES]), final, speech))
            fresh = 0
            if final:
                frames, last_talk, speech = [], 0, 0
                block = Session.next_block
                Session.next_block += 1

        while True:
            frame = self.proc.stdout.read(FRAME_BYTES)
            if len(frame) < FRAME_BYTES:
                break
            lvl = level(frame)
            if floor is None:
                floor = lvl
            talking = lvl > max(floor * 3, MIN_LEVEL)
            if not talking:
                floor = floor * 0.95 + lvl * 0.05

            if talking:
                if not frames:
                    frames.extend(preroll)
                frames.append(frame)
                last_talk = len(frames) - 1
                fresh += 1
                speech += 1
                quiet = 0
            elif frames:
                frames.append(frame)
                quiet += 1
                if quiet == PAUSE_FRAMES:
                    post(final=len(frames) > MAX_BLOCK_FRAMES)
            else:
                preroll.append(frame)
        post(final=True)


def keyboards(known):
    found = []
    for path in evdev.list_devices():
        if path in known:
            continue
        dev = evdev.InputDevice(path)
        # ydotoold's virtual keyboard carries our own keystrokes, which must not count as the user typing
        if "ydotool" not in dev.name and KEY in dev.capabilities().get(ecodes.EV_KEY, []):
            found.append(dev)
        else:
            dev.close()
    return found


def main():
    sel = DefaultSelector()
    known = {}
    last_scan = 0.0
    session = None

    threading.Thread(target=worker, daemon=True).start()

    while True:
        if time.monotonic() - last_scan > 5:
            for dev in keyboards(known):
                known[dev.path] = dev
                sel.register(dev, EVENT_READ)
            last_scan = time.monotonic()
            if not known:
                sys.exit("no keyboard with the configured key found (is the user in the input group?)")

        for sk, _ in sel.select(timeout=5):
            dev = sk.fileobj
            try:
                events = list(dev.read())
            except OSError:
                sel.unregister(dev)
                known.pop(dev.path, None)
                continue
            for ev in events:
                if ev.type != ecodes.EV_KEY:
                    continue
                if ev.code != KEY:
                    # typing or moving the cursor mid-dictation must stop us editing the earlier text
                    if ev.value == 1 and session:
                        typist.freeze()
                    continue
                if ev.value == 1 and session is None:
                    session = Session()
                elif ev.value == 0 and session:
                    session.stop()
                    session = None


main()
