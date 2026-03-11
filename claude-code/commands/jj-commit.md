---
name: jj-commit
description: Create focused jj commits with selective file grouping
---

# /jj-commit — Focused jj Commit

Follow these steps exactly:

## 1. Inspect changes
Run `jj st` and group changed files by category:
- **source**: application code (`.rs`, `.ts`, `.py`, `.go`, etc.)
- **config**: configuration files, manifests, lockfiles
- **docs**: documentation, README, CHANGELOG
- **tests**: test files
- **other**: everything else

## 2. Select files
- **Single category**: auto-select all files in that category. Confirm with user.
- **Multiple categories**: present the categories and let the user choose which to include.
- User can also specify exact files.

## 3. Pre-commit check
If `.claude/jj-pre-commit.sh` exists and is executable, run it. Block on failure.

## 4. Commit
```bash
jj commit -m "<conventional-commit-message>" <selected-files>
```

## 5. Show result
```bash
jj log -r '@ | @-'
```

## 6. Remind about pushing
Tell the user:
> Content is now in **@-**. To push:
> - **Named bookmark**: `jj bookmark set <name> -r @-` then `jj git push -b <name>`
> - **Auto-bookmark**: `jj git push -c @-`
