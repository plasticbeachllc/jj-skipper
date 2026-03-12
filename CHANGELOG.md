# Changelog

## 0.4.1 — 2026-03-11

- **Removed**: File-lock mechanism and parallel-agent guard — isolated workspaces make file-level locking unnecessary

## 0.4.0 — 2026-03-11

- **Renamed**: `jj-develop` skill → `jj-workspace`, inlined workspace creation (no external script dependency)
- **Fixed**: Plugin cache compatibility — skills use real copies instead of symlinks
- **Added**: `jj-guide` cross-references to workspace and commit-push-pr skills

## 0.1.0 — 2026-03-10

Initial release.

- **Shared**: jj-guard.sh (git command interceptor), cleanup-workspace.sh, jj-guide skill with full command reference
- **Claude Code**: Plugin with PreToolUse guard hook, WorktreeCreate/Remove bridge to jj workspaces, jj-doctor sub-agent
- **Codex**: execpolicy rule blocking git commands, install.sh for skill/rule vendoring, AGENTS.md instructions
