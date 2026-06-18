# Local tools & CLIs

## gh (GitHub CLI)
- `gh` opens a pager (alternate buffer) that hangs the agent terminal.
- Always disable it: pipe `| cat` or set `GH_PAGER=cat` (e.g. `gh pr view 116 | cat`).

## glab (GitLab CLI)
- Installed at `/opt/homebrew/bin/glab`
- Authenticated on your GitLab instance — run `glab auth status` to verify host and username
- Use for MR comments, pipeline checks, CI job logs, etc.
- No `GITLAB_TOKEN` env var — glab uses its own config at `~/Library/Application Support/glab-cli/config.yml`
- Key commands:
  - `glab ci list` — list pipelines
  - `glab ci view <id>` — view pipeline/job details
  - `glab mr note create <MR_IID> --message "..."` — post MR comment
  - `glab mr list` — list merge requests
  - `glab mr view <MR_IID>` — view MR details
