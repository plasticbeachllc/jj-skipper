#!/usr/bin/env bash
# file-lock: File-level locking for multi-agent jj workflows.
# Called by PreToolUse hook on Write/Edit. Blocks concurrent edits to the same file.
set -euo pipefail

# Read CC hook input from stdin
if [[ $# -gt 0 ]]; then
  echo "Usage: pipe CC hook JSON to stdin" >&2
  exit 1
fi

input=""
[ ! -t 0 ] && input=$(cat)
[[ -z "$input" ]] && exit 0

# Only guard Write and Edit
tool_name=$(jq -r '.tool_name // empty' <<< "$input")
case "$tool_name" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Extract file path
file_path=$(jq -r '.tool_input.file_path // empty' <<< "$input")
[[ -z "$file_path" ]] && exit 0

# Resolve to absolute path
if [[ "$file_path" != /* ]]; then
  cwd=$(jq -r '.cwd // empty' <<< "$input")
  [[ -z "$cwd" ]] && cwd="$(pwd)"
  file_path="$cwd/$file_path"
fi

# Session ID from hook input
session_id=$(jq -r '.session_id // empty' <<< "$input")
[[ -z "$session_id" ]] && exit 0

# Lock directory keyed by repo root
repo_root="$(jq -r '.cwd // empty' <<< "$input")"
[[ -z "$repo_root" ]] && repo_root="$(pwd)"
repo_hash=$(echo "$repo_root" | shasum -a 256 | cut -c1-12)
lock_dir="/tmp/jj-skipper-locks/$repo_hash"
mkdir -p "$lock_dir"

# Encode file path to a safe filename
lock_file="$lock_dir/$(echo "$file_path" | shasum -a 256 | cut -c1-16).lock"

# Check for existing lock
if [[ -f "$lock_file" ]]; then
  lock_session=$(head -1 "$lock_file" 2>/dev/null || echo "")
  lock_age=0

  # Stale lock detection: locks older than 10 minutes are considered stale
  if [[ -f "$lock_file" ]]; then
    lock_mtime=$(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)
    now=$(date +%s)
    lock_age=$((now - lock_mtime))
  fi

  if [[ "$lock_session" != "$session_id" && $lock_age -lt 600 ]]; then
    # Different session holds a fresh lock — block
    lock_file_path=$(sed -n '2p' "$lock_file" 2>/dev/null || echo "$file_path")
    jq -cn --arg reason "File is being edited by another agent session.
  File: $lock_file_path
  Locked by session: $lock_session
  Lock age: ${lock_age}s

Choose a different file to edit, or wait for the other session to finish.
If the lock is stale, it will expire after 10 minutes." '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      }
    }'
    exit 1
  fi
fi

# Acquire or refresh lock
echo "$session_id" > "$lock_file"
echo "$file_path" >> "$lock_file"
exit 0
