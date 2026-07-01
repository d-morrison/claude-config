"Fully clean" is the terminal state the ARDI review loop drives toward.
A PR/MR is **fully clean** when **both** of these hold:

1. **All CI workflows are green.** Every workflow passes --- not just the required
   checks and not just the review job. This includes non-gating checks like the
   Coverage / codecov job: don't merge around a red Coverage run just because it
   isn't a required check, unless there's a specific, stated reason for that merge
   (the project wants to maintain decent coverage, so a red Coverage job is a real
   signal to fix, not to ignore).
2. **The latest review is totally clean:** no nits, and every item that wasn't
   directly **Addressed** is either **Deferred** to a tracked follow-up issue,
   or **Rebutted with a rebuttal that actually convinced the reviewer** --- i.e.
   the reviewer did *not* re-raise it on the next round. A rebuttal the reviewer
   still disputes does **not** count as clean.

**Threads:** at fully-clean, every **inline** review thread is resolved, and the
only conversation left open is the final all-clear exchange --- the reviewer's
all-clear comment and your reply to it. (The all-clear is usually a top-level PR
comment, not an inline thread.)

**Deadlock -> escalate to a human.** If you and the reviewer(s) can't reach
consensus on an item (a rebuttal was exchanged and neither side is budging),
don't loop forever and don't unilaterally override the reviewer --- request a
**human reviewer**, `@`-mention them in a comment summarizing the impasse, and
surface the open item.
