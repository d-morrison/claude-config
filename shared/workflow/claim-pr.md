Before starting a work session on a GitHub PR or issue --- i.e. before fetching
the branch, making edits, or invoking an automated review cycle --- post a brief
comment on the PR/issue so other people and any automated review bots know not
to start a conflicting parallel session.

Use:

```
gh pr comment <N> --body "Working on this --- paws off until I'm done."
gh issue comment <N> --body "Working on this --- paws off until I'm done."
```

Then proceed with the work. After the session ends (PR merged, issue closed, or
work otherwise paused), follow up with a closing comment so the PR/issue is
unclaimed for the next person.

Skip the claim step if the most recent comment already says you are working on
it. This applies to any task that will push commits to a PR branch or run
iterative review loops. It does **not** apply to read-only inspection (showing a
PR, checking status, explaining a diff) --- those don't risk a parallel session.
