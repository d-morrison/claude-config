---
name: consolidate-skills
description: >
  Merge two or more genuinely-overlapping skills into a single canonical skill
  plus thin alias stubs, preserving every existing invocation name so nothing
  breaks. Audits the corpus for overlap, separates intentional alias families
  and adjacent-but-distinct skills (leave those alone) from genuine duplicates
  (consolidate those), proposes a plan for approval, then ships it via branch +
  PR. Use when asked to "consolidate skills", "merge overlapping skills", "merge
  skills", "dedupe skills", "collapse duplicate skills", or "these two skills do
  the same thing". Invoke explicitly with /consolidate-skills.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# consolidate-skills — merge overlapping skills into one canonical + alias stubs

The corpus accretes near-duplicates: two sessions each author a skill for the
same workflow, or a skill drifts until it overlaps a neighbor. This skill
collapses a genuine-duplicate cluster into **one canonical skill** and turns the
absorbed ones into **thin alias stubs** — so the corpus shrinks but no
invocation name, slash command, or muscle-memory breaks.

It is the corpus-level complement to the single-skill tools: `skill-builder`
*creates* (extend-first), `heal-skill` *repairs* one misfiring skill, and this
*merges* a redundant set into one.

## When this fires

- "consolidate skills", "merge overlapping skills", "merge skills", "dedupe
  skills", "collapse duplicate skills", `/consolidate-skills`.
- You notice two skills whose descriptions and bodies describe the same workflow
  with different words.
- A `skill-builder` run discovers an existing skill it should have extended —
  hand the cleanup here.

## The one distinction that matters

Most "overlap" is **not** a duplicate. Before merging anything, classify each
cluster into exactly one of three buckets:

1. **Intentional alias family — LEAVE ALONE.** One canonical SKILL.md with real
   content; the rest are thin stubs that only redirect to it (e.g.
   `ard`/`adr`/`address-rebut-defer`, `cb`/`prune`/`clean-branches`,
   `sync-pr-branch`/`merge-main`/`resync-branch`). This is the *target* state,
   not a problem. Tell: the others' bodies are ~5 lines ending in
   `→ ~/.claude/skills/<canonical>/SKILL.md`.
2. **Adjacent-but-distinct — LEAVE ALONE (maybe cross-link).** Same theme,
   genuinely different procedure (e.g. `tidy` audits for refactors vs `simplify`
   prunes dead code; `split-concerns` splits a PR vs `defer-issue` files a
   follow-up). Merging these *loses* capability. If they should reference each
   other, hand off to `link-skills` — don't consolidate.
3. **Genuine duplicate — CONSOLIDATE.** Two or more skills with **real bodies**
   that drive the same workflow to the same outcome. This is the only bucket
   this skill acts on.

If you can't articulate what capability would be *lost* by keeping both, it's a
duplicate. If you can, it isn't.

## Procedure

### 1. Locate the repo and gather every skill

```bash
cd "$(git -C ~/.claude/skills rev-parse --show-toplevel)"   # the ai-config repo
ls skills/
# name + description, one row per skill, to eyeball overlap:
for d in skills/*/; do
  n=$(basename "$d")
  desc=$(awk '/^description:/{flag=1} flag{print} /^(user-invocable|allowed-tools):/{if(flag)exit}' "$d/SKILL.md" | head -4 | tr '\n' ' ')
  printf '%-40s %s\n' "$n" "$desc"
done
```

> In a **worktree**, `rev-parse --show-toplevel` resolves to the *main* checkout
> (see issue #76 / the `skill-builder` warning) — that's correct here: skills
> live in the main checkout, edit them there.

### 2. Cluster and classify

Group skills that share trigger keywords or describe the same outcome. For each
candidate cluster, **read the full SKILL.md of every member** and assign the
bucket above. A stub vs. a real body is the fastest signal:

```bash
wc -l skills/<a>/SKILL.md skills/<b>/SKILL.md   # stub ≈ <15 lines; real body more
```

Only clusters that land in **bucket 3 (genuine duplicate)** proceed.

### 3. Propose the consolidation plan — get approval first

Like `heal-skill`, do not mutate before the user signs off. Present, per
cluster:

- **The members** and why they're genuine duplicates (not an alias family, not
  adjacent-but-distinct).
- **The chosen canonical name** — prefer the most discoverable / most-used /
  spelled-out name; keep the one whose triggers best cover the union. State why.
- **What gets folded in** — any trigger phrase or body step unique to an
  absorbed skill that must survive into the canonical.
- **Which names become stubs** (all non-canonical members).
- **References to fix** — `preferences.md`, `CLAUDE.md`, other skills' bodies
  that name an absorbed skill (see step 6).

### 4. Build the canonical skill

In the canonical `skills/<canonical>/SKILL.md`:

- **Union the trigger phrases** from every absorbed skill's `description` into
  the canonical `description`, deduped — discoverability must not regress.
- **Fold in unique body content** — any step, caveat, or example an absorbed
  skill had that the canonical lacks. Keep one coherent procedure; don't just
  staple the bodies together.
- Preserve the family body shape: `# <name> — <tagline>`, `## When this fires`,
  `## Procedure`, `## Relationship to other skills`, `## Anti-patterns`.

### 5. Convert absorbed skills to thin alias stubs

**Never `git rm` an invocation name** — overwrite it with a redirect so every
existing `/name` keeps resolving:

```markdown
---
name: <absorbed>
description: "Alias for `<canonical>`. <one-line of what it does>. Use when asked to '<trigger>', '<trigger>'."
user-invocable: true
---

# <absorbed> (alias for `<canonical>`)

This is an alias for the **<canonical>** skill. Read and follow the canonical skill:

→ **`~/.claude/skills/<canonical>/SKILL.md`**
```

Carry the absorbed skill's own trigger phrases into the stub's `description` so
those phrasings still match. The stub holds **zero** procedural content — the
canonical is the single source of truth.

### 6. Fix every dangling reference

A consolidated name may be mentioned elsewhere. Find and update:

```bash
grep -rn "<absorbed>" skills/*/SKILL.md memories/ CLAUDE.md 2>/dev/null \
  | grep -v "skills/<absorbed>/SKILL.md"
```

Repoint `## Relationship to other skills` cross-links and any `preferences.md` /
`CLAUDE.md` mentions at the canonical name (note the stub still works, but links
should name the canonical).

### 7. Validate, then ship via branch + PR

```bash
python3 scripts/validate-skills.py      # if present — must pass
```

Skills live in the ai-config repo — never leave changes local-only. Branch +
PR (not direct to main), request `d-morrison` as reviewer (`request-pr-review`),
then **ARDI to clean** (`ardi`).

```bash
git checkout -b consolidate-<canonical>-skill origin/main
# write the canonical, overwrite absorbed skills as stubs, fix references
git add skills/<canonical>/ skills/<absorbed-1>/ skills/<absorbed-2>/   # only the
# dirs you touched — plus memories/preferences.md and/or CLAUDE.md ONLY if you
# edited them. Never `git add -A` or a bare `skills/`, which sweeps in unrelated edits.
git commit -m "skills: consolidate <a>/<b> into <canonical> (+ alias stubs)"
git push -u origin HEAD && gh pr create --fill
```

## Relationship to other skills

- **`skill-builder`** — the inverse-facing sibling: it *creates* (extend-first)
  and, when it finds it should have extended an existing skill, hands the
  cleanup here.
- **`heal-skill`** — repairs *one* misfiring skill; this merges a redundant
  *set*. If two skills "compete for the same request" but are genuinely distinct,
  that's a `heal-skill` boundary fix, not a consolidation.
- **`link-skills`** — for adjacent-but-distinct skills that should reference each
  other but stay separate, cross-link instead of merging.
- **`tidy` / `simplify`** — the same "collapse near-duplicates over proliferating
  them" instinct, applied to code rather than the skill corpus.

## Anti-patterns

- ❌ Collapsing an **intentional alias family** (canonical + redirect stubs) —
  that's the target state, not a duplicate.
- ❌ Merging **adjacent-but-distinct** skills and silently dropping a capability.
- ❌ `git rm`-ing an invocation name instead of converting it to an alias stub —
  it breaks every existing `/name`, automation, and muscle-memory.
- ❌ Dropping trigger phrases on the floor — the canonical's `description` must
  cover the **union** of the absorbed skills' triggers, or discoverability
  regresses.
- ❌ Leaving procedural content in a stub — aliases redirect only; one canonical
  source of truth.
- ❌ Mutating before the user approves the plan, or leaving dangling references
  to an absorbed name in `preferences.md` / `CLAUDE.md` / other skills.
