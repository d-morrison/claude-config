#!/usr/bin/env bash
# Symlink each top-level subdir of this repo into ~/.claude/<name>.
#
# For each subdir (skills/, commands/, ...):
#   - if ~/.claude/<name> doesn't exist yet, symlink the whole dir (so new
#     files added to the repo later appear automatically);
#   - if ~/.claude/<name> already exists as a real dir (e.g. cloud/web
#     sessions pre-populate ~/.claude/skills with built-in skills), merge by
#     symlinking each child into it instead of trying to replace the whole dir.
#
# Safe to rerun. Never clobbers a real (non-symlink) file/dir already in place.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR"

# Symlink $src -> $dest unless something is already there.
link_one() {
  local src="$1" dest="$2" name
  name="$(basename "$dest")"

  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      printf 'ok    %s (already linked)\n' "$name"
    else
      printf 'skip  %s (symlink points elsewhere: %s)\n' "$name" "$current"
    fi
    return
  fi

  # A real (non-symlink) path is already here: never clobber it. In a per-child
  # merge this also means a tracked skill/command whose name collides with a
  # built-in already in ~/.claude (e.g. skills/) is skipped — it can't shadow
  # the built-in in remote sessions. Rename ours if that's not what you want.
  if [ -e "$dest" ]; then
    printf 'skip  %s (real path exists at %s — move or merge manually, then rerun)\n' "$name" "$dest"
    return
  fi

  ln -s "$src" "$dest"
  printf 'link  %s -> %s\n' "$name" "$src"
}

shopt -s nullglob
for src in "$SCRIPT_DIR"/*/; do
  src="${src%/}"
  name="$(basename "$src")"
  case "$name" in
    .git|node_modules) continue ;;
  esac

  dest="$CLAUDE_DIR/$name"

  # A real directory already lives at the target (not our symlink): merge by
  # linking each child rather than skipping the whole group. dotglob links
  # hidden entries too (parity with the whole-dir symlink below) and, unlike
  # "$src"/.*, never expands to . or .. ; it's scoped so the outer loop keeps
  # ignoring .git/.github.
  if [ -d "$dest" ] && [ ! -L "$dest" ]; then
    shopt -s dotglob
    for child in "$src"/*; do
      link_one "$child" "$dest/$(basename "$child")"
    done
    shopt -u dotglob
  else
    link_one "$src" "$dest"
  fi
done
