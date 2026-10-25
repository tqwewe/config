import json
import os
import subprocess
import time

import kitty.tab_bar as kitty_tab_bar
import kitty.tabs as kitty_tabs
from kitty.boss import get_boss
from kitty.colors import patch_colors
from kitty.fast_data_types import GLFW_MOUSE_BUTTON_LEFT, GLFW_PRESS, GLFW_RELEASE, add_timer, current_focused_os_window_id, get_options
from kitty.tab_bar import as_rgb, draw_tab_with_powerline
from kitty.utils import color_as_int, log_error

PW_PLAY = '@pwPlay@'
DONE_SOUND = '@doneSound@'
REQUEST_SOUND = '@requestSound@'

STATE_DIR = os.path.join(os.environ.get('XDG_RUNTIME_DIR') or f'/tmp/kitty-agents-{os.getuid()}', 'kitty-agents')
TICK_INTERVAL = 0.25
INTERRUPT_GRACE = 2.0
SPINNER = '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
ANNOTATE_ICON = '\uf040'
# Segment id for the annotate button; kitty window ids start at 1.
ANNOTATE = 0

COLORS = {
    'working': 0xFEE92E,
    'blocked': 0xE83A3F,
    'done': 0x53A4F3,
    'idle': 0x9E9E9E,
}
ORDER = {'blocked': 0, 'working': 1, 'done': 2, 'idle': 3}
# Active border colour per keyboard mode; 'prefix' covers ctrl+p / ctrl+t.
MODE_COLORS = {'move': 0xFEE92E, 'resize': 0xF5971D, 'prefix': 0x53A4F3}
FULL_BORDER_MODES = ('move', 'resize')

# Shared across config reloads, which re-run this module with runpy.
if not hasattr(kitty_tab_bar, '_agents'):
    kitty_tab_bar._agents = {
        'sessions': {},  # window_id -> {'state', 'cwd', 'unseen', 'order'}
        'segments': {},  # os_window_id -> [(x0, x1, window_id)]
        'frame': 0,
        'counter': 0,
        'installed': False,
    }
agents = kitty_tab_bar._agents
agents.setdefault('quiet', {})  # window_id -> (hook ts, when the spinner stopped)
agents.setdefault('spun', set())  # windows whose title has shown the spinner


def play(path):
    try:
        subprocess.Popen(
            [PW_PLAY, path],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as err:
        log_error(f'kitty-agents: failed to play sound: {err}')


def is_focused(boss, window_id):
    """True when the window's tab is the active tab of the focused OS window."""
    window = boss.window_id_map.get(window_id)
    if window is None:
        return False
    tab = window.tabref()
    if tab is None or tab.os_window_id != current_focused_os_window_id():
        return False
    tm = boss.os_window_map.get(tab.os_window_id)
    return tm is not None and tm.active_tab is tab


def is_active_window(boss, window_id):
    window = boss.window_id_map.get(window_id)
    return window is not None and is_focused(boss, window_id) and window.tabref().active_window is window


def read_states(boss):
    """Maps window id to hook state. Files are keyed by shpool session name when
    Claude runs inside one (matched to the pane that last attached it), and by
    kitty pid and window id otherwise."""
    prefix = f'{os.getpid()}-'
    shpool_windows = {w.user_vars.get('shpool'): w.id for w in boss.window_id_map.values() if w.user_vars.get('shpool')}
    states = {}
    try:
        names = os.listdir(STATE_DIR)
    except FileNotFoundError:
        return states
    for name in names:
        if not name.endswith('.json'):
            continue
        path = os.path.join(STATE_DIR, name)
        if name.startswith('shpool-'):
            # Detached sessions keep their file until Claude exits in them.
            window_id = shpool_windows.get(name[len('shpool-'):-len('.json')])
            if window_id is None:
                continue
        elif name.startswith(prefix):
            try:
                window_id = int(name[len(prefix):-len('.json')])
            except ValueError:
                continue
            if window_id not in boss.window_id_map:
                try:
                    os.remove(path)
                except OSError:
                    pass
                continue
        else:
            continue
        try:
            with open(path) as f:
                states[window_id] = json.load(f)
        except (OSError, ValueError):
            continue
    return states


def title_is_busy(boss, window_id):
    """Claude Code prefixes its title with a spinner glyph while a turn runs."""
    window = boss.window_id_map.get(window_id)
    title = window.title if window is not None else ''
    return bool(title) and ('⠀' <= title[0] <= '⣿' or '◐' <= title[0] <= '◓')


def effective_state(boss, window_id, data):
    """The hook's state, except that interrupting a turn fires no Stop hook, so a
    `working` session whose title spinner has stopped for a while is idle."""
    state = data.get('state', 'idle')
    quiet, spun = agents['quiet'], agents['spun']
    if state != 'working' or title_is_busy(boss, window_id):
        if state == 'working':
            spun.add(window_id)
        quiet.pop(window_id, None)
        return state
    # Only trust the title for sessions seen spinning, in case titles are disabled.
    if window_id not in spun:
        return state
    ts = data.get('ts')
    since = quiet.get(window_id)
    if since is None or since[0] != ts:
        quiet[window_id] = (ts, time.monotonic())
        return state
    return 'idle' if time.monotonic() - since[1] > INTERRUPT_GRACE else state


def tick(timer_id=None):
    boss = get_boss()
    sessions = agents['sessions']
    changed = False

    states = read_states(boss)
    for window_id in list(sessions):
        if window_id not in states:
            del sessions[window_id]
            changed = True

    for window_id, data in states.items():
        state = effective_state(boss, window_id, data)
        cwd = data.get('cwd') or ''
        session = sessions.get(window_id)
        if session is None:
            agents['counter'] += 1
            sessions[window_id] = {'state': state, 'cwd': cwd, 'unseen': False, 'order': agents['counter']}
            changed = True
            continue
        prev = session['state']
        if state != prev:
            if state == 'blocked':
                play(REQUEST_SOUND)
            elif state == 'idle' and prev == 'working' and not is_focused(boss, window_id):
                play(DONE_SOUND)
                session['unseen'] = True
            if state != 'idle':
                session['unseen'] = False
            session['state'] = state
            changed = True
        if session['cwd'] != cwd:
            session['cwd'] = cwd
            changed = True
        if session['unseen'] and is_active_window(boss, window_id):
            session['unseen'] = False
            changed = True

    if any(s['state'] == 'working' for s in sessions.values()):
        agents['frame'] = (agents['frame'] + 1) % len(SPINNER)
        changed = True

    if changed:
        for tm in boss.os_window_map.values():
            tm.mark_tab_bar_dirty()


def display_state(session):
    if session['state'] == 'idle' and session['unseen']:
        return 'done'
    return session['state']


def icon(state):
    if state == 'working':
        return SPINNER[agents['frame']]
    return {'blocked': '?', 'done': '●'}.get(state, '○')


def build_segments():
    items = sorted(agents['sessions'].items(), key=lambda kv: (ORDER[display_state(kv[1])], kv[1]['order']))
    return [(window_id, display_state(s), os.path.basename(s['cwd'].rstrip('/')) or '~') for window_id, s in items]


def layout_segments(segments, available):
    """Return (texts, overflow) fitting within `available` cells."""

    def width(texts, overflow):
        total = sum(len(t) + 1 for _, _, t in texts)
        return total + (len(f' +{overflow}') if overflow else 0)

    full = [(w, st, f' {icon(st)} {name}') for w, st, name in segments]
    if width(full, 0) <= available:
        return full, 0
    compact = [(w, st, f' {icon(st)}') for w, st, _ in segments]
    for keep in range(len(compact), -1, -1):
        overflow = len(compact) - keep
        if width(compact[:keep], overflow) <= available:
            return compact[:keep], overflow
    return [], 0


def annotating(os_window_id):
    """True when the active tab has the annotation overlay (see annotate.py) open."""
    tm = get_boss().os_window_map.get(os_window_id)
    tab = tm.active_tab if tm is not None else None
    return tab is not None and any(w.user_vars.get('annotate') for w in tab)


def draw_right(draw_data, screen, os_window_id, min_x):
    """Draws the session strip and the annotate button, right-aligned."""
    right_pad = 1
    button = f' {ANNOTATE_ICON} '
    available = screen.columns - right_pad - len(button) - min_x - 1
    texts, overflow = layout_segments(build_segments(), available) if available > 0 else ([], 0)

    total = sum(len(t) + 1 for _, _, t in texts) + (len(f' +{overflow}') if overflow else 0) + len(button)
    screen.cursor.bg = as_rgb(color_as_int(draw_data.default_bg))
    screen.cursor.italic = False
    screen.cursor.x = max(min_x, screen.columns - right_pad - total)
    ranges = []
    for window_id, state, text in texts:
        start = screen.cursor.x
        screen.cursor.fg = as_rgb(COLORS[state])
        screen.cursor.bold = state != 'idle'
        screen.draw(text + ' ')
        ranges.append((start, screen.cursor.x, window_id))
    screen.cursor.bold = False
    if overflow:
        screen.cursor.fg = as_rgb(COLORS['idle'])
        screen.draw(f' +{overflow}')
    start = screen.cursor.x
    if annotating(os_window_id):
        screen.cursor.fg = as_rgb(0x212121)
        screen.cursor.bg = as_rgb(COLORS['done'])
        screen.cursor.bold = True
    else:
        screen.cursor.fg = as_rgb(COLORS['idle'])
    screen.draw(button)
    screen.cursor.bold = False
    ranges.append((start, screen.cursor.x, ANNOTATE))
    agents['segments'][os_window_id] = ranges


def sync_mode():
    """While a keyboard mode is active, like zellij, the active border takes the
    mode's colour (MODE_COLORS), and move/resize draw it as a full box round the
    active pane rather than only between panes. kitty redraws the tab bar on
    every mode change, which is what calls this."""
    boss = get_boss()
    mode = boss.mappings.current_keyboard_mode_name
    if mode == agents.get('mode', ''):
        return
    agents['mode'] = mode
    # Patching colors and relayouts redraw the tab bar, so not from inside its draw.
    add_timer(lambda timer_id: apply_mode(mode), 0, False)


def apply_mode(mode):
    boss = get_boss()
    if mode:
        color = MODE_COLORS.get(mode, MODE_COLORS['prefix'])
    else:
        color = boss.color_settings_at_startup.get('active_border_color')
    color = None if color is None else int(color)
    if color != agents.get('border_color'):
        agents['border_color'] = color
        patch_colors({'active_border_color': color})

    # kitty rereads this option on each relayout.
    agents.setdefault('minimal_borders', get_options().draw_minimal_borders)
    minimal = agents['minimal_borders'] and mode not in FULL_BORDER_MODES
    if get_options().draw_minimal_borders != minimal:
        get_options().draw_minimal_borders = minimal
        for tm in boss.all_tab_managers:
            if tm.active_tab is not None:
                tm.active_tab.relayout()


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data):
    end = draw_tab_with_powerline(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
    if is_last and not extra_data.for_layout:
        sync_mode()
        # kitty truncates titles by backing up over them, so wipe the overflow
        # here, since we move the cursor away from where kitty would clear it.
        screen.erase_in_line(0, False)
        draw_right(draw_data, screen, tab.os_window_id, screen.cursor.x)
        screen.cursor.x = screen.columns - 1
    return end


def segment_at(tm, x):
    bar = tm.tab_bar
    g = bar.window_geometry
    if not bar.cell_width or not (g.left <= x < g.right):
        return None
    cell_x = (int(x) - g.left) // bar.cell_width
    for x0, x1, window_id in agents['segments'].get(tm.os_window_id, ()):
        if x0 <= cell_x < x1:
            return window_id
    return None


def install():
    if agents['installed']:
        return
    agents['installed'] = True
    original = kitty_tabs.TabManager.handle_tab_bar_mouse

    def handle_tab_bar_mouse(self, x, y, button, modifiers, action):
        if button == GLFW_MOUSE_BUTTON_LEFT and action in (GLFW_PRESS, GLFW_RELEASE):
            window_id = segment_at(self, x)
            if window_id is not None:
                if action == GLFW_RELEASE:
                    if window_id == ANNOTATE:
                        get_boss().combine('kitten annotate.py')
                    else:
                        get_boss().set_active_window(window_id, switch_os_window_if_needed=True)
                return
        return original(self, x, y, button, modifiers, action)

    kitty_tabs.TabManager.handle_tab_bar_mouse = handle_tab_bar_mouse
    add_timer(tick, TICK_INTERVAL, True)


install()
