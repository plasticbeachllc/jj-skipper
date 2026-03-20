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
if [ -d .jj ] && [ -d .git ]; then
  probe=$(mktemp .git/.jj-skipper-write-test.XXXXXX 2>/dev/null) && rm -f "$probe"
fi
```
Confirm there are changes to commit and identify the active bookmark.

If the `.git` probe fails in Codex, stop immediately. Do not attempt `jj bookmark create`, `jj commit`, `jj git push`, or a `git` fallback. Tell the user this session can edit files but cannot perform VCS writes, and ask them to ship from a local shell or restart Codex with approvals/network enabled.

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
