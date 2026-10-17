# Runs kitty panes inside shpool sessions, so work survives kitty restarts and
# can be resumed from another machine over ssh.
#
#   kitty-shpool            new session for this pane, started in the current directory
#   kitty-shpool attach N   attach to session N, taking it over if attached elsewhere
#   kitty-shpool pick       choose a session with fzf and attach to it

session_exists() {
  shpool list --json 2>/dev/null | jq -e --arg name "$1" 'any(.sessions[]; .name == $name)' >/dev/null
}

# Tells kitty which session a pane shows, so the tab bar can match Claude
# status (keyed by session name) to the pane it's currently attached in.
mark_pane() {
  if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
    printf '\e]1337;SetUserVar=shpool=%s\a' "$(printf %s "$1" | base64 -w0)"
  fi
}

attach() {
  local name="$1"
  shift
  while true; do
    mark_pane "$name"
    shpool attach -f "$@" "$name" || true
    # The shell exited, so this pane is done.
    session_exists "$name" || return 0
    # Otherwise another client (e.g. ssh from the laptop) took the session over.
    printf '\n\e[1m%s\e[0m is attached elsewhere. Press enter to take it back, or ctrl+d to close.\n' "$name"
    read -r || return 0
    # It may have been killed while we waited; attaching would recreate it.
    session_exists "$name" || return 0
    set --
  done
}

pick() {
  local name
  name="$(
    shpool list --json |
      jq -r '.sessions | sort_by(-(.last_disconnected_at_unix_ms // .started_at_unix_ms))[] | "\(.name)\t\(.status)"' |
      fzf --delimiter='\t' --prompt='shpool> ' --height=40% --reverse |
      cut -f1
  )" || return 0
  [[ -n "$name" ]] && attach "$name"
}

new() {
  # Started from inside a session already (e.g. kitty launched from one): don't nest.
  if [[ -n "${SHPOOL_SESSION_NAME:-}" ]]; then
    exec "$(getent passwd "$USER" | cut -d: -f7)" -l
  fi
  local base suffix
  base="$(basename "$PWD" | tr -c 'A-Za-z0-9._\n-' '-')"
  suffix="$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
  attach "$base-$suffix" -d .
}

case "${1:-new}" in
  new) new ;;
  attach) attach "${2:?usage: kitty-shpool attach NAME}" ;;
  pick) pick ;;
  *)
    echo "usage: kitty-shpool [new | attach NAME | pick]" >&2
    exit 2
    ;;
esac
