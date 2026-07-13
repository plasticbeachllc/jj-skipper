---
name: jj-workspace
description: "Create an isolated jj workspace and feature bookmark. Activate only for new parallel work, workspace creation, or feature isolation."
---

# Create a jj Workspace

Derive a safe feature name, then run:

```bash
MAIN_REPO=$(jj root)
WORKSPACE_PATH="$MAIN_REPO/.worktrees/<feature-name>"
mkdir -p "$MAIN_REPO/.worktrees"
jj -R "$MAIN_REPO" workspace add "$WORKSPACE_PATH" --name <feature-name>
cd "$WORKSPACE_PATH"
jj new main -m "feat: <description>"
jj bookmark create <feature-name> -r @
```

For colocated repositories, wire Git-dependent tools:

```bash
printf 'export GIT_DIR="%s/.git"\nexport GIT_WORK_TREE="%s"\n' \
  "$MAIN_REPO" "$WORKSPACE_PATH" > .envrc
direnv allow 2>/dev/null || echo "Run: source .envrc"
```

Report the workspace path, bookmark, and change ID. When finished, use `jj-commit-push-pr`, then clean up with `jj -R "$MAIN_REPO" workspace forget <feature-name>`.
