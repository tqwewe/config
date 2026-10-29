from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    direction = {'up': 'top', 'down': 'bottom'}.get(args[1], args[1])
    step = int(args[2])
    window = boss.window_id_map.get(target_window_id)
    tab = boss.active_tab
    if window is None or tab is None:
        return

    horizontal = direction in ('left', 'right')
    before, after = ('left', 'right') if horizontal else ('top', 'bottom')
    neighbors = tab.current_layout.neighbors_for_window(window, tab.windows)

    # Move the divider toward `direction`: the window grows when that divider
    # is on the side it points to, and shrinks otherwise.
    if neighbors.get(after):
        grow = direction == after
    elif neighbors.get(before):
        grow = direction == before
    else:
        return

    if horizontal:
        quality = 'wider' if grow else 'narrower'
    else:
        quality = 'taller' if grow else 'shorter'
    tab.resize_window(quality, step)
