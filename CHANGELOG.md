# Changelog

## 0.4.3 — 2026-03-14

- **Added**: Multi-agent coordination section in Codex `AGENTS.md` (sync workflow, workspace naming)
- **Added**: Multi-agent parallel workflows section in README
- **Fixed**: Test suite — removed stale `file-lock.sh` references (removed in v0.4.1), fixed symlink expectations for `jj-` prefixed skill names, fixed guard tests to work without `.jj/` directory, graceful skip when `jj` is not installed
- **Fixed**: README repo structure — reflects current state (no `file-lock.sh`, all skills listed, correct naming)
- **Fixed**: Inlined all `claude-code/scripts/` (jj-guard, worktree-create, worktree-remove) — no more cross-directory symlinks that break in plugin cache
- **Removed**: `shared/scripts/` directory — all scripts now live directly in their platform adapter

## 0.4.2 — 2026-03-11

- **Cleanup**: Renamed codex skills with `jj-` prefix for consistency, removed broken `develop` symlink, deleted PLAN.md

## 0.4.1 — 2026-03-11

- **Removed**: File-lock mechanism and parallel-agent guard — isolated workspaces make file-level locking unnecessary

## 0.4.0 — 2026-03-11

- **Renamed**: `jj-develop` skill → `jj-workspace`, inlined workspace creation (no external script dependency)
- **Fixed**: Plugin cache compatibility — skills use real copies instead of symlinks
- **Added**: `jj-guide` cross-references to workspace and jj-commit-push-pr skills

## 0.1.0 — 2026-03-10

Initial release.

- **Shared**: jj-guard.sh (git command interceptor), cleanup-workspace.sh, jj-guide skill with full command reference
- **Claude Code**: Plugin with PreToolUse guard hook, WorktreeCreate/Remove bridge to jj workspaces, jj-doctor sub-agent
- **Codex**: execpolicy rule blocking git commands, install.sh for skill/rule vendoring, AGENTS.md instructions
