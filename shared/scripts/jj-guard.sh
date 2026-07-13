#!/usr/bin/env bash
# jj-guard: Blocks bare git commands in jj-managed repositories.
# Dual-mode: reads Claude Code/Codex hook JSON from stdin or accepts a command argument.
set -euo pipefail

standalone=false

find_jj_root() {
  local check_dir="$1"
  while [[ "$check_dir" != "/" ]]; do
    if [[ -d "$check_dir/.jj" ]]; then
      printf '%s\n' "$check_dir"
      return 0
    fi
    check_dir="$(dirname "$check_dir")"
  done
  return 1
}

deny() {
  local reason="$1"
  if [[ "$standalone" == true ]]; then
    echo "BLOCKED: $reason" >&2
    exit 1
  fi

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
    exit 2
  fi
}

if [[ $# -gt 0 ]]; then
  standalone=true
  command_text="$1"
  hook_cwd="$(pwd)"
  hook_event=""
elif [[ ! -t 0 ]]; then
  input=$(cat)
  if [[ -n "$input" ]] && command -v jq &>/dev/null; then
    command_text=$(jq -r '.tool_input.command // empty' <<< "$input")
    hook_cwd=$(jq -r '.cwd // empty' <<< "$input")
    hook_event=$(jq -r '.hook_event_name // empty' <<< "$input")
  else
    command_text=""
    hook_cwd=""
    hook_event=""
  fi
else
  command_text=""
  hook_cwd=""
  hook_event=""
fi

[[ -d "$hook_cwd" ]] || hook_cwd="$(pwd)"

if [[ "$hook_event" == "SessionStart" ]]; then
  if find_jj_root "$hook_cwd" &>/dev/null; then
    jq -cn '{
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "This is a jj repository. Use jj for VCS operations; keep commands non-interactive with explicit messages and prefer change IDs. The working copy is @; after jj commit, committed content is at @-. Load a jj-skipper skill only for workspace creation, shipping, unfamiliar operations, or recovery."
      }
    }'
  fi
  exit 0
fi

[[ -z "$command_text" ]] && exit 0

# Explicit escape hatch for git-only operations such as LFS and submodules.
[[ "$command_text" == :\;git\ * ]] && exit 0

# Match git at the start of a command or after a shell command separator. This
# catches simple compound commands such as `cd src && git status` without
# treating ordinary arguments containing the word "git" as commands.
git_pattern='(^|[;&|][[:space:]]*|\([[:space:]]*)(command[[:space:]]+|env[[:space:]]+|sudo[[:space:]]+)?git([[:space:]]|$)'
[[ "$command_text" =~ $git_pattern ]] || exit 0

find_jj_root "$hook_cwd" &>/dev/null || exit 0

# Extract the first git subcommand for a useful suggestion. Fall back to a
# generic pointer when the shell expression is too complex to classify.
git_subcmd=$(sed -E 's/(^|.*[;&|][[:space:]]*|.*\([[:space:]]*)(command[[:space:]]+|env[[:space:]]+|sudo[[:space:]]+)?git[[:space:]]+([^[:space:];&|]+).*/\3/' <<< "$command_text")

case "$git_subcmd" in
  status)      jj_equiv="jj st" ;;
  diff)        jj_equiv="jj diff" ;;
  log)         jj_equiv="jj log" ;;
  show)        jj_equiv="jj show" ;;
  blame)       jj_equiv="jj file annotate" ;;
  add)         jj_equiv="(not needed — jj tracks changes automatically)" ;;
  commit)      jj_equiv="jj commit -m 'msg'" ;;
  push)        jj_equiv="jj git push" ;;
  pull)        jj_equiv="jj git fetch, then update/rebase the local bookmark" ;;
  fetch)       jj_equiv="jj git fetch" ;;
  clone)       jj_equiv="jj git clone" ;;
  init)        jj_equiv="jj git init" ;;
  checkout|switch) jj_equiv="jj new <rev> or jj edit <rev>" ;;
  branch)      jj_equiv="jj bookmark" ;;
  merge)       jj_equiv="jj new <rev1> <rev2>" ;;
  rebase)      jj_equiv="jj rebase" ;;
  reset)       jj_equiv="jj restore or jj abandon" ;;
  stash)       jj_equiv="jj new" ;;
  cherry-pick) jj_equiv="jj duplicate" ;;
  revert)      jj_equiv="jj revert" ;;
  tag)         jj_equiv="jj tag" ;;
  worktree)    jj_equiv="jj workspace" ;;
  *)           jj_equiv="check the jj-guide skill" ;;
esac

deny "This is a jj repository. Use jj instead of bare git.
  git $git_subcmd → $jj_equiv
Refer to the jj-guide skill for full command mappings.
Escape hatch for git-only operations: prefix the command with :;git."
