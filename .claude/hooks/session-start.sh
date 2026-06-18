#!/usr/bin/env bash
#
# SessionStart hook: install this repo's user-level config into ~/.claude/, and
# install language toolchains the base web image lacks (Julia).
#
# Runs after the repo is checked out (unlike the environment "Setup script",
# which runs at build time before any repo is on disk), so it can call the
# checked-out bootstrap.sh directly. Symlinks skills/ and commands/ into
# ~/.claude/ so they're available in Claude Code on the web sessions.
#
# Config symlinking is fast; bootstrap.sh is idempotent, so re-running on
# resume/clear/compact is a no-op. The Julia install is likewise guarded — it
# only does real work on a fresh container's first startup, and is a no-op once
# juliaup is present.

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

# --- Julia toolchain (juliaup) ---
# The base web image ships no Julia, so install it via juliaup. Guarded +
# idempotent (a no-op once juliaup/julia exists) and kept non-fatal: if the
# environment's network policy hasn't allowlisted *.julialang.org the install
# fails with HTTP 403, and we degrade to "no Julia" rather than aborting the
# config symlinking above. See docs/julia-setup.md for the allowlist hosts.
install_julia() {
  if command -v juliaup >/dev/null 2>&1 || command -v julia >/dev/null 2>&1; then
    return 0
  fi
  curl -fsSL https://install.julialang.org | sh -s -- --yes || return 1

  # juliaup installs its shims (julia, juliaup) into ~/.juliaup/bin. Export it
  # so processes this hook spawns next can find Julia, and persist it on PATH
  # for future interactive session shells (which source ~/.bashrc). Neither can
  # reach the already-running parent process — see docs/julia-setup.md. The -F
  # keeps the literal dot in '.juliaup/bin' from acting as a regex wildcard.
  export PATH="$HOME/.juliaup/bin:$PATH"
  if ! grep -qsF '.juliaup/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo "export PATH=\"\$HOME/.juliaup/bin:\$PATH\"" >> "$HOME/.bashrc"
  fi
}

if ! install_julia; then
  printf 'warning: Julia install incomplete (juliaup unavailable or PATH update failed — check the network allowlist for *.julialang.org; see docs/julia-setup.md)\n' >&2
fi
