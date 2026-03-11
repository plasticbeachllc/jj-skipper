#!/usr/bin/env bash
# worktree-create: Bridge Claude Code WorktreeCreate to jj workspace add.
# Called by WorktreeCreate hook. Reads hook input from stdin.
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

# Resolve repo root so paths work regardless of cwd
repo_root="$(jj root)"

# Create jj workspace (shared commit graph, isolated working copy)
jj workspace add "$worktree_name" --revision @
cd "$repo_root/$worktree_name"
jj new @

# Output the workspace path for Claude Code
echo "$(pwd)"
