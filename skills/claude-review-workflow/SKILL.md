---
name: claude-review-workflow
description: Add or modify the `anthropics/claude-code-action` PR review workflow (`.github/workflows/claude-code-review.yml`). Preserves the delete-prior-sticky-comment pattern so the new sticky lands at the bottom of the PR conversation instead of being buried in folded sections.
user-invocable: true
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
---

# claude-review-workflow

Sets up or edits the Claude PR review GitHub Actions workflow. The critical
detail this skill preserves: **delete the prior Claude sticky comment before
each new run** so the new review lands at the bottom of the PR conversation.

## Why the delete-prior-sticky pattern matters

GitHub folds long PR conversations into "more comments" panels. If
`use_sticky_comment: true` edits the existing comment in place, the comment
can get buried inside the folded section and become invisible to reviewers.

The pattern: a pre-step deletes the previous Claude sticky comment, then the
action posts a new sticky which appears at the bottom where it stays visible.
The `github-actions Bot "deleted a comment from claude Bot"` timeline entry
is **expected, not a bug**.

The canonical reference is the serodynamics workflow.

## When working on this file

Path: `.github/workflows/claude-code-review.yml`

**Do not "simplify" by removing the delete-prior-sticky step.** It looks
redundant but is load-bearing. Keep:

- The pre-step that deletes the prior Claude sticky comment.
- `track_progress: 'true'` on the `anthropics/claude-code-action` step.
- `use_sticky_comment: 'true'` on the same step.

## Reference workflow shape

```yaml
name: Claude PR Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      issues: write
      id-token: write
    steps:
      - name: Delete previous Claude sticky comment
        uses: actions/github-script@v7
        with:
          script: |
            const { data: comments } = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
            });
            const prior = comments.find(
              c => c.user.login === 'claude[bot]' || c.user.login === 'claude'
            );
            if (prior) {
              await github.rest.issues.deleteComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: prior.id,
              });
            }

      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          track_progress: 'true'
          use_sticky_comment: 'true'
          # ... other inputs as needed
```

## Setting up in a new repo

1. Confirm `ANTHROPIC_API_KEY` secret exists:
   `gh secret list` — add via `gh secret set ANTHROPIC_API_KEY` if missing.
2. Write `.github/workflows/claude-code-review.yml` with the shape above.
3. If the repo already has a similar workflow, edit in place rather than
   replacing — preserve any custom `direct_prompt`, model selection, or
   path filters the project already uses.
