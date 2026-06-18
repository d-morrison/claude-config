---
name: slide-tag
description: "Force-move a floating Git tag (e.g., v2) to a new commit — typically current main HEAD. Handles fetch, safety checks, delete+recreate pattern. Use when asked to 'slide <tag>', 'move tag to main', 'update the v2 tag', or 'bump the floating tag'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# Slide Tag

Force-move a floating Git tag to a new target commit. Used for repos where
consumers pin to a major-version tag (e.g., `v2`) that advances with each
release.

## When this fires

- User says "slide v2", "slide the tag", "move tag to main"
- User says "update the v2 tag", "bump the floating tag"
- After merging work to main when the repo uses floating version tags

## Procedure

### 1. Determine tag and target

- **Tag:** from user input (e.g., "slide v2" → tag is `v2`)
- **Target:** defaults to `origin/main` unless user specifies otherwise

### 2. Fetch and validate

```bash
git fetch origin main --tags
```

Confirm the tag exists:
```bash
git tag -l '<tag>'   # should output the tag name
```

If the tag doesn't exist yet, create it fresh (skip the delete steps):
```bash
git tag <tag> <target>
git push origin <tag>
```

### 3. Show what's moving

Display the before/after so the user can sanity-check:
```bash
echo "Current: $(git log --oneline -1 <tag>)"
echo "Target:  $(git log --oneline -1 <target>)"
echo "Commits being added:"
git log --oneline <tag>..<target> | head -20
```

### 4. Slide the tag

```bash
git tag -d <tag>
git tag <tag> <target>
git push origin :refs/tags/<tag>
git push origin <tag>
```

**Why delete+recreate instead of `git push --force`?** Some GitLab/GitHub
instances have protected-tag rules that block force-push but allow
delete+create. The delete+recreate pattern works universally.

### 5. Confirm

```bash
git log --oneline -1 <tag>
```

Report the new tag position to the user.

## Edge cases

- **Tag doesn't exist yet:** Skip delete, just create and push.
- **Target is behind current tag:** Warn the user — this would move the tag
  backward. Proceed only if confirmed.
- **Protected tag on remote:** If delete fails with a permission error, the
  tag is protected. Inform the user they need to unprotect it in the repo
  settings first (Settings → Repository → Protected Tags on GitLab).

## Examples

```
User: "slide v2"
→ moves v2 to origin/main

User: "slide v2 to abc123"
→ moves v2 to commit abc123

User: "slide v3 to the release branch"
→ moves v3 to origin/release (or whatever the release branch is)
```

## Anti-patterns

- ❌ Using `git push --force origin <tag>` without trying delete first
- ❌ Sliding without fetching first (tag might already be at target)
- ❌ Sliding without showing the user what commits are being added
- ❌ Moving a tag backward without explicit confirmation
