---
name: develop
description: Enter isolated workspace and bookmark for parallel development.
isolation: worktree
---

# /develop — Start Work in an Isolated Workspace

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
> Working on bookmark **<feature-name>** (change **<change-id>**) in an isolated workspace.
> File edits auto-amend into this change. When done, run `/commit-push-pr`.
