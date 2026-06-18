---
name: gia
description: "Grab Issues + iterate-All: clear the repo's entire work queue in two phases — first run ARDIA (drive every open PR/MR to a clean review verdict), then run GII (grab each open issue, implement it, open an MR/PR, ARDI to clean, recurse). Use when asked to 'gia', 'ardia+gii', 'adria+gii', 'gii+ardia', 'gii+adria', 'clear the whole queue', 'clean all PRs then do all the issues', 'burn down everything', 'tidy the repo end to end', or 'empty the backlog'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# GIA — Grab Issues + iterate-All

Clear the repo's **entire** work queue end to end by composing two existing
skills in sequence:

1. **Phase 1 — [`ardia`](../ardia/SKILL.md)** (ARD + Iterate-All): drive every
   *already-open* PR/MR to a clean review verdict.
2. **Phase 2 — [`gii`](../gii/SKILL.md)** (Grab Issues Iteratively): work
   through every open issue — grab, implement, open an MR/PR, ARDI it to clean,
   recurse.

PRs-first, then issues: clearing the existing review backlog first means new
issue work lands on top of an already-clean queue (and may even unblock or
close issues that the open PRs address).

## When this fires

- "gia", "ardia+gii", "adria+gii", "gii+ardia", "gii+adria"
- "clear the whole queue", "clean all PRs then do all the issues"
- "burn down everything", "tidy the repo end to end", "empty the backlog"

## Procedure

### 0. Establish context

Detect the forge (GitHub `gh` / GitLab `glab`) from `git remote get-url
origin`. Note the default branch (`main` / `master`).

### Phase 1 — ARDIA (existing open PRs/MRs)

Run the full [`ardia`](../ardia/SKILL.md) procedure: list every open PR/MR and
drive each to a clean verdict in series (claim → ARD every finding → push →
post summary → re-request review → repeat until clean). Per-PR rules from
`ardi` apply (sync main first, re-request even on Rebut/Defer-only rounds).

If there are **zero open PRs/MRs**, Phase 1 is a no-op — note "no open PRs" in
the report's Phase 1 section and go straight to Phase 2.

Carry forward an interim table:

| PR/MR | Rounds | Final status |
|-------|--------|--------------|
| [#25](url) | 3 | ✅ Clean |

> **Why before issues:** a PR that's already open may close an issue on merge
> (`Closes #N`). Finishing PRs first avoids grabbing an issue that a pending PR
> already resolves.

### Phase 2 — GII (open issues)

Once every pre-existing PR/MR is clean, run the full [`gii`](../gii/SKILL.md)
loop: grab the highest-priority open issue → check history → implement → open
MR/PR → ARDI to clean → recurse. Stack MRs when a later issue depends on an
earlier unmerged branch. Respect GII's stopping conditions (backlog empty, user
stop, or the default 5-issue checkpoint — ask before continuing past it).

> Each PR that GII opens in this phase is itself ARDI'd to clean, so it does
> **not** need a second pass through Phase 1.

### Final report

Print one combined summary covering both phases:

```
## GIA Session Summary — <timestamp>

### Phase 1 — existing PRs/MRs driven to clean
| PR/MR | Rounds | Status |
|-------|--------|--------|
| [#16](url) | 3 | ✅ Clean |

### Phase 2 — issues grabbed & shipped
| # | Issue | MR/PR | Rounds | Status |
|---|-------|-------|--------|--------|
| 1 | [#12](url) | [#30](url) | 2 | ✅ Clean |

### Merge order
1. [#16](url)
2. [#30](url) — fix: … (stacked on #16 if applicable)
```

List the merge order across **both** phases — Phase 1 PRs can be stacked on each
other just as Phase 2 issue-PRs can, so a dependency may run PR → PR, PR →
issue-PR, or issue-PR → issue-PR. Order so every base merges before whatever
stacks on it.

## Stopping conditions

- If the trigger was ambiguous about whether to also burn down issues (e.g. a
  bare "clean up the PRs"), stop after Phase 1 and check in before starting
  Phase 2.
- Honor GII's 5-issue checkpoint in Phase 2 (ask before continuing).
- Stop if a PR or issue is blocked and surface it rather than spinning.
- If Phase 1's reviewer keeps emitting new nits each round on the same PR
  (asymptotic noise after 3–4 rounds), surface it and ask whether to continue.

## Relationship to other skills

- **`ardia`** / `adria` — Phase 1 in full.
- **`gii`** / `gis` — Phase 2 in full (which itself nests `gi`, `ardi`,
  `check-history`, `sync-pr-branch`, `defer-issue`).
- Use **`ardia`** alone to only clear the PR queue, or **`gii`** alone to only
  work the issue backlog. `gia` is the both-in-one sweep.

## Anti-patterns

- ❌ Interleaving the two phases — finish all open PRs before grabbing issues.
- ❌ Re-running Phase 1 on PRs that Phase 2 just opened (GII already ARDI'd them).
- ❌ Running Phase 2 unbounded — keep GII's checkpoint.
- ❌ Grabbing an issue a pending Phase-1 PR already closes.
