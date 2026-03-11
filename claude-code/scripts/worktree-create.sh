#!/usr/bin/env bash
# worktree-create: Claude Code WorktreeCreate hook.
# Parses hook JSON payload and delegates to shared workspace-create.sh.
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "jj-skipper: jq is required for WorktreeCreate hook" >&2
  exit 1
fi

INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
MAIN_REPO=$(echo "$INPUT" | jq -r '.cwd')

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/../../shared/scripts/workspace-create.sh" "$NAME" "$MAIN_REPO"
