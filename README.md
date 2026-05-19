# claude-config

Portable Claude Code config — synced across machines via git.

Each top-level subdir mirrors a directory under `~/.claude/`. `bootstrap.sh`
symlinks each one into place.

## Setup on a new machine

```sh
git clone <this-repo-url> ~/Documents/GitHub/claude-config
bash ~/Documents/GitHub/claude-config/bootstrap.sh
```

Rerun `bootstrap.sh` any time a new top-level dir is added to the repo
(e.g., `agents/`, `commands/`).

## What's tracked

- `skills/` — user-level skills (`~/.claude/skills/`)

Add more by creating a top-level dir here (e.g., `agents/`, `commands/`,
`output-styles/`) and rerunning `bootstrap.sh`.

## What's deliberately NOT tracked

These are either machine-specific, sensitive, or pure session state:

- `settings.json` / `settings.local.json` — permission allowlists and
  `additionalDirectories` bake in absolute paths and per-machine choices.
- `sessions/`, `history.jsonl`, `tasks/`, `plans/`, `projects/` — session
  and per-CWD memory state, keyed by absolute home path.
- `cache/`, `shell-snapshots/`, `file-history/`, `ide/`, `telemetry/`,
  `backups/`, `downloads/`, `session-env/` — ephemera.
- `plugins/` — managed by Claude Code itself from marketplaces.

If a per-machine variation appears that's worth syncing (e.g., a global
`CLAUDE.md`), add it as a top-level entry here and update `bootstrap.sh`
only if it needs special handling beyond a directory symlink.
