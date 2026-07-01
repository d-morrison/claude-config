---
name: discussions
description: "Read and respond to GitHub Discussions forum topics — list a repo's discussions, read a topic and its comments, draft and post a reply, and mark an answer on Q&A discussions. Discussions are GraphQL-only (no `gh discussion` subcommand, no GitHub MCP tool), so this skill runs `gh api graphql`. Use when asked to 'read the discussions', 'respond to this discussion', 'answer the discussion topic', 'reply to the forum', 'triage the discussion board', or 'check GitHub Discussions'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# discussions — read and respond to forum topics

Read a repo's GitHub Discussions and respond to a topic: list open topics, read
one with its comment thread, draft a reply, post it, and (on Q&A topics) mark a
comment as the accepted answer.

## When this fires

- User says "read the discussions", "check the discussion board", "what's on
  the forum"
- User says "respond to discussion #N", "reply to this topic", "answer the
  discussion"
- User says "mark that as the answer", "accept this answer"
- After a PR/issue thread points at a Discussions board and you need to follow up
  there

If the topic really belongs in the issue tracker (a concrete, actionable bug or
task), hand off to **[migrate-discussion](../migrate-discussion/SKILL.md)**
instead of just replying.

## How Discussions are reached — GraphQL only

Discussions are **not** in the REST API. There is **no `gh discussion`
subcommand** and **no `mcp__github__*` Discussions tool**. Every operation goes
through GraphQL:

- **Local session with `gh`:** run `gh api graphql` (shown below). This is the
  primary path.
- **Remote / web session (MCP only, no `gh`):** the GitHub MCP server exposes no
  Discussions tools and `gh` isn't installed, so Discussions may be unreachable.
  If the session has an authenticated GraphQL passthrough, use it; otherwise say
  so and surface it to the user — don't fake a reply that never posted.

`<owner>`/`<repo>` below are the repository; `<N>` is a discussion number. Use
`-F` for typed (Int) variables and `-f` for strings.

## Procedure

### 1. Confirm the repo has Discussions enabled

```bash
gh api graphql -f owner='<owner>' -f repo='<repo>' -f query='
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) { hasDiscussionsEnabled }
  }'
```

If `hasDiscussionsEnabled` is `false`, stop and tell the user — there's nothing
to read or post to.

### 2. List topics

```bash
gh api graphql -f owner='<owner>' -f repo='<repo>' -f query='
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      discussions(first: 20, orderBy: {field: UPDATED_AT, direction: DESC}) {
        nodes {
          number title url updatedAt
          category { name isAnswerable }
          answerChosenAt
          comments { totalCount }
        }
      }
    }
  }'
```

`answerChosenAt` is non-null when a Q&A topic already has an accepted answer;
`category.isAnswerable` marks a Q&A category. Report the list to the user with
clickable URLs.

### 3. Read one topic and its thread

The reply and answer mutations need node **IDs** (not numbers), so capture them
here:

```bash
gh api graphql -f owner='<owner>' -f repo='<repo>' -F number=<N> -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      discussion(number: $number) {
        id title body url
        author { login }
        category { name isAnswerable }
        answerChosenAt
        comments(first: 50) {
          nodes {
            id body isAnswer
            author { login }
            replies(first: 20) { nodes { id body author { login } } }
          }
        }
      }
    }
  }'
```

Note the discussion's `id` (for a top-level reply) and any comment `id` (to
reply in-thread or mark as the answer).

### 4. Draft the response — then get approval before posting

Posting to a public forum is outward-facing and hard to unsay. Draft the reply
first, show it to the user, and wait for explicit approval before posting. Apply
the plain-prose style (`use-preferred-style`): answer the actual question, be
direct, no filler. If the answer isn't clear from context, ask the user rather
than guessing on a public thread.

### 5. Post the reply

Top-level comment on the discussion (uses the discussion `id` from step 3):

```bash
gh api graphql -f discussionId='<discussion-id>' -f body='<reply text>' -f query='
  mutation($discussionId: ID!, $body: String!) {
    addDiscussionComment(input: {discussionId: $discussionId, body: $body}) {
      comment { id url }
    }
  }'
```

Threaded reply to a specific comment — add `replyToId` (the comment `id`):

```bash
gh api graphql -f discussionId='<discussion-id>' -f replyToId='<comment-id>' -f body='<reply text>' -f query='
  mutation($discussionId: ID!, $replyToId: ID!, $body: String!) {
    addDiscussionComment(input: {discussionId: $discussionId, replyToId: $replyToId, body: $body}) {
      comment { id url }
    }
  }'
```

### 6. Mark an answer (Q&A topics only)

Only categories where `isAnswerable` is true accept an answer. Mark a comment
(usually one you just posted, or an existing one the user points to):

```bash
gh api graphql -f commentId='<comment-id>' -f query='
  mutation($commentId: ID!) {
    markDiscussionCommentAsAnswer(input: {id: $commentId}) {
      discussion { url answerChosenAt }
    }
  }'
```

Use `unmarkDiscussionCommentAsAnswer` with the same input shape to undo it.

### 7. Report back

Give the user the posted comment's URL as a clickable link, and note whether an
answer was marked.

## Relationship to other skills

- **[migrate-discussion](../migrate-discussion/SKILL.md)** — when a topic is
  really an actionable bug/task (belongs in Issues) or an issue is really an
  open-ended question (belongs in Discussions), migrate it instead of replying.
- **[use-preferred-style](../use-preferred-style/SKILL.md)** — apply the
  plain-prose guide to the reply before posting.
- **[sup](../sup/SKILL.md)** — files issues/PRs (or Discussions) on an
  *upstream* repo; this skill responds on a repo you already work in.
- **[defer-issue](../defer-issue/SKILL.md)** — files a follow-up issue for
  out-of-scope work; reach for it if a discussion surfaces a task to track.

## Anti-patterns

- ❌ Posting to a public discussion **without showing the draft and getting
  approval** — outward-facing and hard to retract.
- ❌ Assuming `gh discussion ...` exists — it doesn't; use `gh api graphql`.
- ❌ Reporting a reply as posted in a remote/MCP session that can't actually
  reach Discussions — verify the mutation ran, or say it didn't.
- ❌ Marking an answer in a non-Q&A category — only `isAnswerable` categories
  accept one; the mutation errors otherwise.
- ❌ Guessing at a technical answer on a public thread — ask the user when the
  answer isn't clear from context.
