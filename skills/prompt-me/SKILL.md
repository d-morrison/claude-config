---
name: prompt-me
description: >
  Restate every open question still waiting on user input — anything asked
  earlier in the conversation that hasn't been answered yet — as a single,
  clearly numbered list, instead of leaving it scattered across the
  transcript. Use when asked to 'prompt me', 'pm', 'what are you waiting on
  me for', 'what do you need from me', 'remind me what you asked', or
  '/prompt-me'.
user-invocable: true
allowed-tools: []
---

# prompt-me

Sweep the conversation for questions that were posed to the user but never
answered, and restate them together in one place. Long sessions bury a
question asked several turns back under unrelated work; this skill surfaces
it again instead of leaving it stranded.

## When this fires

- Explicit invocation: `/prompt-me`, `/pm`, "prompt me", "pm".
- The user asks a variant like "what are you waiting on me for?", "what do
  you need from me?", "did you ask me something?", or "remind me what you
  asked".

## Step 1 — Find candidate questions

Scan back through the current conversation (not prior sessions) for anything
that reads as a question directed at the user:

- Direct questions in your own prior messages (ending in `?`, or phrased as
  a request for a decision, confirmation, or missing information).
- Any pending `AskUserQuestion` call that was skipped, dismissed, or never
  resolved.
- Conditional asks embedded in a longer message ("let me know if...", "should
  I... or...", "confirm before I...").

Exclude:

- Questions the user already answered, even indirectly (a later message that
  makes the answer clear moots the question — don't re-ask it).
- Rhetorical questions or ones you answered yourself in the same message.
- Questions from a different task the user explicitly dropped or superseded.

## Step 2 — Restate them as a single list

List in reverse chronological order (most recent first), but group by topic
when several questions share the same task. For each item, give enough
context to answer cold — don't just repeat the bare question if the
surrounding detail (options, why it matters, what's blocked on it) got lost
upstream.

```
Still waiting on you for:
1. <question>, restated with the context that pins it down
2. <question>, ditto
```

If nothing is actually pending, say so plainly ("nothing open right now")
rather than manufacturing a question to fill the list.

## Step 3 — Don't re-decide anything

This skill only restates; it never guesses an answer or picks a default to
unblock itself. If a question turns out to be stale (events since have made
it moot), say that instead of listing it, but don't silently drop a question
just because answering it looks hard.
