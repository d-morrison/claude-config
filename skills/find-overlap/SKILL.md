---
name: find-overlap
description: >
  Read-only detector of overlapping or redundant content across a corpus —
  skills, memories, docs, prose, or any file set. Clusters comparable units by
  similarity, classifies each cluster as intentional-alias / adjacent-but-distinct
  / genuine-duplicate, and reports each with similarity evidence and a recommended
  disposition (merge / cross-link / leave-distinct) routed to the right action
  skill. Detects and reports only — never edits, merges, or deletes. Use when
  asked to 'find overlap', 'find overlapping skills', 'find overlapping content',
  'find duplicates', 'find redundant content', 'audit for duplication', 'dedupe
  audit', "what's redundant here", or 'where do these overlap'. Invoke explicitly
  with /find-overlap.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# find-overlap — read-only overlap / redundancy detector

Find where a corpus says the same thing twice — and change nothing. This is the
*detection* half of de-duplication, factored out so it's reusable: an action
skill calls it for its audit (`consolidate-skills` for the skills corpus,
`consolidate-memory` for the memory corpus), and you can run it standalone to ask
"what's redundant here?" over any body of content. It is to `consolidate-skills`
what `pr-status` is to `ardi` — it reports, it does not act.

## When this fires

- "find overlap", "find overlapping skills", "find overlapping content", "find
  duplicates", "find redundant content", "audit for duplication", "dedupe audit",
  "what's redundant here", "where do these overlap", `/find-overlap`.
- As the detection phase of an action skill — `consolidate-skills` delegates its
  audit here.

## The one distinction that matters — three buckets

Most "overlap" is **not** redundancy. Every cluster you surface must be sorted
into exactly one of three buckets — the report is only useful if it makes this
call, not just "these look similar":

1. **Intentional alias / redirect — NOT overlap.** One canonical unit with real
   content; the rest are thin pointers to it (skill alias stubs ending in
   `→ …/<canonical>/SKILL.md`; a memory that just says "see [[other]]"). This is
   the *target* state. Also here: deliberate single-vs-all pairings
   (`pr-status` / `pr-status-all`).
2. **Adjacent-but-distinct — NOT a duplicate.** Same theme, genuinely different
   purpose or procedure (`tidy` vs `simplify`; two memories on related but
   separate facts). Merging these *loses* something. If they should reference
   each other, that's a cross-link job (→ `link-skills`), not a merge.
3. **Genuine duplicate / redundant — FLAG THIS.** Two or more units with **real
   content** that say the same thing or drive the same outcome in different
   words. This is the only bucket that warrants a merge.

**Litmus:** if you can name a capability or fact that would be lost by removing
one member, it isn't a duplicate. If you can't, it is.

## Procedure

### 1. Define the corpus and the comparable unit

Pick the scope the user named (default to the skills corpus when you're in the
ai-config repo and none is given), and the unit you compare:

| Corpus | Unit | Cheap signature | Similarity tell |
|--------|------|-----------------|-----------------|
| `skills/` | one `skills/<name>/SKILL.md` | `name` + `description` + body | shared trigger phrases / same outcome verb |
| `memories/` | one memory file | `name` + `description` + body | same subject/fact restated |
| docs / Quarto / markdown | one heading section | heading + first lines | same topic covered twice |
| code | one function / file | signature + doc comment | same logic, different name |
| pasted prose | one paragraph / section | first sentence | same claim repeated |

### 2. Gather signatures cheaply (one row per unit)

For skills:
```bash
cd "$(git -C ~/.claude/skills/find-overlap rev-parse --show-toplevel)"
for d in skills/*/; do n=$(basename "$d")
  # robust for inline and block-scalar (`>`, `|`, with optional `-`/`+` chomp) frontmatter:
  desc=$(python3 -c "
import re
t=open('$d/SKILL.md').read()
m=re.search(r'^description:[ \t]*[>|]?[-+]?[ \t]*\n?(.*?)(?=\n\S|\Z)', t, re.M|re.S)
print(re.sub(r'\s+',' ', m.group(1) if m else '').strip().strip('\"')[:70])")
  lc=$(wc -l < "$d/SKILL.md" | tr -d ' ')
  printf '%4s  %-34s %s\n' "$lc" "$n" "$desc"
done | sort -n
```
(A plain `awk -F'description:'` drops `description: >` block scalars — including
this skill's own — to blank; the `python3` extractor handles both forms.)
For memories: the same shape over `memories/*.md` (`name` + `description` from
frontmatter). The line count separates thin stubs from real bodies at a glance.

### 3. Cluster candidates — then read the bodies

Group units that share keywords, titles, or the same outcome. Do a cheap
keyword/title pass first, **then read the full body of every member of each
candidate cluster.** Never classify on titles or descriptions alone — that's the
top source of false positives (two skills can share a verb and do different
work).

### 4. Classify each cluster into one of the three buckets

Apply the litmus above. Be skeptical: assume *adjacent-but-distinct* until the
bodies prove genuine duplication.

### 5. Report — read-only, routed to an action

Output one compact table; **edit nothing.** For each cluster give the members,
the bucket, what they share, and a recommended disposition pointed at the skill
that would carry it out:

| Cluster | Members | Bucket | Shared | Recommended |
|---------|---------|--------|--------|-------------|
| deploy | `deploy-staging`, `push-to-staging` | genuine duplicate | same deploy steps | merge → `consolidate-skills` |
| sync trio | `merge-main`, `sync` | intentional alias | redirect stubs | leave |
| tidy/simplify | `tidy`, `simplify` | adjacent-distinct | "clean up code" | cross-link → `link-skills` |

(The first row is illustrative — a hypothetical pair, not a live finding. The
other two model real corpus relationships.)

Disposition routing: duplicate skills → `consolidate-skills`; duplicate memories
→ `consolidate-memory`;
adjacent-but-distinct missing a link → `link-skills`; redundant code → `tidy` /
`simplify`; prose/docs → a manual edit. Always end with a recommendation per
cluster — a raw similarity list with no disposition just pushes the judgment back
to the reader.

## Relationship to other skills

- **`consolidate-skills`** — the action counterpart for the skills corpus; it
  delegates its audit to this skill, then merges the genuine-duplicate clusters.
  find-overlap finds; consolidate-skills acts.
- **`consolidate-memory`** — the action counterpart for the memory corpus.
- **`link-skills`** — finds the *inverse* (distinct skills that should reference
  each other but don't); hand it the adjacent-but-distinct clusters.
- **`find-ai-tells`** — sibling read-only scanner over prose, for a different
  signal (AI tells, not duplication).
- **`tidy` / `simplify`** — code-level dedup once overlap is found.
- **`pr-status` ↔ `ardi`** — the same read-only-report vs. actor split this skill
  has with the `consolidate-*` family.

## Anti-patterns

- ❌ Editing, merging, or deleting anything — find-overlap only detects and
  reports. Acting is the `consolidate-*` skills' job.
- ❌ Flagging an **intentional alias family** or a single-vs-all pairing
  (`pr-status` / `pr-status-all`) as a duplicate.
- ❌ Conflating **adjacent-but-distinct** with **duplicate** — that recommends a
  merge that loses a capability.
- ❌ Classifying on titles/descriptions alone without reading bodies — the main
  false-positive source.
- ❌ Checking only one corpus when the user said "generally" / "everywhere".
- ❌ Reporting raw similarity with no per-cluster disposition.
