#!/usr/bin/env bash
# workspace-create: Creates an isolated jj workspace with $GIT_DIR wiring.
# Works standalone (CLI args) or called by other scripts.
#
# Usage: workspace-create.sh <name> [repo-root]
#   name      — workspace name (used for directory and jj workspace name)
#   repo-root — main repo root (defaults to current jj repo root)
set -euo pipefail

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: workspace-create.sh <name> [repo-root]" >&2
  exit 1
fi

if ! command -v jj &>/dev/null; then
  echo "jj-skipper: jj is required" >&2
  exit 1
fi

MAIN_REPO="${2:-$(jj root 2>/dev/null || pwd)}"
WORKTREE_PATH="$MAIN_REPO/.worktrees/$NAME"

# --- Create jj workspace ---
mkdir -p "$MAIN_REPO/.worktrees"
jj workspace add "$WORKTREE_PATH" --name "$NAME"

# --- Wire GIT_DIR for gh CLI and other git-expecting tools ---
if [[ -d "$MAIN_REPO/.git" ]]; then
  cat > "$WORKTREE_PATH/.envrc" <<EOF
export GIT_DIR="$MAIN_REPO/.git"
export GIT_WORK_TREE="$WORKTREE_PATH"
EOF
  direnv allow "$WORKTREE_PATH" 2>/dev/null || \
    echo "jj-skipper: direnv not found. Run 'source .envrc' in the workspace for gh CLI support." >&2
fi

# --- Print the workspace path ---
echo "$WORKTREE_PATH"
