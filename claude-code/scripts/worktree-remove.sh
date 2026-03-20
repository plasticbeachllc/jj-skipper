#!/usr/bin/env bash
# worktree-remove: Claude Code WorktreeRemove hook.
# Forgets the jj workspace, cleans up .envrc, and removes the directory.
set -euo pipefail

die() {
  echo "jj-skipper: $1" >&2
  exit 1
}

validate_workspace_name() {
  local name="$1"
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || \
    die "invalid workspace name '$name' (allowed: letters, numbers, dot, underscore, dash)"
}

if ! command -v jq &>/dev/null; then
  die "jq is required for WorktreeRemove hook"
fi

# --- Parse hook payload ---
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -er '.name | select(type == "string" and length > 0)') || \
  die "hook payload must include a non-empty string 'name'"
MAIN_REPO=$(echo "$INPUT" | jq -er '.cwd | select(type == "string" and length > 0)') || \
  die "hook payload must include a non-empty string 'cwd'"
validate_workspace_name "$NAME"
[[ "$MAIN_REPO" = /* ]] || die "hook payload 'cwd' must be an absolute path"
[[ -d "$MAIN_REPO/.jj" ]] || die "main repository '$MAIN_REPO' is not a jj workspace root"
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
