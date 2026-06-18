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

The same hook also installs **Julia** (via `juliaup`) on the first session
start, since the base web image ships none. The install is guarded (a no-op
once Julia is present) and non-fatal — it only succeeds if the environment's
network policy allowlists the Julia download hosts. See
[`docs/julia-setup.md`](docs/julia-setup.md) for the allowlist and a
build-time alternative.

## Use these skills in another repo's web sessions (plugin marketplace)

The `SessionStart` hook above only fires when **ai-config itself** is the open
project. To get these skills when a **different** repo is open in a cloud
session — where that repo's hooks know nothing about ai-config, `~/.claude`
starts empty, and skills uploaded to claude.ai/customize do **not** cross over
into Claude Code — this repo also publishes itself as a **plugin marketplace**.

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

Locally (or to try it), run these as slash commands inside a Claude Code
session (or prefix with `claude ` to run them in a terminal):

```
/plugin marketplace add d-morrison/ai-config
/plugin install ai-config@d-morrison
```

No `version` is pinned, so every commit to this repo counts as a new version —
sessions with marketplace auto-update pick up the latest automatically.

## Use these skills with this repo's own `@claude` bot

The two mechanisms above cover the **CLI** (`~/.claude/skills` via `bootstrap.sh`)
and **other repos' cloud sessions** (the plugin marketplace). The third surface
is the `@claude` **CI bot** running on *this* repo's PRs/issues
(`.github/workflows/claude-bot.yml`).

That bot runs `claude-code-action`, which does **not** auto-discover skills from
`~/.claude` (the runner's home is fresh) or from a plugin unless it's installed.
It *does* load **project** skills from `.claude/skills/` in the checked-out
repo.

The `.claude/skills → ../skills` symlink is **committed** to this repo. It
works via a subtle two-step mechanism:

1. `claude-code-action` has a security feature called `restoreConfigFromBase`
   that, for every PR, restores `.claude/` from the **base branch** (`main`)
   using `git checkout origin/main -- .claude`. This prevents malicious PR
   branches from injecting hooks or settings.
2. Because `.claude/skills` is committed to `main`, `restoreConfigFromBase`
   always restores the symlink — even if the PR branch doesn't have it.
3. `git checkout origin/main -- .claude` correctly materializes the symlink on
   disk (unlike `gh pr checkout`, which dropped it due to `core.symlinks`
   handling — a separate failure mode that was the original blocker).

Once the symlink is in place every top-level skill becomes available to the bot
by **bare name**. Comment **`@claude ardi`** (or any other skill trigger) on a
PR or issue and the bot can invoke the `ardi` skill, exactly like the local CLI
does. No duplication (`skills/` stays the one source of truth) and new skills
are picked up automatically.

> **Note:** On PRs that predate the merge of this feature to `main`, the
> symlink is absent (`restoreConfigFromBase` restores from the `main` at the
> time Claude runs). Skills become available to the bot for all sessions after
> this PR merges.

## What's tracked

- `skills/` — reusable workflow skills (`~/.claude/skills/`)
- `commands/` — slash commands (`~/.claude/commands/`)
- `memories/` — persistent notes & preferences (symlinked into VS Code Copilot memory dir)
- `references/` — reviewed reference material / worked examples (e.g. a cloud
  Setup script). Documentation only: `bootstrap.sh` skips it, so it is **not**
  symlinked into `~/.claude`.

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
