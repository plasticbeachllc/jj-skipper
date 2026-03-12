#!/usr/bin/env bash
# worktree-remove: Claude Code WorktreeRemove hook.
# Forgets the jj workspace, cleans up .envrc, and removes the directory.
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "jj-skipper: jq is required for WorktreeRemove hook" >&2
  exit 1
fi

# --- Parse hook payload ---
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
MAIN_REPO=$(echo "$INPUT" | jq -r '.cwd')
WORKTREE_PATH="$MAIN_REPO/.worktrees/$NAME"

# --- Forget workspace ---
if command -v jj &>/dev/null; then
  jj workspace forget "$NAME" 2>/dev/null || true
fi

# --- Clean up .envrc ---
if [[ -f "$WORKTREE_PATH/.envrc" ]]; then
  direnv deny "$WORKTREE_PATH" 2>/dev/null || true
  rm -f "$WORKTREE_PATH/.envrc"
fi

# --- Remove directory ---
if [[ -d "$WORKTREE_PATH" ]]; then
  rm -rf "$WORKTREE_PATH"
fi
