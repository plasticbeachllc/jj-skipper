#!/usr/bin/env bash
# worktree-remove: Bridges Claude Code WorktreeRemove to jj workspace cleanup.
# Removes .envrc, forgets the workspace, and deletes the directory.
set -euo pipefail

# --- Preflight ---
if ! command -v jq &>/dev/null; then
  echo "jj-skipper: jq is required for WorktreeRemove hook" >&2
  exit 1
fi

# --- Parse hook payload ---
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
MAIN_REPO=$(echo "$INPUT" | jq -r '.cwd')
WORKTREE_PATH="$MAIN_REPO/.worktrees/$NAME"

# --- Delegate to shared cleanup script ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/../../shared/scripts/cleanup-workspace.sh" "$NAME" "$WORKTREE_PATH"
