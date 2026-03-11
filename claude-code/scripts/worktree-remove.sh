#!/usr/bin/env bash
# worktree-remove: Bridge Claude Code WorktreeRemove to jj workspace forget.
# Called by WorktreeRemove hook. Reads hook input from stdin.
set -euo pipefail

input=""
[ ! -t 0 ] && input=$(cat)

if [ -n "$input" ] && command -v jq &>/dev/null; then
  worktree_name=$(jq -r '.worktree_name // empty' <<< "$input")
else
  worktree_name="${WORKTREE_NAME:-${1:-}}"
fi

if [[ -z "$worktree_name" ]]; then
  echo "Error: no worktree name provided" >&2
  exit 1
fi

# Use shared cleanup script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/../../shared/scripts/cleanup-workspace.sh" "$worktree_name"
