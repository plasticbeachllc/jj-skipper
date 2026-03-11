#!/usr/bin/env bash
# cleanup-workspace: Remove stale jj workspaces and their directories.
# Used by WorktreeRemove hooks and manual cleanup.
set -euo pipefail

workspace_name="${1:-}"
workspace_dir="${2:-}"

if [[ -z "$workspace_name" ]]; then
  echo "Usage: cleanup-workspace.sh <workspace-name> [workspace-dir]" >&2
  exit 1
fi

# Resolve workspace directory relative to repo root
if [[ -z "$workspace_dir" ]]; then
  if command -v jj &>/dev/null; then
    repo_root="$(jj root 2>/dev/null || pwd)"
  else
    repo_root="$(pwd)"
  fi
  workspace_dir="$repo_root/$workspace_name"
fi

# Forget the workspace in jj (ignore errors if already forgotten or jj not available)
if command -v jj &>/dev/null; then
  if jj workspace forget "$workspace_name" 2>/dev/null; then
    echo "Forgot workspace: $workspace_name"
  else
    echo "Workspace already forgotten or not found: $workspace_name"
  fi
else
  echo "Warning: jj not found in PATH, skipping workspace forget" >&2
fi

# Remove .envrc before directory removal (avoid stale GIT_DIR pointers)
if [[ -f "$workspace_dir/.envrc" ]]; then
  direnv deny "$workspace_dir" 2>/dev/null || true
  rm -f "$workspace_dir/.envrc"
fi

# Remove the workspace directory if it exists
if [[ -d "$workspace_dir" ]]; then
  rm -rf "$workspace_dir"
  echo "Removed directory: $workspace_dir"
fi

echo "Workspace $workspace_name cleaned up."
