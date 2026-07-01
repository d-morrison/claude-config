---
name: "style"
description: "Codex wrapper for the ai-config Claude skill `style`. Alias for `use-preferred-style`. Write or revise prose in the user's preferred style \u2014 limit dependent clauses, cut filler and jargon, prefer short declarative sentences joined by coordinating conjunctions. Use when asked to '/style', 'use my style', 'apply my preferred style', or 'tighten this prose'. Use when Codex is asked to use `style`, `/style`, or the corresponding ai-config/Claude skill workflow."
---

# style (Codex wrapper)

This is a generated Codex wrapper around the canonical ai-config Claude skill.

Source: [skills/style/SKILL.md](../../skills/style/SKILL.md)

Before acting, read the source skill completely and follow its workflow, adapting it to Codex.

The source lives at `skills/style/SKILL.md` in the same ai-config checkout as this wrapper. If this wrapper was loaded through `${CODEX_HOME:-$HOME/.codex}/skills/style`, resolve the symlink target for this wrapper directory first, then read `../../skills/style/SKILL.md` relative to that real directory. Do not resolve that relative path from inside `${CODEX_HOME:-$HOME/.codex}/skills`, because it points back at the wrapper tree.

- Treat `user-invocable` and `allowed-tools` as Claude metadata, not Codex permissions.
- Use the tools available in this Codex session for equivalent operations.
- If the source mentions a Claude-only path such as `~/.claude/skills`, use this repository's `skills/` path while editing.
- Keep procedural changes in the canonical source skill unless the user specifically asks to change this wrapper.

## Tool mappings

The canonical skill names `gh`/`git` commands (and sometimes `mcp__github__*`
tools). Use the GitHub MCP tool below if this Codex session has it; otherwise
run the CLI command. Full per-model reference: [tool-mappings.md](../../tool-mappings.md).

| Operation | Does | CLI (`gh`/`git`) | GitHub MCP tool |
| --- | --- | --- | --- |
| `VIEW_PR` | Read a pull request's details and metadata. | `gh pr view <N>` | `mcp__github__pull_request_read (method=get)` |
| `LIST_PRS` | List pull requests. | `gh pr list` | `mcp__github__list_pull_requests` |
| `DIFF_PR` | Read a pull request's diff. | `gh pr diff <N>` | `mcp__github__pull_request_read (method=get_diff)` |
| `PR_CHECKS` | Read a pull request's CI check / status results. | `gh pr checks <N>` | `mcp__github__pull_request_read (method=get_check_runs)` |
| `CREATE_PR` | Open a new pull request. | `gh pr create` | `mcp__github__create_pull_request` |
| `EDIT_PR` | Edit a pull request (reviewers, labels, base, etc.). | `gh pr edit <N>` | `mcp__github__update_pull_request` |
| `MERGE_PR` | Merge a pull request. | `gh pr merge <N>` | `mcp__github__merge_pull_request` |
| `COMMENT_PR` | Post a top-level comment on a pull request. | `gh pr comment <N> --body "..."` | `mcp__github__add_issue_comment` |
| `REPLY_REVIEW_COMMENT` | Reply to an inline pull-request review comment. | `gh api (reply to review comment)` | `mcp__github__add_reply_to_pull_request_comment` |
| `WATCH_PR` | Subscribe to / unsubscribe from a pull request's activity. | (no CLI equivalent) | `mcp__github__subscribe_pr_activity / mcp__github__unsubscribe_pr_activity` |
| `VIEW_ISSUE` | Read an issue's details. | `gh issue view <N>` | `mcp__github__issue_read` |
| `LIST_ISSUES` | List issues. | `gh issue list` | `mcp__github__list_issues` |
| `CREATE_ISSUE` | Open a new issue. | `gh issue create` | `mcp__github__issue_write (method=create)` |
| `COMMENT_ISSUE` | Post a comment on an issue. | `gh issue comment <N> --body "..."` | `mcp__github__add_issue_comment` |
| `LIST_DISCUSSIONS` | List a repository's discussions. Discussions are GraphQL-only. | `gh api graphql (list discussions)` | (no GitHub MCP tool; use gh api graphql) |
| `VIEW_DISCUSSION` | Read a discussion topic and its comment thread. | `gh api graphql (read discussion + comments)` | (no GitHub MCP tool; use gh api graphql) |
| `COMMENT_DISCUSSION` | Post a reply on a discussion (top-level or threaded). | `gh api graphql (addDiscussionComment)` | (no GitHub MCP tool; use gh api graphql) |
| `ANSWER_DISCUSSION` | Mark a comment as the accepted answer on a Q&A discussion. | `gh api graphql (markDiscussionCommentAsAnswer)` | (no GitHub MCP tool; use gh api graphql) |
| `CREATE_DISCUSSION` | Open a new discussion in a category. | `gh api graphql (createDiscussion)` | (no GitHub MCP tool; use gh api graphql) |
| `CLOSE_DISCUSSION` | Close a discussion with a reason (RESOLVED, OUTDATED, DUPLICATE). | `gh api graphql (closeDiscussion)` | (no GitHub MCP tool; use gh api graphql) |
| `PUSH` | Push commits to a branch. | `git push -u origin <branch>` | (use git; no GitHub MCP equivalent) |
| `COMMIT` | Record staged changes as a commit. | `git commit -m "..."` | (use git; mcp__github__create_or_update_file commits a single file) |
| `FETCH` | Fetch refs from the remote. | `git fetch origin <branch>` | (use git; no GitHub MCP equivalent) |
| `MERGE_BRANCH` | Merge a branch into the current one. | `git merge origin/<branch>` | (use git; no GitHub MCP equivalent) |
| `CREATE_BRANCH` | Create a new branch (e.g. off the default branch). | `git switch -c <branch> origin/<base>` | `mcp__github__create_branch` |
| `READ_FILE` | Read a file's contents from the repo. | `gh api repos/<owner>/<repo>/contents/<path>` | `mcp__github__get_file_contents` |
| `WRITE_FILE` | Create or update file(s) on a branch in a single commit. | `git add <path> && git commit -m "..." && git push` | `mcp__github__create_or_update_file (one file) / mcp__github__push_files (multiple)` |
