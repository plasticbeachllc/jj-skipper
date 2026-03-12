---
name: jj-workspace
description: "Create an isolated jj workspace and bookmark for parallel development.
Activate when starting new work, creating a feature branch, or entering a workspace."
---

# Start Work in an Isolated Workspace

## 1. Create workspace

Ask the user for a feature name (or derive from their task description).

```bash
MAIN_REPO=$(jj root)
WORKSPACE_PATH="$MAIN_REPO/.worktrees/<feature-name>"
mkdir -p "$MAIN_REPO/.worktrees"
jj workspace add "$WORKSPACE_PATH" --name <feature-name>
```

Wire up `$GIT_DIR` so `gh` CLI and other git-expecting tools work in the workspace:
```bash
if [[ -d "$MAIN_REPO/.git" ]]; then
  printf 'export GIT_DIR="%s/.git"\nexport GIT_WORK_TREE="%s"\n' "$MAIN_REPO" "$WORKSPACE_PATH" > "$WORKSPACE_PATH/.envrc"
  direnv allow "$WORKSPACE_PATH" 2>/dev/null || echo "Run 'source .envrc' in the workspace for gh CLI support."
fi
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
> File edits auto-amend into this change. When done, use `/jj-commit-push-pr` to ship.

## 4. When done

Use `/jj-commit-push-pr`, then clean up:
```bash
jj workspace forget <feature-name>
rm -rf <workspace-path>
```
