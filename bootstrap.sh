#!/usr/bin/env bash
# Symlink each top-level subdir of this repo into ~/.claude/<name>.
# Safe to rerun. Skips when a real (non-symlink) file/dir already exists at the target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR"

shopt -s nullglob
for src in "$SCRIPT_DIR"/*/; do
  src="${src%/}"
  name="$(basename "$src")"
  case "$name" in
    .git|node_modules) continue ;;
  esac

  dest="$CLAUDE_DIR/$name"

  if [ -L "$dest" ]; then
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      printf 'ok    %s (already linked)\n' "$name"
    else
      printf 'skip  %s (symlink points elsewhere: %s)\n' "$name" "$current"
    fi
    continue
  fi

  if [ -e "$dest" ]; then
    printf 'skip  %s (real path exists at %s — move or merge manually, then rerun)\n' "$name" "$dest"
    continue
  fi

  ln -s "$src" "$dest"
  printf 'link  %s -> %s\n' "$name" "$src"
done
