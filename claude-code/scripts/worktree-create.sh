#!/usr/bin/env bash
# worktree-create: Bridges Claude Code WorktreeCreate to jj workspace add,
# and wires $GIT_DIR so gh CLI works in the new workspace.
set -euo pipefail

# --- Preflight ---
if ! command -v jq &>/dev/null; then
  echo "jj-skipper: jq is required for WorktreeCreate hook" >&2
  exit 1
fi

if ! command -v jj &>/dev/null; then
  echo "jj-skipper: jj is required for WorktreeCreate hook" >&2
  exit 1
fi

# --- Parse hook payload ---
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
MAIN_REPO=$(echo "$INPUT" | jq -r '.cwd')
WORKTREE_PATH="$MAIN_REPO/.worktrees/$NAME"

# --- Create jj workspace ---
mkdir -p "$MAIN_REPO/.worktrees"
jj workspace add "$WORKTREE_PATH" --name "$NAME"

# --- Wire GIT_DIR for gh CLI and other git-expecting tools ---
cat > "$WORKTREE_PATH/.envrc" <<EOF
export GIT_DIR="$MAIN_REPO/.git"
export GIT_WORK_TREE="$WORKTREE_PATH"
EOF

direnv allow "$WORKTREE_PATH" 2>/dev/null || \
  echo "jj-skipper: direnv not found. Agent should run 'source .envrc' in the worktree for gh CLI support." >&2

# --- Print path — Claude Code uses this as the working directory ---
echo "$WORKTREE_PATH"
