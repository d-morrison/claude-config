When you find a bug or issue that belongs in an **upstream or external
repository** (a dependency, a reusable workflow, an action you call, etc.),
work through this escalation path:

1. **Open a PR** in the upstream repo if you have a fix ready.
   Push directly if you have write access; fork first if you don't.
2. **File an issue** in the upstream repo if you have access to the tracker
   but no fix ready, or if a PR would be premature. Link back to the current
   PR/issue for context.
3. **File an issue in your own repo** if you can't file an issue in the upstream
   repo either (e.g. the tracker is closed, the MCP tools can't reach it, or you
   lack any access). Write it clearly enough that it could stand on its own, then
   **ask the user to transfer it** to the upstream repo using GitHub's
   *Transfer issue* feature.

In all cases, reply to the review comment (or note in the PR) with a link to
whatever issue or PR you filed, so the upstream root cause is tracked and
visible.

Apply any reasonable local mitigation regardless of which path you took, but
don't let the upstream root cause go unrecorded.
