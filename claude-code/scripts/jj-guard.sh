#!/usr/bin/env bash
# jj-guard: Blocks git mutations in jj-managed repositories.
# Dual-mode: reads Claude Code hook JSON from stdin, also works standalone.
#
# Inspired by kawaz/claude-plugin-jj and kalupa/jj-workflow.
set -euo pipefail

deny() {
  local reason="$1"
  if command -v jq &>/dev/null; then
    jq -cn --arg reason "$reason" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      }
    }'
  else
    echo "BLOCKED: $reason" >&2
  fi
  exit 1
}

# Read CC hook input; handle non-CC invocation gracefully
if [[ $# -gt 0 ]]; then
  # Standalone mode: command passed as argument
  command="$1"
elif [ ! -t 0 ]; then
  # CC hook mode: JSON on stdin
  input=$(cat)
  if [ -n "$input" ] && command -v jq &>/dev/null; then
    command=$(jq -r '.tool_input.command // empty' <<< "$input")
  else
    command=""
  fi
else
  command=""
fi

[[ -z "$command" ]] && exit 0

# Escape hatch: :;git prefix allows raw git when truly needed
if [[ "$command" == ":;git "* ]]; then
  exit 0
fi

# Only intercept commands starting with "git "
[[ "$command" != git\ * ]] && exit 0

# Walk up to find .jj directory
check_dir="$(pwd)"
found_jj=false
while [[ "$check_dir" != "/" ]]; do
  [[ -d "$check_dir/.jj" ]] && found_jj=true && break
  check_dir="$(dirname "$check_dir")"
done
[[ "$found_jj" == false ]] && exit 0

# Extract git subcommand
git_subcmd=$(echo "$command" | awk '{print $2}')

case "$git_subcmd" in
  status)      jj_equiv="jj st" ;;
  diff)        jj_equiv="jj diff" ;;
  log)         jj_equiv="jj log" ;;
  show)        jj_equiv="jj show" ;;
  blame)       jj_equiv="jj file annotate" ;;
  add)         jj_equiv="(not needed — jj tracks all changes automatically)" ;;
  commit)      jj_equiv="jj commit -m 'msg'" ;;
  push)        jj_equiv="jj git push" ;;
  pull)        jj_equiv="jj git fetch && jj bookmark set main -r main@origin (then jj rebase -d main@origin if local commits exist)" ;;
  fetch)       jj_equiv="jj git fetch" ;;
  clone)       jj_equiv="jj git clone" ;;
  init)        jj_equiv="jj git init" ;;
  checkout|switch) jj_equiv="jj new <rev> or jj edit <rev>" ;;
  branch)      jj_equiv="jj bookmark" ;;
  merge)       jj_equiv="jj new <rev1> <rev2>" ;;
  rebase)      jj_equiv="jj rebase" ;;
  reset)       jj_equiv="jj restore or jj abandon" ;;
  stash)       jj_equiv="(not needed — use jj new to start fresh work)" ;;
  cherry-pick) jj_equiv="jj duplicate" ;;
  revert)      jj_equiv="jj revert" ;;
  tag)         jj_equiv="jj tag" ;;
  worktree)    jj_equiv="jj workspace" ;;
  *)           jj_equiv="(check jj --help)" ;;
esac

deny "This is a jj repository. Use jj instead of git.
  git $git_subcmd → $jj_equiv
Refer to the jj-guide skill for full command reference.
For complex VCS issues, invoke jj-doctor.
Escape hatch: prefix with :;git for git-only operations (submodule, lfs)."
