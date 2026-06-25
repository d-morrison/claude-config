When starting a **new** piece of work, go **issue-first**: before branching,
editing, or opening a PR, make sure a tracking issue exists. Search the tracker
first; if no open issue covers the task, **file one** (`gh issue create` /
`glab issue create`), then proceed. Never jump straight into a PR without a
tracking issue behind it.

The issue is the durable record of intent, scope, and "done" criteria --- it
gives reviewers context, lets the PR auto-close it via `Closes #N`, and keeps
the work discoverable even if the PR stalls. Skip only when the task is already
tracked by an open issue.

When filing an issue that contains a list of independent subissues, file each
subissue as a child issue linked under the parent (GitHub sub-issues feature:
`mcp__github__sub_issue_write` in remote sessions, or `gh api` with the
sub-issues endpoint in local sessions).
