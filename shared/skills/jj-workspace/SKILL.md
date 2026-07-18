---
name: jj-workspace
description: "Create an isolated jj workspace and feature bookmark. Activate only for new parallel work, workspace creation, or feature isolation."
---

# Create a jj Workspace

Derive a safe feature name and run the bundled manager from this skill directory:

```bash
bash scripts/workspace.sh create \
  --repo "$(jj root)" \
  --name <feature-name> \
  --base fresh \
  --description "feat: <description>"
```

Use `--base head` only when the new workspace must include the current local change; otherwise keep the clean `fresh` base. The manager creates the workspace and bookmark atomically and prints its path.

Report the path, bookmark, base, and change ID. When finished, use `jj-commit-push-pr`, then run `bash scripts/workspace.sh remove --repo <repo> --path <workspace-path>`.
