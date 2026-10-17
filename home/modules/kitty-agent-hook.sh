# Records Claude Code session state for the kitty tab bar (see kitty-tab-bar.py).
# Usage: kitty-agent-hook <hook event>, with the hook payload on stdin.

dir="${XDG_RUNTIME_DIR:-/tmp/kitty-agents-$(id -u)}/kitty-agents"
# Inside shpool the kitty env is frozen at session creation, so key by session
# name and let the tab bar find whichever pane has it attached now.
if [[ -n "${SHPOOL_SESSION_NAME:-}" ]]; then
  file="$dir/shpool-$SHPOOL_SESSION_NAME.json"
elif [[ -n "${KITTY_PID:-}" && -n "${KITTY_WINDOW_ID:-}" ]]; then
  file="$dir/$KITTY_PID-$KITTY_WINDOW_ID.json"
else
  exit 0
fi

event="${1:-}"
payload="$(cat)"

case "$event" in
  SessionStart | Stop) state=idle ;;
  UserPromptSubmit | PreToolUse | PostToolUse) state=working ;;
  Notification) state=blocked ;;
  SessionEnd)
    rm -f "$file"
    exit 0
    ;;
  *) exit 0 ;;
esac

mkdir -p "$dir"
tmp="$(mktemp "$file.XXXXXX")"
jq -c --arg state "$state" \
  '{state: $state, cwd: (.cwd // ""), session_id: (.session_id // ""), ts: now}' \
  <<<"$payload" >"$tmp" || echo "{\"state\":\"$state\"}" >"$tmp"
mv -f "$tmp" "$file"
