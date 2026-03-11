---
name: develop
description: Enter isolated jj workspace for parallel work
---

# /develop — Isolated jj Workspace

Follow these steps exactly:

## 1. Generate workspace name
From the user's task description, generate a name: `claude-<feature>-YYYYMMDD`
Example: `claude-auth-refactor-20260310`

## 2. Create workspace
Use the EnterWorktree tool with the generated name. This triggers the WorktreeCreate hook which runs `jj workspace add` under the hood.

## 3. Explain to user
> You're now in an isolated jj workspace: **<name>**
>
> - Commits are shared across all workspaces (same repo).
> - Working copy is isolated — edits here don't affect the main workspace.
> - No merge needed — when done, the commits are already in the graph.

## 4. On completion
When the user's task is done:
```bash
jj workspace forget <name>
```
Then use ExitWorktree to return. The workspace directory is cleaned up automatically by the WorktreeRemove hook.
