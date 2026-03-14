# Changelog

## 0.5.0 — 2026-03-14

- **Added**: `agent-status.sh` script for multi-agent workspace/bookmark discovery and file conflict pre-check
- **Added**: `jj-status` skill — agents can check what other agents are working on and detect file overlaps before pushing
- **Added**: Pre-push conflict check step in `commit-push-pr` skill
- **Added**: Multi-agent coordination section in Codex `AGENTS.md` and `AGENTS.template.md`
- **Fixed**: Test suite — removed stale `file-lock.sh` references (removed in v0.4.1), fixed symlink expectations for `jj-` prefixed skill names, fixed guard tests to work without `.jj/` directory, graceful skip when `jj` is not installed
- **Fixed**: README — updated repo structure to reflect current state (removed `file-lock.sh`, added all skills, correct skill naming)

## 0.4.2 — 2026-03-11

- **Cleanup**: Renamed codex skills with `jj-` prefix for consistency, removed broken `develop` symlink, deleted PLAN.md

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
