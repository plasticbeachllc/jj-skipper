---
name: commit-push-pr
description: Commit, push bookmark, and open a PR on GitHub
---

# /commit-push-pr — Ship It

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

## 2. Pre-commit hook
If `.claude/jj-pre-commit.sh` exists and is executable, run it. Block on failure.

## 3. Commit
```bash
jj commit -m "<conventional-commit-message>"
```
Content is now in **@-**. New **@** is empty.

## 4. Verify bookmark
```bash
jj bookmark list
```
The bookmark should point at `@-`. If it doesn't:
```bash
jj bookmark set <feature-name> -r @-
```

## 5. Push
```bash
jj git push -b <feature-name>
```

## 6. Open PR
```bash
gh pr create --base main --head <feature-name> --title "<title>" --body "<body>"
```
Use the commit message as the PR title. Ask the user for any additional context for the body.

## 7. Show result
```bash
jj log -r '@ | @-'
```
Return the PR URL.
