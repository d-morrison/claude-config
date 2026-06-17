---
name: ard
description: "Address, Rebut, or Defer: respond to every review finding on a PR/MR. For each item the reviewer flags, choose exactly one disposition — fix it (Address), explain why it's correct as-is (Rebut), or file a follow-up issue (Defer). Ignoring findings is never acceptable. Use after receiving a review, or as the inner loop of the iterate skill."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# ARD — Address, Rebut, or Defer

Every review finding gets exactly one disposition. Ignoring is not an option.

## The three dispositions

| Code | Meaning | Action required |
|------|---------|-----------------|
| **A** — Address | The finding is valid and in-scope. | Fix it in this PR/MR. Commit the change. |
| **R** — Rebut | The finding is incorrect, already handled, or based on a misunderstanding. | Explain *why* it's wrong or inapplicable, citing evidence (code, docs, specs). The rebuttal must be specific enough that the reviewer can verify it without re-reading the whole PR. |
| **D** — Defer | The finding is valid but out of scope for this PR/MR. | File a follow-up issue (`gh issue create` / `glab issue create`) capturing the item. Reference the issue in your response. Update the MR description's "Known Deferred Items" section. |

## Decision criteria

Use this order of preference:

1. **Address** — default. Most findings are 1–5 line fixes. If you can fix it
   in under 2 minutes, just fix it.
2. **Rebut** — only when you're confident the reviewer is mistaken or the
   concern doesn't apply. A good rebuttal includes:
   - What the reviewer expected vs. what actually happens
   - A concrete reference (line number, test, doc link, spec section)
   - Why the current code is correct/intentional
3. **Defer** — only when the fix genuinely expands scope (new feature, broader
   refactor, unrelated concern, or requires design discussion). Never defer
   just because a fix is "minor" — minor fixes should be Addressed.

## Responding

After processing all findings, post a single structured comment on the PR/MR
summarizing your dispositions. Format:

```
Addressed findings from review of <commit>:

| # | Finding | Disposition | Detail |
|---|---------|-------------|--------|
| 1 | <summary> | ✅ Address | Fixed in <commit-sha> |
| 2 | <summary> | 🔄 Rebut | <one-line reason> |
| 3 | <summary> | 📌 Defer | <issue-link> |

<For rebuttals, expand below the table:>

### Rebuttal: Finding 2
<Full explanation with evidence>
```

## Rules

- **Every finding must appear in the table.** If the reviewer flagged it, it
  gets a row — even "positive" observations (mark those as `✅ Acknowledged`).
- **Severity labels don't change the requirement.** "Nit", "minor",
  "non-blocker", "optional", "consider" — all still require A, R, or D.
- **Rebuttals must be falsifiable.** "I think it's fine" is not a rebuttal.
  Point to specific code, behavior, or documentation that proves the point.
- **Deferred items get tracked.** A deferral without a filed issue is just
  ignoring with extra words. Always create the issue.
- **After Addressing, push the fix** before posting the response comment.
  The reviewer should be able to verify the fix is in the branch.

## Integration with iterate

When used inside the `iterate` skill's loop:
1. Read the latest review (step 4 of iterate)
2. Apply ARD to each finding (this skill)
3. Push fixes (iterate step 6)
4. Post the ARD summary comment (this skill)
5. Re-request review (iterate step 3)

The iterate loop continues until the reviewer returns zero findings.

## Edge cases

- **Finding is ambiguous** — if you can't tell whether the reviewer wants a
  change or is just observing, treat it as a finding and Address or Rebut.
  Don't assume it's informational.
- **Reviewer contradicts a previous reviewer** — Address the latest reviewer's
  concern; note the contradiction in your response so the user can arbitrate.
- **Finding duplicates a Known Deferred Item** — Rebut by pointing to the
  existing deferred issue. The "Notes for Automated Reviewers" section in the
  MR description should prevent this, but if it recurs, update that section.
