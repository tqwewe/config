from kittens.tui.handler import result_handler

ANNOTATE_ACTION = '@annotateAction@'


def main(args):
    pass


def annotation_window(tab):
    """The annotation overlay in `tab`, tagged by the launch action's --var."""
    if tab is None:
        return None
    return next((w for w in tab if w.user_vars.get('annotate')), None)


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    overlay = annotation_window(boss.active_tab)
    if overlay is not None:
        boss.mark_window_for_close(overlay)
    else:
        boss.combine(ANNOTATE_ACTION)
