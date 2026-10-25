import os

from kittens.tui.handler import result_handler


def main(args):
    pass


def proc_stat(pid):
    with open(f'/proc/{pid}/stat') as f:
        # comm can contain spaces and parens, so split after the last ')'
        return f.read().rsplit(')', 1)[1].split()


def shpool_daemon():
    for pid in filter(str.isdigit, os.listdir('/proc')):
        try:
            with open(f'/proc/{pid}/cmdline', 'rb') as f:
                argv = f.read().split(b'\0')
            if os.stat(f'/proc/{pid}').st_uid == os.getuid() and argv[0].endswith(b'shpool') and b'daemon' in argv[1:]:
                return pid
        except OSError:
            continue


def session_cwd(name):
    """The directory of a shpool session's shell, which kitty can't see: the
    pane's own process is only the `shpool attach` client."""
    daemon = shpool_daemon()
    if daemon is None:
        return None
    for pid in filter(str.isdigit, os.listdir('/proc')):
        try:
            if proc_stat(pid)[1] != daemon:
                continue
            with open(f'/proc/{pid}/environ', 'rb') as f:
                if f'SHPOOL_SESSION_NAME={name}'.encode() in f.read().split(b'\0'):
                    return os.readlink(f'/proc/{pid}/cwd')
        except OSError:
            continue


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    """`launch` that starts in the focused pane's shell directory, even when
    the pane runs inside a shpool session."""
    window = boss.window_id_map.get(target_window_id)
    name = window.user_vars.get('shpool') if window else None
    cwd = session_cwd(name) if name else None
    boss.launch(*args[1:], f'--cwd={cwd}' if cwd else '--cwd=current')
