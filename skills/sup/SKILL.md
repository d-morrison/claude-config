---
name: sup
description: "Send to Upstream: file an issue or open a PR on an upstream repo (a fork's parent, a dependency, or any external project). Use when you've found a bug, want to propose a fix, or need to request a feature in a project you don't own. Handles both 'just report it' (issue) and 'here's the fix' (PR) workflows. Use when asked to 'sup', 'send upstream', 'file upstream issue', 'upstream PR', 'contribute this fix back', or 'report this bug upstream'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# SUP — Send to Upstream

File an issue or open a PR on an upstream repository — a fork's parent, a
dependency, or any external project where you've found a bug, want to propose
a fix, or need to request a feature.

## When this fires

- User says "sup", "send upstream", "file upstream", "report this upstream"
- User says "contribute this fix back", "open a PR on <upstream>"
- User says "file a bug on <package>", "upstream issue for this"
- After discovering a bug in a dependency during normal work
- After implementing a workaround that should really be fixed at the source

## Determine the action type

| Situation | Action |
|-----------|--------|
| Bug report, feature request, question — no code to contribute | **Issue** |
| You have a fix ready (patch, config change, doc fix) | **PR** |
| You have a fix but aren't sure upstream wants it | **Issue first**, mention you have a fix ready |
| Fork divergence — your fork has improvements the parent should get | **PR** |

If unclear, ask the user: "Issue (report only) or PR (with fix)?"

## Procedure

### 1. Identify the upstream repo

Try these in order:

```bash
# Fork parent (GitHub)
gh repo view --json parent --jq '.parent.owner.login + "/" + .parent.name'

# Fork parent (GitLab)
glab repo view --output json | python3 -c "import json,sys; r=json.load(sys.stdin); print(r.get('forked_from_project',{}).get('path_with_namespace',''))"

# Dependency — user must specify or you infer from context
# e.g., "the bug is in rlang" → "r-lib/rlang"
```

If you can't determine the upstream repo, ask the user.

### 2. Verify access

```bash
# Can you push/PR to this repo?
gh repo view <owner>/<repo> --json viewerPermission --jq '.viewerPermission'
# WRITE or ADMIN → can PR directly
# READ → fork first, then PR from fork
```

### 3A. File an issue (report-only path)

Gather from context:
- **Title**: short, specific, imperative. "X breaks when Y" not "Problem with Z"
- **Description**: what happens, what should happen, how to reproduce
- **Environment**: version of the package/tool, OS, relevant config
- **Minimal reprex**: if you have one (prefer `reprexes` skill output)
- **Workaround**: if you have one, mention it — helps others and shows you've investigated

```bash
gh issue create --repo <owner>/<repo> \
  --title "<title>" \
  --body "<body>"
```

Or for GitLab:
```bash
glab issue create --repo <owner>/<repo> \
  --title "<title>" \
  --description "<body>"
```

After filing, report the issue URL back to the user.

### 3B. Open a PR (fix path)

#### If you have push access (collaborator/org member):

```bash
# Clone or add remote
git remote add upstream https://github.com/<owner>/<repo>.git 2>/dev/null || true
git fetch upstream

# Branch from upstream's default branch
git checkout -b fix/<slug> upstream/main  # or upstream/master, upstream/develop

# Apply your fix (copy from local workaround, write fresh, cherry-pick)
# ... make edits ...

git add -A && git commit -m "<conventional commit message>"
git push upstream fix/<slug>

# Open PR
gh pr create --repo <owner>/<repo> \
  --base main \
  --head fix/<slug> \
  --title "<title>" \
  --body "<body>"
```

#### If you need to fork first:

```bash
# Fork (idempotent — won't re-fork if already forked)
gh repo fork <owner>/<repo> --clone=false

# Your fork is now at <your-username>/<repo>
gh repo clone <your-username>/<repo> /tmp/upstream-fix
cd /tmp/upstream-fix

# Branch, fix, commit, push to YOUR fork
git checkout -b fix/<slug>
# ... make edits ...
git add -A && git commit -m "<conventional commit message>"
git push origin fix/<slug>

# Open PR from your fork to upstream
gh pr create --repo <owner>/<repo> \
  --base main \
  --head <your-username>:fix/<slug> \
  --title "<title>" \
  --body "<body>"
```

### 4. Link back to local context

After filing the upstream issue/PR:

- If you have a local workaround, add a comment in the code:
  `# WORKAROUND: upstream <owner>/<repo>#<N> — remove when fixed`
- If you used `workaround-watcher`, set it to watch the new issue/PR
- If you deferred from a local MR review, update the ARD summary with the
  upstream issue link

### 5. Report to user

Provide:
- The upstream issue/PR URL (clickable markdown link)
- What was filed (issue vs PR, title)
- Any next steps (watch for response, set up workaround-watcher, etc.)

## PR body template

```markdown
## Problem

<What's broken / missing — 2-3 sentences>

## Reproduction

<Minimal steps or reprex>

## Fix

<What this PR does — 1-2 sentences>

## Notes

- Found while working on <context> in <your-repo>
- Currently working around this with <workaround description>
```

## Issue body template

```markdown
## Problem

<What's broken / missing>

## Reproduction

<Minimal steps, version info, reprex>

## Expected behavior

<What should happen instead>

## Workaround

<If you have one — helps others and shows investigation>

## Environment

- Package version: X.Y.Z
- R/Python/Node version: ...
- OS: ...
```

## Relationship to other skills

- **`prefer-upstream`** — discovers that an upstream solution exists; `sup`
  contributes fixes back to it
- **`workaround-watcher`** — watches an upstream issue for resolution; `sup`
  creates that upstream issue in the first place
- **`defer-issue`** — files issues on YOUR repo; `sup` files on THEIR repo
- **`reprexes`** — creates minimal examples; `sup` includes them in the
  upstream report

## Anti-patterns

- ❌ Filing a vague issue ("something is broken") — always include a reprex
  or clear reproduction steps
- ❌ Opening a PR without checking if the project accepts contributions
  (look for CONTRIBUTING.md, issue templates, PR guidelines)
- ❌ Sending a massive PR that mixes your fix with unrelated changes — keep
  it minimal and focused
- ❌ Not mentioning your workaround — upstream maintainers appreciate knowing
  the impact and that you've investigated
- ❌ Filing on the wrong repo (e.g., filing on a mirror instead of the
  canonical source)
