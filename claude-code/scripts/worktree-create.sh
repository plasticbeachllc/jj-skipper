#!/usr/bin/env bash
# worktree-create: Claude Code WorktreeCreate hook.
# Creates an isolated jj workspace with GIT_DIR wiring for gh CLI.
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
  die "jq is required for WorktreeCreate hook"
fi

if ! command -v jj &>/dev/null; then
  die "jj is required"
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
