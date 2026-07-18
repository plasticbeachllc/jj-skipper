---
name: jj-guide
description: "Reference for unfamiliar or complex jj operations, command translation, revsets, rewriting, repository diagnosis, or recovery. Use for lost work, bookmark errors, conflicts, divergence, stale workspaces, or operation-log forensics. Do not activate for routine status, diff, log, workspace creation, or shipping tasks covered by dedicated skills."
---

# jj Guide

Use this skill only when the task needs more than routine `jj st`, `jj diff`, or `jj log`, and is not fully covered by `jj-workspace` or `jj-commit-push-pr`.

## Invariants

- The working copy is commit `@`; edits automatically amend it.
- There is no staging area.
- Use `-m` for descriptions and commits; never open an editor or use `-i`.
- Prefer stable change IDs over commit IDs.
- After `jj commit -m "msg"`, committed content is at `@-` and the new `@` is empty.
- Conflicts live in commits. The operation log makes repository operations recoverable.

## Load only what the task needs

- Git command translation: [references/git-to-jj.md](references/git-to-jj.md)
- Bookmarks, syncing, rewriting, review, and selective changes: [references/workflows.md](references/workflows.md)
- Revsets and filesets: [references/revsets-filesets.md](references/revsets-filesets.md)
- Repository diagnosis, lost work, divergence, conflicts, or stale state: [references/recovery.md](references/recovery.md)

Do not read every reference. Select the narrowest relevant one.

For isolated workspace creation, use `jj-workspace`. For commit/push/PR delivery, use `jj-commit-push-pr`.
