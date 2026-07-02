When reviewing code or prose, challenge ambiguous phrasing and terminology
instead of silently accepting it. Flag a term or phrase when its meaning
depends on the reader guessing --- a name that could refer to more than one
thing, a claim that cites a value or construct without confirming it exists,
a word doing double duty for two different concepts in the same document. Ask
what the writer means, or check the referenced code/spec directly, rather than
inferring a plausible reading and moving on.

This catches more than typos: a reviewer who accepts ambiguous terminology at
face value can let a factually wrong claim through unchallenged --- for
example, documentation that cites a named constant or enum value that doesn't
exist in the code, because the term sounded plausible and nobody checked it
against the actual source.

Applies everywhere review already happens: PR/MR code review (`ard`/`ardi`),
prose and doc review (`use-preferred-style`, `find-ai-tells`), and issue/spec
review. When the ambiguity is resolvable by reading the code or spec yourself,
resolve it and note the correction; when it genuinely depends on the author's
intent, ask rather than assume.

**Cross-repo citations have a merge-order trap.** Citing a specific file path
or construct in another repo is itself unverifiable --- and will 404 a link
checker --- if the PR that adds it hasn't merged yet. Name the repo generically
until the referenced PR merges, then tighten the citation to the specific path.
(Caught by this very guideline, twice, while adding it to gha#151 --- the file
it pointed at only existed on this fragment's own not-yet-merged PR.)
