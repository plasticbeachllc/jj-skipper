---
name: jj-commit-push-pr
description: "Commit, push bookmark, and open a PR on GitHub. Activate when the user
wants to ship code, open a PR, push changes, or finalize work on a bookmark."
---

# Commit, Push, and Open PR

Follow these steps exactly:

## 1. Pre-flight
```bash
jj st
jj bookmark list
```
Confirm there are changes to commit and identify the active bookmark.

If no bookmark exists on `@`, create one:
```bash
jj bookmark create <feature-name> -r @
```

## 2. Commit
```bash
jj commit -m "<conventional-commit-message>"
```
Content is now in **@-**. New **@** is empty.

## 3. Verify bookmark
```bash
jj bookmark list
```
The bookmark should point at `@-`. If it doesn't:
```bash
jj bookmark set <feature-name> -r @-
```

## 4. Push
```bash
jj git push -b <feature-name>
```

## 5. Open PR
```bash
gh pr create --base main --head <feature-name> --title "<title>" --body "<body>"
```
Use the commit message as the PR title. Ask the user for any additional context for the body.

## 6. Show result
```bash
jj log -r '@ | @-'
```
Return the PR URL.
