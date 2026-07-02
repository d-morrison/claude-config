When reviewing prose in a PR/MR --- documentation, lecture notes, a README, any
non-code narrative content --- assess it for **accuracy and clarity**, not just
style. This is broader than the terminology check in
[`challenge-ambiguous-terminology.md`](../workflow/challenge-ambiguous-terminology.md):
that guide catches phrasing whose meaning is unresolved; this one catches
claims and reasoning that are resolved but wrong.

## What to check

- **Factual claims.** Check each claim against the AI's own domain knowledge
  and, where the claim is checkable against an external source (a paper, a
  spec, a package's documentation, a dataset), fetch and check it there too.
  Don't accept a plausible-sounding claim without checking it.
- **Tool/library behavior claims.** When prose describes how a specific tool
  or library behaves (a git merge driver, a shell built-in, a regex engine, a
  function's edge-case handling) and that behavior is deterministic and cheap
  to reproduce, run a small live test rather than relying on memory or a
  half-remembered doc. A plausible-sounding mechanism description ("union
  merge de-duplicates identical lines") can be wrong in a specific,
  checkable way; a two-minute constructed repro settles it definitively where
  recall alone can't.
- **Document-internal reasoning.** Work through the logic of any argument the
  document makes, not just its individual factual claims --- this includes
  **formal mathematical reasoning** (derivations, proofs, algebraic steps ---
  verify each step follows from the last, check dimensions/units, check
  edge cases and boundary conditions) and **informal reasoning** (an argument
  that X implies Y, a causal claim, a justification for a design choice).
  Flag steps that don't follow, unstated assumptions load-bearing enough that
  the conclusion breaks without them, and conclusions the stated reasoning
  doesn't actually support.
- **Rendered/computed artifacts.** When the document references a computed
  value, a figure, or a numeric result (a fitted coefficient, a plotted
  curve, a table entry), don't take the source prose's word for it --- check it
  against the rendered output. If the project has a rendered preview site
  (a PR-preview deploy, a `gh-pages` branch, a built docs site), fetch the
  live preview and/or the underlying built files on that branch to confirm
  the value or figure the prose describes actually matches what was computed.
  Prefer the live preview when the PR is far enough along to have one; fall
  back to the `gh-pages`/built-output branch's raw files when the preview
  isn't deployed yet or doesn't cover the changed page. Many PR-preview
  setups (e.g. `rossjrw/pr-preview-action`, used by this lab's Quarto repos)
  deploy each PR's rendered site to a `gh-pages` branch under
  `pr-preview/pr-<N>/`, with the direct URL posted in a sticky PR comment ---
  check that comment or the repo's own CLAUDE.md for the exact convention
  rather than assuming a layout.

## What to report

For every claim or reasoning step checked, state:

1. **Which claims are inaccurate**, if any --- quote or point to the specific
   sentence, and say what's wrong with it.
2. **The basis for each judgment** --- cite the specific source checked (a URL,
   a file path and line, a rendered page, a computed value pulled from the
   preview/`gh-pages` branch) so the author can verify the check without
   re-deriving it.
3. **Additional citations or references that would help**, proactively ---
   not just where a claim is already flagged as uncited, but anywhere a
   reader would benefit from a pointer to a source (a foundational
   result, a dataset's documentation, a package's reference page) even if
   the prose isn't currently wrong without it.

Silence on a checkable claim reads as "verified" --- don't leave one unchecked
because it sounded right on a first pass.
