#!/usr/bin/env bash
# Bootstrap ai-config: symlink skills, commands, and memories into their
# respective consumer directories (Claude Code, VS Code Copilot, etc.).
# Safe to rerun. Skips when a real (non-symlink) file/dir already exists at the target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"

# VS Code Copilot memory directory (macOS default; override with COPILOT_MEMORY_DIR)
COPILOT_MEMORY_DIR="${COPILOT_MEMORY_DIR:-$HOME/Library/Application Support/Code/User/globalStorage/github.copilot-chat/memory-tool/memories}"

mkdir -p "$CLAUDE_DIR"

# --- Top-level files (CLAUDE.md, etc.) ---
shopt -s nullglob
for src in "$SCRIPT_DIR"/*.md; do
  [ -f "$src" ] || continue
  fname="$(basename "$src")"
  [[ "$fname" == "README.md" ]] && continue   # don't symlink repo README
  dest="$CLAUDE_DIR/$fname"

  if [ -L "$dest" ]; then
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      printf 'ok    %s (already linked)\n' "$fname"
    else
      printf 'skip  %s (symlink points elsewhere: %s)\n' "$fname" "$current"
    fi
    continue
  fi

  if [ -e "$dest" ]; then
    printf 'skip  %s (real file exists at %s — move or merge manually, then rerun)\n' "$fname" "$dest"
    continue
  fi

  ln -s "$src" "$dest"
  printf 'link  %s -> %s\n' "$fname" "$src"
done

# --- Directories (skills, commands, memories, etc.) ---
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

# --- Memories: symlink individual .md files into VS Code Copilot memory dir ---
if [ -d "$SCRIPT_DIR/memories" ] && [ -d "$COPILOT_MEMORY_DIR" ]; then
  printf '\n--- VS Code Copilot memories ---\n'
  for src in "$SCRIPT_DIR"/memories/*.md; do
    [ -f "$src" ] || continue
    fname="$(basename "$src")"
    dest="$COPILOT_MEMORY_DIR/$fname"

    if [ -L "$dest" ]; then
      current="$(readlink "$dest")"
      if [ "$current" = "$src" ]; then
        printf 'ok    memories/%s (already linked)\n' "$fname"
      else
        printf 'skip  memories/%s (symlink points elsewhere: %s)\n' "$fname" "$current"
      fi
      continue
    fi

    if [ -e "$dest" ]; then
      printf 'skip  memories/%s (real file exists — move it, then rerun)\n' "$fname"
      continue
    fi

    ln -s "$src" "$dest"
    printf 'link  memories/%s -> %s\n' "$fname" "$src"
  done
else
  printf '\nskip  memories/ (dir not found or Copilot memory dir missing)\n'
fi
