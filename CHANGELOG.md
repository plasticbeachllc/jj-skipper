# Changelog

## Unreleased

## 0.7.1 — 2026-07-17

- **Changed**: Folded the Claude-only `jj-doctor` agent into `jj-guide` as a shared, evidence-first diagnosis and recovery workflow

## 0.7.0 — 2026-07-17

- **Fixed**: Claude `WorktreeRemove` now consumes the documented `worktree_path` payload and validates it against the jj workspace registry
- **Fixed**: Workspace creation no longer overwrites tracked `.envrc` files or exposes the main Git index through an alternate work tree
- **Changed**: `jj-workspace` and Claude lifecycle hooks now share one deterministic manager with base selection, atomic bookmark creation, rollback, and recovery bookmarks

## 0.6.0 — 2026-07-13

- **Changed**: Reduced eager jj guidance to a small conditional `SessionStart` payload in jj repositories
- **Changed**: The standalone Codex installer removes its legacy global `AGENTS.md` block instead of duplicating startup context
- **Changed**: Converted `jj-guide` into a compact router with detailed workflows, revsets, and recovery loaded on demand
- **Changed**: Tightened skill trigger boundaries and added context-size regression budgets
- **Changed**: Reworked user and maintainer documentation for concise installation, usage, architecture, and context guidance
- **Fixed**: Documented the complete Claude Code marketplace installation flow and current jj bookmark/rebase syntax

## 0.5.0 — 2026-07-13

- **Added**: Native Codex plugin manifest, marketplace entry, and bundled `PreToolUse` hook
- **Changed**: Codex user skills now install to the current `~/.agents/skills` discovery path
- **Changed**: Bare Git enforcement is repo-aware on both Claude Code and Codex; the global Codex rule is now explicit strict-mode opt-in
- **Added**: Canonical shared guard logic and `scripts/sync-adapters.sh` to prevent platform-copy drift
- **Added**: Behavioral tests for compound commands, Codex hook output, real jj workspace lifecycle, plugin contracts, adapter synchronization, and execpolicy decisions
- **Fixed**: Claude worktree hooks now validate hook payloads before creating or deleting workspace paths, rejecting empty names, path traversal, and non-jj roots
- **Added**: Regression tests covering invalid `WorktreeCreate` and `WorktreeRemove` payloads
- **Changed**: `jj-commit-push-pr` now documents a lightweight `.git` write preflight so Codex sessions fail fast when VCS writes are sandboxed

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
