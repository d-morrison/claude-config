#!/usr/bin/env bash
#
# SessionStart hook: install this repo's user-level config into ~/.claude/.
#
# Runs after the repo is checked out (unlike the environment "Setup script",
# which runs at build time before any repo is on disk), so it can call the
# checked-out bootstrap.sh directly. Symlinks skills/ and commands/ into
# ~/.claude/ so they're available in Claude Code on the web sessions.
#
# Synchronous and fast (just creates symlinks); bootstrap.sh is idempotent, so
# re-running on resume/clear/compact is a no-op.

set -euo pipefail

# Only relevant in remote (web) sessions; on local machines this repo is
# installed once by running bootstrap.sh manually (see README.md).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Locate the repo root relative to this hook (.claude/hooks/ -> repo root) so it
# works regardless of which repo is the session's project directory.
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$HOOK_DIR/../.." && pwd)"

bash "$REPO_DIR/bootstrap.sh"
