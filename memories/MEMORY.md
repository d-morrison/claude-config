# MEMORY.md --- index of `memories/`

Index of the cross-project memory files in this directory. When you add a
*new* memory file, register it here so the corpus stays discoverable --- the
`memorize` skill writes the file, then adds a row to the table below.
(Appending a bullet to an existing file needs no change here.)

This index covers only the general, cross-project memories kept in the
ai-config repo. Repo-specific memories live outside the repo, under
`~/.claude/projects/<project-path>/memory/`, each with its own `MEMORY.md`
index in that directory.

| File | Title | Covers |
|------|-------|--------|
| [`preferences.md`](preferences.md) | User preferences (cross-workspace) | Standing working rules: never-assume/always-verify, record learnings as you go, cite sources for tool-behavior claims, issue-first, and the ARDI / fully-clean definitions. |
| [`tools.md`](tools.md) | Local tools & CLIs | Tool and CLI behavior: `gh` / `glab` and the GitHub MCP tools, the `@claude` review / CI workflows, git tags / submodules / worktrees, R / Quarto / Julia in cloud sessions, R-package CI gates, GitHub Actions workflow authoring, Quarto HTML site build / layout gotchas, harness and shell gotchas (AskUserQuestion, Bash-under-zsh), and editing committed Office Open XML files. |
| [`debugging.md`](debugging.md) | Debugging notes | Debugging practices: real-browser CSS/JS testing (not DOM stubs), VS Code editor-vs-disk desync, ARDI review-polling, portable bash scripting (sed, EOF, robustness), R test/lint CI-only gotchas and snapshot regeneration, and recovery from merge-clobbered or force-pushed PR branches. |
