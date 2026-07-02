When explaining a concept or writing documentation, **cite claims to their
primary or authoritative source, thoroughly and by default** --- not only
when asked. This applies to chat explanations and to any content added to
docs, READMEs, or manuals (e.g. lab-manual chapters).

- Prefer the primary source: official docs, a spec, a standards body, the
  project's own repository --- over a secondhand summary.
- For well-established general concepts, a solid encyclopedia article (e.g.
  Wikipedia) is an acceptable citation.
- Link the *first* mention of a term or product, not every repetition.
- A "further reading" link is appropriate even for claims that don't strictly
  need a citation, when it would help a reader go deeper.
- Skip a citation when the source would be redundant with one already given
  in the same passage, or when the claim is about this session's own visible
  tool output (nothing external to cite).

This is a default, not an absolute rule: don't let a citation search block a
plain answer to a simple question, and don't cite something so well-known
that a link would look padded.

A citation that resolves but doesn't actually back the claim it's attached
to is still a defect --- the `check-info-quality` (`ciq`) skill's
misleading/out-of-context check catches that case; run it on content with
citations alongside `purge-hallucinations` (which only checks the citation
*exists*).
