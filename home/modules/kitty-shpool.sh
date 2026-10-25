# Runs kitty panes inside shpool sessions, so work survives kitty restarts and
# can be resumed from another machine over ssh.
#
#   kitty-shpool            new session for this pane, started in the current directory
#   kitty-shpool attach N   attach to session N, taking it over if attached elsewhere
#   kitty-shpool pick       choose sessions with fzf: the first attaches here, any
#                           others (tab to multi-select) open in new kitty tabs

# home-manager signals kitty with `pkill kitty` on switch, which also matches
# this script's process name. Ignore it rather than taking the pane down.
trap '' USR1

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

# Prints "name<TAB>shell pid" for every session, found as the shpool daemon's
# children (each session's shell carries SHPOOL_SESSION_NAME).
session_pids() {
  local daemon pid name
  daemon="$(pgrep -u "$USER" -f '/shpool( .*)? daemon' | head -n1 || true)"
  [[ -n "$daemon" ]] || return 0
  for pid in $(pgrep -P "$daemon" || true); do
    name="$(tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null | sed -n 's/^SHPOOL_SESSION_NAME=//p' || true)"
    [[ -n "$name" ]] && printf '%s\t%s\n' "$name" "$pid"
  done
}

ago() {
  local secs=$(($1 / 1000))
  if ((secs < 60)); then
    echo "${secs}s ago"
  elif ((secs < 3600)); then
    echo "$((secs / 60))m ago"
  elif ((secs < 86400)); then
    echo "$((secs / 3600))h ago"
  else
    echo "$((secs / 86400))d ago"
  fi
}

# One picker row per session, most recently used first: "name<TAB>columns".
session_rows() {
  local -A pids=()
  local name pid status ms dir cmd fg claude when now
  while IFS=$'\t' read -r name pid; do
    pids[$name]="$pid"
  done < <(session_pids)
  now="$(date +%s%3N)"

  shpool list --json |
    jq -r '.sessions | sort_by(-(.last_disconnected_at_unix_ms // .last_connected_at_unix_ms // .started_at_unix_ms))[]
      | [.name, .status, (.last_disconnected_at_unix_ms // .started_at_unix_ms)] | @tsv' |
    while IFS=$'\t' read -r name status ms; do
      dir="?" cmd="" claude=""
      pid="${pids[$name]:-}"
      if [[ -n "$pid" ]]; then
        dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "?")"
        dir="${dir/#$HOME/\~}"
        fg="$(ps -o tpgid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
        if [[ -n "$fg" && "$fg" != "$pid" ]]; then
          cmd="$(ps -o comm= -p "$fg" 2>/dev/null || true)"
          cmd="${cmd#.}"
          cmd="${cmd%-wrapped}"
        fi
      fi
      claude="$(jq -r '.state // empty' "${XDG_RUNTIME_DIR:-/tmp}/kitty-agents/shpool-$name.json" 2>/dev/null || true)"
      [[ -n "$claude" ]] && claude="claude:$claude"
      if [[ "$status" == Attached ]]; then
        when="● attached"
      else
        when="○ $(ago $((now - ms)))"
      fi
      printf '%s\t%-12s  %-34s  %-12s  %s\n' "$name" "$when" "$dir" "$cmd" "$claude"
    done
}

preview() {
  local name="$1" pid sid
  pid="$(session_pids | awk -F'\t' -v n="$name" '$1 == n { print $2 }')"
  echo "$name"
  [[ -n "$pid" ]] || return 0
  readlink "/proc/$pid/cwd" 2>/dev/null || true
  echo
  sid="$(ps -o sid= -p "$pid" | tr -d ' ')"
  ps -o pid=,etime=,args= --forest -s "$sid" 2>/dev/null | cut -c1-200
}

open_in_tab() {
  kitty @ launch --type=tab "$0" attach "$1" >/dev/null
}

pick() {
  if [[ -n "${SHPOOL_SESSION_NAME:-}" ]]; then
    echo "Already inside session $SHPOOL_SESSION_NAME, and sessions can't nest." >&2
    echo "Use ctrl+t s for a picker in a new tab, or detach first (ctrl+space ctrl+q)." >&2
    return 1
  fi
  local picked first name
  picked="$(
    session_rows |
      fzf --multi --delimiter='\t' --with-nth=2 --prompt='shpool> ' \
        --header='enter: attach   tab: select several (extras open in new tabs)' \
        --preview="$0 _preview {1}" --preview-window=down,40% --reverse |
      cut -f1
  )" || return 0
  [[ -n "$picked" ]] || return 0
  first="$(head -n1 <<<"$picked")"
  if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
    while read -r name; do
      [[ -n "$name" ]] && open_in_tab "$name"
    done < <(tail -n +2 <<<"$picked")
  fi
  attach "$first"
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
  _preview) preview "${2:-}" ;;
  *)
    echo "usage: kitty-shpool [new | attach NAME | pick]" >&2
    exit 2
    ;;
esac
