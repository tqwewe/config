import json
import subprocess

from kittens.tui.handler import result_handler

SHPOOL = '@shpool@'
KITTY_SHPOOL = '@kittyShpool@'


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    """Reopens every detached shpool session in its own tab, oldest first, e.g.
    after kitty closed with sessions still running."""
    out = subprocess.run([SHPOOL, 'list', '--json'], capture_output=True, text=True).stdout
    sessions = json.loads(out or '{}').get('sessions', [])
    detached = sorted(
        (s for s in sessions if s.get('status') == 'Disconnected'),
        key=lambda s: s.get('started_at_unix_ms', 0),
    )
    if not detached:
        boss.show_error('Nothing to restore', 'There are no detached shpool sessions.')
        return
    window = boss.window_id_map.get(target_window_id)
    for session in detached:
        boss.call_remote_control(window, ('launch', '--type=tab', KITTY_SHPOOL, 'attach', session['name']))
