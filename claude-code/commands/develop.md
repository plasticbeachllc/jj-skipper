---
name: develop
description: Start isolated work on a new jj change
---

# /develop — Start Isolated Work

Follow these steps exactly:

## 1. Capture current state
```bash
jj log -r '@ | @-' --limit 5
```

## 2. Create a new change
From the user's task description, create a descriptive commit message:
```bash
jj new main -m "feat: <description from user>"
```

## 3. Explain to user
> You're now on a new isolated change branched from **main**.
>
> - Your edits auto-amend into this change (no staging needed).
> - Other in-flight changes are untouched — switch with `jj edit <change-id>`.
> - When done, `jj commit -m "msg"` finalizes and starts a fresh change.
> - To push: `jj git push -c @-` (auto-bookmark) or set a named bookmark.

## 4. On completion
When the user's task is done:
```bash
jj commit -m "<conventional commit message>"
jj log -r '@- | @'
```

Remind the user:
> Content is in **@-**. To push:
> - `jj git push -c @-` (auto-bookmark for PR)
> - Or: `jj bookmark set <name> -r @-` then `jj git push -b <name>`
