---
name: develop
description: "Create an isolated jj workspace and bookmark for parallel development.
Activate when starting new work, creating a feature branch, or entering a workspace."
---

# Start Work in an Isolated Workspace

## 1. Create workspace

Ask the user for a feature name (or derive from their task description).

Run the workspace creation script:
```bash
bash <jj-skipper-path>/shared/scripts/workspace-create.sh <feature-name>
```

If the script is not available, create the workspace manually:
```bash
MAIN_REPO=$(jj root)
WORKSPACE_PATH="$MAIN_REPO/.worktrees/<feature-name>"
mkdir -p "$MAIN_REPO/.worktrees"
jj workspace add "$WORKSPACE_PATH" --name <feature-name>
```

## 2. Enter workspace
```bash
cd <workspace-path>
source .envrc    # if direnv is not auto-loading
```

## 3. Create bookmark
```bash
jj new main -m "feat: <description>"
jj bookmark create <feature-name> -r @
```

Confirm:
> Working on bookmark **<feature-name>** (change **<change-id>**) in workspace **<workspace-path>**.
> File edits auto-amend into this change. When done, use the commit-push-pr skill to ship.

## 4. When done

Use the commit-push-pr skill, then clean up:
```bash
jj workspace forget <feature-name>
rm -rf <workspace-path>
```
