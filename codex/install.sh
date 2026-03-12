#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME/skills"
RULES_DIR="$CODEX_HOME/rules"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_SKILLS="$SCRIPT_DIR/../shared/skills"
RULES_SRC="$SCRIPT_DIR/rules/jj-skipper.rules"
AGENTS_MD="$CODEX_HOME/AGENTS.md"

# --- Install skills ---
mkdir -p "$SKILLS_DIR"

for skill_dir in "$SHARED_SKILLS"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$skill_name"
  [ -e "$target" ] || [ -L "$target" ] && rm -rf "$target"
  if ln -s "$(cd "$skill_dir" && pwd)" "$target" 2>/dev/null; then
    echo "Linked skill $skill_name → $target"
  else
    cp -r "$skill_dir" "$target"
    echo "Copied skill $skill_name → $target"
  fi
done

# --- Install execpolicy rules ---
mkdir -p "$RULES_DIR"
cp "$RULES_SRC" "$RULES_DIR/jj-skipper.rules"
echo "Installed execpolicy rules → $RULES_DIR/jj-skipper.rules"

# --- Append jj workflow instructions to AGENTS.md (idempotent) ---
MARKER="<!-- jj-skipper -->"
JJ_BLOCK="$MARKER
## jj (Jujutsu) — Version Control

Use jj exclusively. Repos are colocated (.jj/ and .git/ both exist). All VCS writes use jj.

**One bookmark per feature.** Before work:
\`\`\`bash
jj new main -m \"feat: description\"
jj bookmark create <feature-name> -r @
\`\`\`

After \`jj commit\`, content is at \`@-\`. Bookmark tracks the change ID automatically.

To push: \`jj git push -b <feature-name>\`

To sync after PR merge:
\`\`\`bash
jj git fetch
jj bookmark set main -r main@origin
\`\`\`

Use the jj-guide skill for full reference. Use the commit-push-pr skill to ship code.
$MARKER"

if [ -f "$AGENTS_MD" ] && grep -q "$MARKER" "$AGENTS_MD"; then
  # Replace existing block between markers using sed
  # Write new block to temp file, then splice it in
  block_file=$(mktemp)
  echo "$JJ_BLOCK" > "$block_file"
  # Remove old block (first marker through second marker), then append new block
  sed "/$MARKER/,/$MARKER/d" "$AGENTS_MD" > "$AGENTS_MD.tmp"
  cat "$block_file" >> "$AGENTS_MD.tmp"
  mv "$AGENTS_MD.tmp" "$AGENTS_MD"
  rm -f "$block_file"
  echo "Updated jj-skipper block in $AGENTS_MD"
else
  # Append (preserve existing content)
  [ -f "$AGENTS_MD" ] && echo "" >> "$AGENTS_MD"
  echo "$JJ_BLOCK" >> "$AGENTS_MD"
  echo "Appended jj-skipper instructions to $AGENTS_MD"
fi

# --- Summary ---
echo ""
echo "jj-skipper installed for Codex."
echo ""
echo "  Skills: $SKILLS_DIR/{jj-guide,jj-commit-push-pr,jj-workspace}"
echo "  Rules:  $RULES_DIR/jj-skipper.rules (blocks all 'git' commands)"
echo "  Agent:  $AGENTS_MD (jj workflow instructions)"
echo ""
echo "  WARNING: The execpolicy rule blocks 'git' commands GLOBALLY."
echo "  For repos still using plain git, remove or disable the rule:"
echo "    rm $RULES_DIR/jj-skipper.rules"
echo ""
echo "Restart Codex to pick up changes."
