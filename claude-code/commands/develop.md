---
name: develop
description: Enter isolated bookmark for parallel development. Each agent gets its own bookmark.
---

# /develop — Start Work on a New Bookmark

Follow these steps exactly:

## 1. Check current state
```bash
jj log -r '@ | @-' --limit 5
jj bookmark list
```

## 2. Create bookmark

Ask the user for a feature name (or derive from their task description).

```bash
jj new main -m "feat: <description>"
jj bookmark create <feature-name> -r @
```

Confirm:
> Working on bookmark **<feature-name>** (change **<change-id>**).
> File edits auto-amend into this change. When done, run `/commit-push-pr`.

## 3. Parallel safety rules

These rules apply when agents **share a working copy**. Agents in separate workspaces (via WorktreeCreate) each have their own `@` and are not affected.

**NEVER** run these commands while other agents share your working copy:
- `jj commit` — snapshots working copy, moves @
- `jj new` — moves @ to a new empty change
- `jj edit` — switches @ to a different change
- `jj squash` — modifies commit graph

These are safe anytime:
- `jj st` / `jj diff` / `jj log` (read-only)
- `jj describe -m "msg"` (updates message only, no @ movement)
- File edits via Write/Edit tools (guarded by file-lock)
