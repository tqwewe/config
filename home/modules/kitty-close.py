import subprocess

from kittens.tui.handler import result_handler

SHPOOL = '@shpool@'


def main(args):
    pass


def kill_sessions(windows):
    names = [w.user_vars['shpool'] for w in windows if w.user_vars.get('shpool')]
    if names:
        subprocess.Popen([SHPOOL, 'kill', *names], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return names


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    """Closes the pane (or with `tab`, the whole tab) and ends its shpool
    sessions, rather than leaving them detached."""
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    if args[1:2] == ['tab']:
        tab = window.tabref()
        if tab is not None:
            kill_sessions(list(tab))
            boss.close_tab(tab)
    elif not kill_sessions([window]):
        # A pane with a session closes itself once the session is gone.
        boss.mark_window_for_close(window)
