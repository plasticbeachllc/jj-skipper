#!/usr/bin/env bash
# Copy canonical shared assets into adapters that cannot safely use symlinks.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)

mkdir -p "$ROOT/claude-code/skills" "$ROOT/codex/skills" "$ROOT/codex/scripts"

for skill_dir in "$ROOT/shared/skills"/*; do
  skill_name=$(basename "$skill_dir")
  for adapter in claude-code codex; do
    target="$ROOT/$adapter/skills/$skill_name"
    rm -rf "$target"
    mkdir -p "$target"
    cp -R "$skill_dir/". "$target/"
  done
done

cp "$ROOT/shared/scripts/jj-guard.sh" "$ROOT/claude-code/scripts/jj-guard.sh"
cp "$ROOT/shared/scripts/jj-guard.sh" "$ROOT/codex/scripts/jj-guard.sh"
chmod +x "$ROOT/claude-code/scripts/jj-guard.sh" "$ROOT/codex/scripts/jj-guard.sh"

echo "Synchronized shared skills and guard logic into platform adapters."
