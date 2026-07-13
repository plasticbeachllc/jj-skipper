#!/usr/bin/env bash
# Legacy standalone installer. Prefer the native Codex plugin for new installs.
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
SKILLS_DIR="$AGENTS_HOME/skills"
HOOKS_FILE="$CODEX_HOME/hooks.json"
INSTALL_DIR="$CODEX_HOME/jj-skipper"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_SKILLS="$SCRIPT_DIR/../shared/skills"
AGENTS_MD="$CODEX_HOME/AGENTS.md"

mkdir -p "$SKILLS_DIR" "$INSTALL_DIR"

for skill_dir in "$SHARED_SKILLS"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$skill_name"
  if [[ -e "$target" || -L "$target" ]]; then
    rm -rf "$target"
  fi
  if ln -s "$(cd "$skill_dir" && pwd)" "$target" 2>/dev/null; then
    echo "Linked skill $skill_name → $target"
  else
    cp -R "$skill_dir" "$target"
    echo "Copied skill $skill_name → $target"
  fi
done

cp "$SCRIPT_DIR/scripts/jj-guard.sh" "$INSTALL_DIR/jj-guard.sh"
chmod +x "$INSTALL_DIR/jj-guard.sh"

hook_command="bash $INSTALL_DIR/jj-guard.sh"
new_hook=$(jq -cn --arg command "$hook_command" '{
  matcher: "^Bash$",
  hooks: [{
    type: "command",
    command: $command,
    timeout: 10,
    statusMessage: "Checking jj repository policy"
  }]
}')

if [[ -f "$HOOKS_FILE" ]]; then
  jq --argjson hook "$new_hook" '
    .hooks = (.hooks // {}) |
    .hooks.PreToolUse = ((.hooks.PreToolUse // []) |
      map(select(any(.hooks[]?; ((.command? // "") | endswith("/jj-skipper/jj-guard.sh"))) | not)) + [$hook])
  ' "$HOOKS_FILE" > "$HOOKS_FILE.tmp"
else
  jq -n --argjson hook "$new_hook" '{hooks: {PreToolUse: [$hook]}}' > "$HOOKS_FILE.tmp"
fi
mv "$HOOKS_FILE.tmp" "$HOOKS_FILE"
echo "Installed repo-aware hook → $HOOKS_FILE"

# Remove the unsafe global rule installed by jj-skipper versions before 0.5.
legacy_rule="$CODEX_HOME/rules/jj-skipper.rules"
if [[ -f "$legacy_rule" ]] && grep -q "jj-skipper" "$legacy_rule"; then
  rm -f "$legacy_rule"
  echo "Removed legacy global Git rule → $legacy_rule"
fi

MARKER="<!-- jj-skipper -->"
TEMPLATE="$SCRIPT_DIR/../AGENTS.template.md"
JJ_BLOCK="$(printf '%s\n%s\n%s' "$MARKER" "$(cat "$TEMPLATE")" "$MARKER")"

mkdir -p "$CODEX_HOME"
if [[ -f "$AGENTS_MD" ]] && grep -q "$MARKER" "$AGENTS_MD"; then
  sed "/$MARKER/,/$MARKER/d" "$AGENTS_MD" > "$AGENTS_MD.tmp"
  printf '%s\n' "$JJ_BLOCK" >> "$AGENTS_MD.tmp"
  mv "$AGENTS_MD.tmp" "$AGENTS_MD"
  echo "Updated jj-skipper block in $AGENTS_MD"
else
  [[ -f "$AGENTS_MD" ]] && printf '\n' >> "$AGENTS_MD"
  printf '%s\n' "$JJ_BLOCK" >> "$AGENTS_MD"
  echo "Appended jj-skipper instructions to $AGENTS_MD"
fi

echo ""
echo "jj-skipper installed for Codex."
echo "  Skills: $SKILLS_DIR/{jj-guide,jj-commit-push-pr,jj-workspace}"
echo "  Hook:   $HOOKS_FILE (blocks bare git only inside jj repositories)"
echo "  Agent:  $AGENTS_MD"
echo ""
echo "Restart Codex, then review and trust the hook with /hooks."
