#!/usr/bin/env bash
#
# session-start-register.sh — optional hook to auto-register a Claude Code
# session with the local session-deconfliction registry (see the session-lock
# skill). Wire it into a repo's SessionStart hook so every session is recorded
# without the agent having to call `register` by hand, and so a same-working-tree
# collision is surfaced the moment the session opens.
#
# Claude Code passes hook input as JSON on stdin, including a stable `session_id`
# and the `cwd`. We read those, then call ai-session.sh from the project repo.
#
# Wire it up in a repo's .claude/settings.json:
#
#   {
#     "hooks": {
#       "SessionStart": [
#         { "hooks": [ { "type": "command",
#           "command": "bash \"$HOME/.claude/skills/session-lock/hooks/session-start-register.sh\"" } ] }
#       ]
#     }
#   }
#
# It is deliberately non-fatal: if anything is missing (not a git repo, no
# session id, jq/python absent) it exits 0 so it never blocks a session from
# starting. Safe to re-run on resume/compact/clear (register is idempotent).

set -uo pipefail

payload="$(cat 2>/dev/null || true)"

# Pull session_id and cwd out of the JSON payload without hard-depending on jq.
read_json_field() { # field-name
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r --arg f "$field" '.[$f] // empty' 2>/dev/null && return
  fi
  if command -v python3 >/dev/null 2>&1; then
    # Single-quote the program so the shell never expands anything inside the
    # Python body, and pass the field name as a positional arg — code and data
    # stay fully separate (no $-interpolation into the source, now or later).
    printf '%s' "$payload" | python3 -c '
import json,sys
try: print(json.load(sys.stdin).get(sys.argv[1],""))
except Exception: pass
' "$field" 2>/dev/null && return
  fi
}

SID="$(read_json_field session_id)"
CWD="$(read_json_field cwd)"
[ -n "$CWD" ] || CWD="$PWD"

# Resolve the registry script via this hook's own location (works whether it is
# symlinked into ~/.claude/skills or run from a checkout).
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo .)"
SCRIPT="$HOOK_DIR/../scripts/ai-session.sh"
[ -x "$SCRIPT" ] || SCRIPT="$HOME/.claude/skills/session-lock/scripts/ai-session.sh"
[ -x "$SCRIPT" ] || exit 0

# Must be inside a git repo to have a registry.
( cd "$CWD" && git rev-parse --git-dir >/dev/null 2>&1 ) || exit 0

ID="${SID:-cli-$(whoami 2>/dev/null || echo user)-$$}"

( cd "$CWD" && AI_SESSION_ID="$ID" "$SCRIPT" register --agent "claude-code" \
    --task "auto-registered via SessionStart hook" ) || true

exit 0
