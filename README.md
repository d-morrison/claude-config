# ai-config

Portable AI agent config — skills, memories, and commands synced across
machines via git. Works with Claude Code, VS Code Copilot, and any agent
that reads markdown instruction files.

Each top-level subdir is symlinked into the appropriate consumer directory
by `bootstrap.sh`.

## Setup on a new machine

```sh
git clone https://github.com/d-morrison/ai-config.git ~/ai-config
bash ~/ai-config/bootstrap.sh
```

Rerun `bootstrap.sh` any time a new top-level dir is added to the repo.

## Claude Code on the web

In cloud (web) sessions you can't run `bootstrap.sh` by hand, and the
environment "Setup script" runs at build time *before* this repo is checked
out — so it can't reference `bootstrap.sh` either. Instead, the committed
`SessionStart` hook (`.claude/settings.json` → `.claude/hooks/session-start.sh`)
runs `bootstrap.sh` once the repo is on disk, symlinking `skills/` and
`commands/` into `~/.claude/`. The hook is a no-op outside remote sessions
(`CLAUDE_CODE_REMOTE`) and idempotent, so local machines are unaffected.

## Use as a Claude Code plugin (web / remote sessions)

`bootstrap.sh` only covers local machines. Claude Code on the web starts each
cloud session in a fresh container where `~/.claude` is empty and
`bootstrap.sh` never runs — and skills uploaded to claude.ai/customize do **not**
cross over into Claude Code. So this repo also publishes itself as a **plugin
marketplace**, the supported way to load these skills in cloud sessions.

The repo is simultaneously:

- the marketplace — `.claude-plugin/marketplace.json`
- a single plugin — `.claude-plugin/plugin.json` with `source: "./"`, which
  bundles the existing top-level `skills/` and `commands/` (no duplication;
  `skills/` and `commands/` are auto-discovered at the plugin root).

To load these skills in another repo's cloud sessions, commit this to **that
repo's** `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "d-morrison": {
      "source": { "source": "github", "repo": "d-morrison/ai-config" }
    }
  },
  "enabledPlugins": {
    "ai-config@d-morrison": true
  }
}
```

Claude Code installs the plugin at session start (needs network access to reach
GitHub). Plugin skills are namespaced, e.g. `/ai-config:reprexes`,
`/ai-config:grade-work`.

Locally (or to try it), add and install interactively:

```sh
/plugin marketplace add d-morrison/ai-config
/plugin install ai-config@d-morrison
```

No `version` is pinned, so every commit to this repo counts as a new version —
sessions with marketplace auto-update pick up the latest automatically.

## What's tracked

- `skills/` — reusable workflow skills (`~/.claude/skills/`)
- `commands/` — slash commands (`~/.claude/commands/`)
- `memories/` — persistent notes & preferences (symlinked into VS Code Copilot memory dir)

Add more by creating a top-level dir here (e.g., `agents/`,
`output-styles/`) and rerunning `bootstrap.sh`.

## What's deliberately NOT tracked

These are either machine-specific, sensitive, or pure session state:

- `settings.json` / `settings.local.json` — permission allowlists and
  `additionalDirectories` bake in absolute paths and per-machine choices.
  (This is the *user-level* `~/.claude/settings.json`. The repo-root
  `.claude/settings.json` is a different thing — project-level hooks config
  for the web `SessionStart` hook above — and is intentionally tracked.)
- `sessions/`, `history.jsonl`, `tasks/`, `plans/`, `projects/` — session
  and per-CWD memory state, keyed by absolute home path.
- `cache/`, `shell-snapshots/`, `file-history/`, `ide/`, `telemetry/`,
  `backups/`, `downloads/`, `session-env/` — ephemera.
- `plugins/` — managed by Claude Code itself from marketplaces.

If a per-machine variation appears that's worth syncing (e.g., a global
`CLAUDE.md`), add it as a top-level entry here and update `bootstrap.sh`
only if it needs special handling beyond a directory symlink.
