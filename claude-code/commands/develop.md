---
name: develop
description: Start or join a working change for isolated development. Safe for parallel agents.
---

# /develop — Start or Join a Working Change

Follow these steps exactly:

## 1. Check current state
```bash
jj log -r '@ | @-' --limit 5
```

## 2. Decide: create or join

**If @ is empty and sitting on main/trunk** (fresh state):
```bash
jj new main -m "feat: <description from user>"
```

**If @ already has a description or changes** (another agent is working):
Do NOT run `jj new`. You are joining an in-progress working change. Just start editing.
Say:
> Joining existing working change: **<change-id>** — "<description>"

## 3. Explain to user
> You're working in change **<change-id>**.
>
> - File edits auto-amend into this change.
> - The file-lock hook prevents two agents from editing the same file.
> - **Do NOT run `jj commit` or `jj new` while other agents are active.**
>   These commands move @ and would disrupt parallel work.
> - When all agents are done, finalize with `jj commit -m "msg"`.

## 4. Parallel safety rules

**NEVER** run these commands while other agents may be active:
- `jj commit` — snapshots working copy, moves @
- `jj new` — moves @ to a new empty change
- `jj edit` — switches @ to a different change
- `jj squash` — modifies commit graph

These are safe anytime:
- `jj st` / `jj diff` / `jj log` (read-only)
- `jj describe -m "msg"` (updates message only, no @ movement)
- File edits via Write/Edit tools (guarded by file-lock)

## 5. On completion (single agent or last agent standing)
```bash
jj commit -m "<conventional commit message>"
jj log -r '@- | @'
```

Remind the user:
> Content is in **@-**. To push:
> - `jj git push -c @-` (auto-bookmark for PR)
> - Or: `jj bookmark set <name> -r @-` then `jj git push -b <name>`
