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
  shared/skills/jj-commit-push-pr/SKILL.md
  shared/skills/jj-workspace/SKILL.md
  claude-code/.claude-plugin/plugin.json
  claude-code/hooks/hooks.json
  claude-code/scripts/worktree-create.sh
  claude-code/scripts/worktree-remove.sh
  claude-code/agents/jj-doctor.md
  codex/rules/jj-skipper.rules
  codex/install.sh
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

# ---------- Symlinks ----------
section "Symlinks"

expected_links=(
  "codex/skills/jj-guide"
  "codex/skills/jj-commit-push-pr"
  "codex/skills/jj-workspace"
)

# Claude Code skills should be real directories (not symlinks) for plugin cache compatibility
cc_skill_dirs=(
  "claude-code/skills/jj-guide"
  "claude-code/skills/jj-commit-push-pr"
  "claude-code/skills/jj-workspace"
)
for d in "${cc_skill_dirs[@]}"; do
  if [[ -d "$d" ]] && [[ ! -L "$d" ]]; then
    pass "$d is a real directory (plugin cache compatible)"
  elif [[ -L "$d" ]]; then
    warn "$d is a symlink (may not survive plugin cache copy)"
  else
    fail "$d missing"
  fi
done

for link in "${expected_links[@]}"; do
  if [[ -L "$link" ]]; then
    target=$(readlink "$link")
    if [[ -e "$link" ]]; then
      pass "$link -> $target (resolves)"
    else
      fail "$link -> $target (broken symlink)"
    fi
  else
    fail "$link is not a symlink"
  fi
done

# ---------- Executables ----------
section "Executable bits"

executables=(
  claude-code/scripts/jj-guard.sh
  claude-code/scripts/worktree-create.sh
  claude-code/scripts/worktree-remove.sh
  codex/install.sh
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
  codex/install.sh
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
)

for j in "${json_files[@]}"; do
  if jq empty "$j" 2>/dev/null; then
    pass "$j is valid JSON"
  else
    fail "$j is invalid JSON"
  fi
done

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

# CC hook JSON mode
if echo '{"tool_input":{"command":"git diff"}}' | (cd "$guard_tmpdir" && bash "$OLDPWD/$guard") &>/dev/null; then
  fail "JSON mode should block git diff"
else
  pass "JSON mode blocks git diff"
fi

if echo '{"tool_input":{"command":"jj diff"}}' | (cd "$guard_tmpdir" && bash "$OLDPWD/$guard") &>/dev/null; then
  pass "JSON mode allows jj diff"
else
  fail "JSON mode should allow jj diff"
fi

if echo '{"tool_input":{"command":":;git fetch"}}' | (cd "$guard_tmpdir" && bash "$OLDPWD/$guard") &>/dev/null; then
  pass "JSON mode allows :;git escape hatch"
else
  fail "JSON mode should allow :;git escape hatch"
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

rm -rf "$guard_tmpdir" "$non_jj_tmpdir"


# ---------- Codex install.sh dry run ----------
section "Codex install.sh (dry run in temp dir)"

tmpdir=$(mktemp -d)
trap "rm -rf '$tmpdir'" EXIT

if CODEX_HOME="$tmpdir/codex" bash codex/install.sh &>/dev/null; then
  pass "install.sh runs without error"
else
  fail "install.sh failed"
fi

if [[ -d "$tmpdir/codex/skills/jj-guide" ]]; then
  pass "skill installed to \$CODEX_HOME/skills/jj-guide"
else
  fail "skill not found in \$CODEX_HOME/skills/"
fi

if [[ -f "$tmpdir/codex/skills/jj-guide/SKILL.md" ]]; then
  pass "SKILL.md accessible through installed skill"
else
  fail "SKILL.md not accessible through installed skill"
fi

if [[ -d "$tmpdir/codex/skills/jj-commit-push-pr" ]] || [[ -d "$tmpdir/codex/skills/jj-workspace" ]]; then
  pass "additional skills installed to \$CODEX_HOME/skills/"
else
  fail "additional skills not found in \$CODEX_HOME/skills/"
fi

if [[ -f "$tmpdir/codex/rules/jj-skipper.rules" ]]; then
  pass "rules installed to \$CODEX_HOME/rules/jj-skipper.rules"
else
  fail "rules not found in \$CODEX_HOME/rules/"
fi

if [[ -f "$tmpdir/codex/AGENTS.md" ]] && grep -q "jj-skipper" "$tmpdir/codex/AGENTS.md"; then
  pass "jj-skipper block appended to \$CODEX_HOME/AGENTS.md"
else
  fail "jj-skipper block not found in \$CODEX_HOME/AGENTS.md"
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
