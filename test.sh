#!/usr/bin/env bash
# jj-skipper test suite
# Run from repo root: bash test.sh
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }
warn() { WARN=$((WARN + 1)); echo "  WARN: $1"; }

section() { echo ""; echo "=== $1 ==="; }

# ---------- Structure ----------
section "Repository structure"

expected_files=(
  shared/skills/jj-guide/SKILL.md
  shared/skills/jj-guide/references/git-to-jj.md
  shared/skills/jj-guide/references/workflows.md
  shared/skills/jj-guide/references/revsets-filesets.md
  shared/skills/jj-guide/references/recovery.md
  shared/skills/jj-commit-push-pr/SKILL.md
  shared/skills/jj-workspace/SKILL.md
  shared/scripts/jj-guard.sh
  claude-code/.claude-plugin/plugin.json
  claude-code/hooks/hooks.json
  claude-code/scripts/worktree-create.sh
  claude-code/scripts/worktree-remove.sh
  claude-code/agents/jj-doctor.md
  codex/.codex-plugin/plugin.json
  codex/hooks/hooks.json
  codex/scripts/jj-guard.sh
  codex/rules/jj-skipper-strict.rules
  codex/install.sh
  .agents/plugins/marketplace.json
  scripts/sync-adapters.sh
  LICENSE.md
  README.md
  CHANGELOG.md
  AGENTS.template.md
)

for f in "${expected_files[@]}"; do
  if [[ -e "$f" ]]; then
    pass "$f exists"
  else
    fail "$f missing"
  fi
done

# ---------- Self-contained adapter assets ----------
section "Self-contained adapter assets"

adapter_skill_dirs=(
  "claude-code/skills/jj-guide"
  "claude-code/skills/jj-commit-push-pr"
  "claude-code/skills/jj-workspace"
  "codex/skills/jj-guide"
  "codex/skills/jj-commit-push-pr"
  "codex/skills/jj-workspace"
)
for d in "${adapter_skill_dirs[@]}"; do
  if [[ -d "$d" ]] && [[ ! -L "$d" ]]; then
    pass "$d is a real directory (plugin cache compatible)"
  elif [[ -L "$d" ]]; then
    fail "$d is a symlink (may not survive plugin cache copy)"
  else
    fail "$d missing"
  fi
done

# ---------- Executables ----------
section "Executable bits"

executables=(
  claude-code/scripts/jj-guard.sh
  claude-code/scripts/worktree-create.sh
  claude-code/scripts/worktree-remove.sh
  shared/scripts/jj-guard.sh
  codex/scripts/jj-guard.sh
  codex/install.sh
  scripts/sync-adapters.sh
)

for f in "${executables[@]}"; do
  if [[ -x "$f" ]]; then
    pass "$f is executable"
  else
    fail "$f is not executable"
  fi
done

# ---------- Shell syntax ----------
section "Shell script syntax (bash -n)"

scripts=(
  claude-code/scripts/jj-guard.sh
  claude-code/scripts/worktree-create.sh
  claude-code/scripts/worktree-remove.sh
  shared/scripts/jj-guard.sh
  codex/scripts/jj-guard.sh
  codex/install.sh
  scripts/sync-adapters.sh
)

for s in "${scripts[@]}"; do
  if bash -n "$s" 2>/dev/null; then
    pass "$s parses OK"
  else
    fail "$s has syntax errors"
  fi
done

# ---------- JSON validity ----------
section "JSON validity"

json_files=(
  claude-code/.claude-plugin/plugin.json
  claude-code/hooks/hooks.json
  .claude-plugin/marketplace.json
  codex/.codex-plugin/plugin.json
  codex/hooks/hooks.json
  .agents/plugins/marketplace.json
)

for j in "${json_files[@]}"; do
  if jq empty "$j" 2>/dev/null; then
    pass "$j is valid JSON"
  else
    fail "$j is invalid JSON"
  fi
done

# ---------- Shared content synchronization ----------
section "Shared content synchronization"

while IFS= read -r shared_file; do
  relative_path="${shared_file#shared/skills/}"
  for adapter in claude-code codex; do
    adapter_file="$adapter/skills/$relative_path"
    if cmp -s "$shared_file" "$adapter_file"; then
      pass "$adapter_file matches canonical source"
    else
      fail "$adapter_file differs from $shared_file (run scripts/sync-adapters.sh)"
    fi
  done
done < <(find shared/skills -type f | sort)

for adapter_guard in claude-code/scripts/jj-guard.sh codex/scripts/jj-guard.sh; do
  if cmp -s shared/scripts/jj-guard.sh "$adapter_guard"; then
    pass "$adapter_guard matches canonical guard"
  else
    fail "$adapter_guard differs from shared/scripts/jj-guard.sh"
  fi
done

# ---------- Codex plugin contract ----------
section "Codex plugin contract"

codex_manifest="codex/.codex-plugin/plugin.json"
if [[ $(jq -r '.name' "$codex_manifest") == "jj-skipper" ]] &&
   [[ $(jq -r '.skills' "$codex_manifest") == "./skills/" ]]; then
  pass "Codex plugin manifest identifies jj-skipper and its skills"
else
  fail "Codex plugin manifest has incorrect identity or skills path"
fi

codex_version=$(jq -r '.version' "$codex_manifest")
claude_version=$(jq -r '.plugins[] | select(.name == "jj-skipper") | .version' .claude-plugin/marketplace.json)
if [[ "$codex_version" == "$claude_version" ]]; then
  pass "Claude Code and Codex adapters publish the same version"
else
  fail "adapter versions differ: Claude Code $claude_version, Codex $codex_version"
fi

if jq -e '.hooks.PreToolUse[] | select(.matcher == "^Bash$")' codex/hooks/hooks.json &>/dev/null; then
  pass "Codex plugin declares a Bash PreToolUse hook"
else
  fail "Codex plugin is missing its Bash PreToolUse hook"
fi

if jq -e '.hooks.SessionStart[] | select(.matcher | contains("startup"))' codex/hooks/hooks.json &>/dev/null; then
  pass "Codex plugin declares conditional startup context"
else
  fail "Codex plugin is missing conditional startup context"
fi

if jq -e '.plugins[] | select(.name == "jj-skipper" and .source.path == "./codex")' \
  .agents/plugins/marketplace.json &>/dev/null; then
  pass "Codex marketplace exposes the native plugin"
else
  fail "Codex marketplace is missing the native plugin"
fi

if command -v codex &>/dev/null; then
  plugin_home=$(mktemp -d)
  mkdir -p "$plugin_home/codex"
  if CODEX_HOME="$plugin_home/codex" codex plugin marketplace add "$PWD" &>/dev/null &&
     CODEX_HOME="$plugin_home/codex" codex plugin add jj-skipper@jj-skipper &>/dev/null &&
     CODEX_HOME="$plugin_home/codex" codex plugin list | grep -q 'jj-skipper@jj-skipper.*installed, enabled'; then
    pass "fresh Codex home discovers and enables the native plugin"
  else
    fail "fresh Codex home could not install the native plugin"
  fi
  rm -rf "$plugin_home"
else
  warn "codex not installed — skipping native plugin discovery smoke test"
fi

# ---------- Auto-discovery structure ----------
section "Plugin auto-discovery (default directories)"

plugin_root="claude-code"
for dir in hooks agents skills; do
  if [[ -d "$plugin_root/$dir" ]]; then
    pass "plugin has $dir/ directory"
  else
    fail "plugin missing $dir/ directory"
  fi
done

# ---------- hooks.json references ----------
section "hooks.json script references"

# Extract script paths from hooks.json (they use ${CLAUDE_PLUGIN_ROOT})
hook_scripts=$(jq -r '.. | .command? // empty' "$plugin_root/hooks/hooks.json" | sed "s|\\\${CLAUDE_PLUGIN_ROOT}|$plugin_root|g")
while IFS= read -r cmd; do
  # Extract the script path (after "bash ")
  script_path="${cmd#bash }"
  if [[ -e "$script_path" ]]; then
    pass "hook -> $script_path exists"
  else
    fail "hook -> $script_path not found"
  fi
done <<< "$hook_scripts"

# ---------- SKILL.md frontmatter ----------
section "SKILL.md frontmatter"

skill_file="shared/skills/jj-guide/SKILL.md"
if head -1 "$skill_file" | grep -q "^---"; then
  pass "SKILL.md has frontmatter delimiter"
else
  fail "SKILL.md missing frontmatter"
fi

if sed -n '2,/^---$/p' "$skill_file" | grep -q "^name:"; then
  pass "SKILL.md has name field"
else
  fail "SKILL.md missing name field"
fi

if sed -n '2,/^---$/p' "$skill_file" | grep -q "^description:"; then
  pass "SKILL.md has description field"
else
  fail "SKILL.md missing description field"
fi

# ---------- Context budgets ----------
section "Context budgets"

assert_word_budget() {
  local file="$1"
  local budget="$2"
  local count
  count=$(wc -w < "$file" | tr -d ' ')
  if (( count <= budget )); then
    pass "$file uses $count/$budget words"
  else
    fail "$file uses $count words (budget: $budget)"
  fi
}

assert_word_budget AGENTS.template.md 100
assert_word_budget shared/skills/jj-guide/SKILL.md 350
assert_word_budget shared/skills/jj-commit-push-pr/SKILL.md 180
assert_word_budget shared/skills/jj-workspace/SKILL.md 150

# ---------- Agent frontmatter ----------
section "jj-doctor.md frontmatter"

agent_file="claude-code/agents/jj-doctor.md"
if head -1 "$agent_file" | grep -q "^---"; then
  pass "jj-doctor.md has frontmatter delimiter"
else
  fail "jj-doctor.md missing frontmatter"
fi

for field in name description model tools; do
  if sed -n '2,/^---$/p' "$agent_file" | grep -q "^${field}:"; then
    pass "jj-doctor.md has $field field"
  else
    fail "jj-doctor.md missing $field field"
  fi
done

# ---------- jj command existence ----------
section "jj commands exist"

if ! command -v jj &>/dev/null; then
  warn "jj not installed — skipping command existence checks"
else

jj_commands=(
  "st"
  "diff"
  "log"
  "show"
  "commit"
  "describe"
  "squash"
  "new"
  "edit"
  "bookmark"
  "git push"
  "git fetch"
  "git clone"
  "git init"
  "rebase"
  "restore"
  "abandon"
  "duplicate"
  "revert"
  "tag"
  "workspace"
  "file annotate"
  "undo"
  "op log"
  "split"
  "absorb"
  "interdiff"
  "parallelize"
  "fix"
)

for cmd in "${jj_commands[@]}"; do
  if jj $cmd --help &>/dev/null; then
    pass "jj $cmd exists"
  else
    fail "jj $cmd not found"
  fi
done

fi  # end jj installed check

# ---------- Guard script ----------
section "jj-guard.sh functional tests"

guard="claude-code/scripts/jj-guard.sh"

# Create a temp directory with .jj to simulate a jj repo
guard_tmpdir=$(mktemp -d)
mkdir -p "$guard_tmpdir/.jj"

# Should BLOCK (run from inside the temp jj repo)
block_commands=("git status" "git commit -m test" "git push" "git checkout -b feat" "git add ." "git stash" "git rebase main" "git reset --hard" "git merge feat" "git branch -d old")
for cmd in "${block_commands[@]}"; do
  if (cd "$guard_tmpdir" && bash "$OLDPWD/$guard" "$cmd") &>/dev/null; then
    fail "should block: $cmd"
  else
    pass "blocks: $cmd"
  fi
done

# Should ALLOW
allow_commands=("jj st" "jj commit -m test" "jj git push" "ls -la" "echo hello" "" ":;git status")
for cmd in "${allow_commands[@]}"; do
  if (cd "$guard_tmpdir" && bash "$OLDPWD/$guard" "$cmd") &>/dev/null; then
    pass "allows: ${cmd:-<empty>}"
  else
    fail "should allow: ${cmd:-<empty>}"
  fi
done

# Hook JSON mode (shared by Claude Code and Codex)
guard_output=$(echo '{"tool_input":{"command":"git diff"},"cwd":"'"$guard_tmpdir"'"}' | bash "$guard")
if jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<< "$guard_output" &>/dev/null; then
  pass "JSON mode blocks git diff"
else
  fail "JSON mode should block git diff"
fi

if echo '{"tool_input":{"command":"jj diff"},"cwd":"'"$guard_tmpdir"'"}' | bash "$guard" &>/dev/null; then
  pass "JSON mode allows jj diff"
else
  fail "JSON mode should allow jj diff"
fi

if echo '{"tool_input":{"command":":;git fetch"},"cwd":"'"$guard_tmpdir"'"}' | bash "$guard" &>/dev/null; then
  pass "JSON mode allows :;git escape hatch"
else
  fail "JSON mode should allow :;git escape hatch"
fi

compound_output=$(echo '{"tool_input":{"command":"cd src && git status"},"cwd":"'"$guard_tmpdir"'"}' | bash "$guard")
if jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<< "$compound_output" &>/dev/null; then
  pass "JSON mode blocks git in a compound shell command"
else
  fail "JSON mode should block git in a compound shell command"
fi

session_output=$(echo '{"hook_event_name":"SessionStart","cwd":"'"$guard_tmpdir"'"}' | bash "$guard")
if jq -e '.hookSpecificOutput.additionalContext | contains("This is a jj repository")' <<< "$session_output" &>/dev/null; then
  pass "SessionStart adds minimal context in a jj repository"
else
  fail "SessionStart should add jj context"
fi

# Edge cases
if (cd "$guard_tmpdir" && bash "$OLDPWD/$guard" "github-cli login") &>/dev/null; then
  pass "allows github-cli (not git)"
else
  fail "should allow github-cli"
fi

if (cd "$guard_tmpdir" && bash "$OLDPWD/$guard" "gitk") &>/dev/null; then
  pass "allows gitk (not 'git ')"
else
  fail "should allow gitk"
fi

# Should ALLOW git in non-jj directories
non_jj_tmpdir=$(mktemp -d)
if (cd "$non_jj_tmpdir" && bash "$OLDPWD/$guard" "git status") &>/dev/null; then
  pass "allows git in non-jj directory"
else
  fail "should allow git in non-jj directory"
fi

non_jj_session=$(echo '{"hook_event_name":"SessionStart","cwd":"'"$non_jj_tmpdir"'"}' | bash "$guard")
if [[ -z "$non_jj_session" ]]; then
  pass "SessionStart adds no context outside jj repositories"
else
  fail "SessionStart should be silent outside jj repositories"
fi

rm -rf "$guard_tmpdir" "$non_jj_tmpdir"

# ---------- Worktree hook validation ----------
section "Worktree hook input validation"

create_hook="claude-code/scripts/worktree-create.sh"
remove_hook="claude-code/scripts/worktree-remove.sh"
hook_tmpdir=$(mktemp -d)
mkdir -p "$hook_tmpdir/.jj" "$hook_tmpdir/.worktrees"
touch "$hook_tmpdir/.worktrees/keep"

invalid_worktree_payloads=(
  '{"cwd":"'"$hook_tmpdir"'"}'
  '{"name":"","cwd":"'"$hook_tmpdir"'"}'
  '{"name":"../escape","cwd":"'"$hook_tmpdir"'"}'
  '{"name":"feature/test","cwd":"'"$hook_tmpdir"'"}'
  '{"name":"safe-name","cwd":"relative/path"}'
  '{"name":"safe-name","cwd":"'"$hook_tmpdir"'/missing"}'
)

for payload in "${invalid_worktree_payloads[@]}"; do
  if echo "$payload" | bash "$create_hook" &>/dev/null; then
    fail "worktree-create should reject payload: $payload"
  else
    pass "worktree-create rejects payload: $payload"
  fi

  if echo "$payload" | bash "$remove_hook" &>/dev/null; then
    fail "worktree-remove should reject payload: $payload"
  else
    pass "worktree-remove rejects payload: $payload"
  fi
done

if [[ -f "$hook_tmpdir/.worktrees/keep" ]]; then
  pass "worktree-remove leaves .worktrees untouched after invalid payloads"
else
  fail "worktree-remove modified .worktrees on invalid payload"
fi

rm -rf "$hook_tmpdir"

# ---------- Real jj workspace lifecycle ----------
section "Real jj workspace lifecycle"

if command -v jj &>/dev/null; then
  workspace_repo=$(mktemp -d)
  jj git init --colocate "$workspace_repo" &>/dev/null
  workspace_path=$(printf '{"name":"agent-test","cwd":"%s"}\n' "$workspace_repo" | bash "$create_hook")

  if [[ "$workspace_path" == "$workspace_repo/.worktrees/agent-test" ]] &&
     [[ -d "$workspace_path" ]] && [[ -e "$workspace_path/.jj" ]]; then
    pass "WorktreeCreate creates a real jj workspace"
  else
    fail "WorktreeCreate did not create the expected jj workspace"
  fi

  if [[ -f "$workspace_path/.envrc" ]] && grep -q 'GIT_DIR=' "$workspace_path/.envrc"; then
    pass "WorktreeCreate wires Git metadata for compatible tools"
  else
    fail "WorktreeCreate did not write Git metadata wiring"
  fi

  printf '{"name":"agent-test","cwd":"%s"}\n' "$workspace_repo" | bash "$remove_hook"
  if [[ ! -e "$workspace_path" ]] && ! jj -R "$workspace_repo" workspace list | grep -q 'agent-test'; then
    pass "WorktreeRemove forgets and removes the jj workspace"
  else
    fail "WorktreeRemove left workspace state behind"
  fi
  rm -rf "$workspace_repo"
else
  warn "jj not installed — skipping real workspace lifecycle"
fi

# ---------- Codex strict rule evaluation ----------
section "Codex strict rule evaluation"

if command -v codex &>/dev/null; then
  strict_decision=$(codex execpolicy check --rules codex/rules/jj-skipper-strict.rules -- git status | jq -r '.decision')
  jj_decision=$(codex execpolicy check --rules codex/rules/jj-skipper-strict.rules -- jj st | jq -r '.decision')
  if [[ "$strict_decision" == "forbidden" && "$jj_decision" != "forbidden" ]]; then
    pass "optional strict rule blocks git without blocking jj"
  else
    fail "optional strict rule decisions are incorrect"
  fi
else
  warn "codex not installed — skipping execpolicy evaluation"
fi


# ---------- Codex install.sh dry run ----------
section "Codex install.sh (dry run in temp dir)"

tmpdir=$(mktemp -d)
trap "rm -rf '$tmpdir'" EXIT

mkdir -p "$tmpdir/codex"
printf '%s\n' '{"hooks":{"PostToolUse":[{"matcher":"^Bash$","hooks":[{"type":"command","command":"echo existing"}]}]}}' > "$tmpdir/codex/hooks.json"
printf '%s\n' 'Keep this user instruction.' '<!-- jj-skipper -->' 'Legacy eager context.' '<!-- jj-skipper -->' > "$tmpdir/codex/AGENTS.md"

if CODEX_HOME="$tmpdir/codex" AGENTS_HOME="$tmpdir/agents" bash codex/install.sh &>/dev/null; then
  pass "install.sh runs without error"
else
  fail "install.sh failed"
fi

if [[ -d "$tmpdir/agents/skills/jj-guide" ]]; then
  pass "skill installed to \$AGENTS_HOME/skills/jj-guide"
else
  fail "skill not found in \$AGENTS_HOME/skills/"
fi

if [[ -f "$tmpdir/agents/skills/jj-guide/SKILL.md" ]]; then
  pass "SKILL.md accessible through installed skill"
else
  fail "SKILL.md not accessible through installed skill"
fi

if [[ -d "$tmpdir/agents/skills/jj-commit-push-pr" ]] || [[ -d "$tmpdir/agents/skills/jj-workspace" ]]; then
  pass "additional skills installed to \$AGENTS_HOME/skills/"
else
  fail "additional skills not found in \$AGENTS_HOME/skills/"
fi

if jq -e '.hooks.PreToolUse[] | .hooks[] | select(.command | endswith("/jj-skipper/jj-guard.sh"))' \
  "$tmpdir/codex/hooks.json" &>/dev/null; then
  pass "repo-aware guard installed to \$CODEX_HOME/hooks.json"
else
  fail "repo-aware guard not found in \$CODEX_HOME/hooks.json"
fi

if jq -e '.hooks.SessionStart[] | .hooks[] | select(.command | endswith("/jj-skipper/jj-guard.sh"))' \
  "$tmpdir/codex/hooks.json" &>/dev/null; then
  pass "conditional startup context installed to \$CODEX_HOME/hooks.json"
else
  fail "conditional startup context not found in \$CODEX_HOME/hooks.json"
fi

if jq -e '.hooks.PostToolUse[] | .hooks[] | select(.command == "echo existing")' \
  "$tmpdir/codex/hooks.json" &>/dev/null; then
  pass "installer preserves unrelated existing hooks"
else
  fail "installer clobbered an unrelated existing hook"
fi

if [[ ! -e "$tmpdir/codex/rules/jj-skipper.rules" ]]; then
  pass "unsafe global Git rule is not installed by default"
else
  fail "legacy global Git rule should not be installed"
fi

if grep -q "Keep this user instruction" "$tmpdir/codex/AGENTS.md" &&
   ! grep -q "jj-skipper" "$tmpdir/codex/AGENTS.md"; then
  pass "installer removes legacy eager context and preserves user AGENTS.md content"
else
  fail "installer did not safely remove the legacy jj-skipper AGENTS.md block"
fi

# ---------- Content checks ----------
section "Content safety checks"

if grep -rq "backout" shared/ claude-code/ codex/ 2>/dev/null; then
  fail "deprecated 'jj backout' still referenced"
else
  pass "no deprecated 'jj backout' references"
fi

if grep -rq "openai\.yaml" shared/ claude-code/ codex/ 2>/dev/null; then
  fail "dead 'openai.yaml' still referenced"
else
  pass "no dead 'openai.yaml' references"
fi

if grep -rq "openai\\.yaml" claude-code/ 2>/dev/null; then
  fail "dead openai.yaml references in claude-code/"
else
  pass "no dead openai.yaml references in claude-code/"
fi

# ---------- Summary ----------
echo ""
echo "==============================="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo "==============================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
