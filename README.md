# jj-skipper

**Makes [jj (Jujutsu)](https://martinvonz.github.io/jj/) the native VCS for AI coding agents.**

jj-skipper provides a single source of truth for jj knowledge, guard logic, and workflow automation that works with both Claude Code and OpenAI Codex — without duplicating content or maintaining parallel configurations.

The name "skipper" represents how the agent steers the repo through tumultuous waters using jj. It also harkens to jj's ability to "skip" unbookmarked changes in the git commit history.

## How It Works

Repos use **colocated mode** (`jj git init --colocate`) so both `.jj/` and `.git/` exist. This preserves compatibility with tools that expect `.git/` (Codex worktrees, VSCode, `gh` CLI). Agents use jj for all writes; git reads work naturally.

### Guard Layer
- **Claude Code**: PreToolUse hook intercepts Bash commands and blocks `git` before execution, suggesting the jj equivalent.
- **Codex**: `execpolicy` rule with `decision = "forbidden"` blocks all `git` commands.
- **Escape hatch**: Prefix with `:;git` for git-only operations (submodule, lfs).

### Knowledge Layer
- **jj-guide skill**: Loaded automatically for any VCS operation. Covers mental model, workflows, bookmark rules, revsets, filesets, and common pitfalls.
- **git-to-jj reference**: Complete command mapping from git to jj equivalents.

### Automation Layer (Claude Code)
- **WorktreeCreate hook**: Bridges `jj workspace add` + `.envrc` for `$GIT_DIR`, so `gh` CLI works in secondary workspaces.
- **`/jj-workspace`**: Create an isolated workspace and bookmark for parallel agent work.
- **`/commit-push-pr`**: Commit, push bookmark, and open a PR on GitHub.
- **jj-doctor**: Sub-agent for debugging lost commits, stale bookmarks, conflicts, and other VCS tangles.

### Prerequisites
- `jj`, `jq` (required)
- `direnv` (recommended — enables automatic `$GIT_DIR` in worktrees; fallback: `source .envrc`)

## Installation

### Claude Code (plugin)

```bash
# From marketplace (when published):
/plugin marketplace add plasticbeachllc/jj-skipper

# Or local install for development:
/plugin install /path/to/jj-skipper/claude-code
```

### Codex

```bash
git clone https://github.com/plasticbeachllc/jj-skipper.git
./jj-skipper/codex/install.sh
```

> **Warning**: The Codex execpolicy rule blocks `git` commands **globally** across all sessions. For repos still using plain git, remove the rule: `rm ~/.codex/rules/jj-skipper.rules`

### Per-project instructions

Add to your project's `CLAUDE.md` or `AGENTS.md`:

```markdown
## Version Control

This project uses jj (Jujutsu) exclusively. The repo is colocated (.jj/ and .git/ both
exist). All VCS writes use jj. Git reads work naturally.

**Multi-agent model: one bookmark per agent/feature.**

Before doing any work, create a bookmark:
  jj new main -m "feat: description"
  jj bookmark create <feature-name> -r @

After committing, the content is at @- (parent). @ is always an empty working copy.

To push:
  jj git push -b <feature-name>

To sync after a PR merges on GitHub:
  jj git fetch
  jj bookmark set main -r main@origin

Claude Code handles workspace creation automatically via the WorktreeCreate hook.
If gh CLI doesn't work in a worktree, run `direnv allow` or `source .envrc`.

Use the jj-guide skill for full reference. Use /commit-push-pr to ship code.
If VCS state gets tangled, invoke jj-doctor.
```

## Repository Structure

```
jj-skipper/
├── shared/                          # Platform-agnostic content
│   ├── skills/
│   │   ├── jj-guide/              # Core jj knowledge (both platforms)
│   │   │   ├── SKILL.md
│   │   │   └── references/git-to-jj.md
│   │   ├── commit-push-pr/        # Ship code skill
│   │   │   └── SKILL.md
│   │   └── jj-workspace/          # Workspace creation skill
│   │       └── SKILL.md
│   └── scripts/
│       ├── jj-guard.sh             # Git command interceptor
│       ├── workspace-create.sh     # Isolated workspace setup
│       └── cleanup-workspace.sh    # Workspace cleanup helper
│
├── claude-code/                     # Claude Code adapter
│   ├── .claude-plugin/plugin.json
│   ├── hooks/hooks.json            # PreToolUse + Worktree hooks
│   ├── scripts/                    # Worktree bridge scripts
│   ├── skills/                     # Real directories (plugin cache compatible)
│   │   ├── jj-guide/
│   │   ├── jj-commit-push-pr/
│   │   └── jj-workspace/
│   └── agents/jj-doctor.md        # VCS debugger sub-agent
│
├── codex/                           # Codex adapter
│   ├── skills/                     # Symlinks → ../../shared/skills/*
│   │   ├── jj-guide
│   │   ├── jj-commit-push-pr
│   │   └── jj-workspace
│   ├── rules/jj-skipper.rules     # execpolicy guard
│   ├── agents/AGENTS.md
│   └── install.sh
│
├── LICENSE.md
├── README.md
└── CHANGELOG.md
```

Symlinks keep it DRY — shared content is edited once, used by both adapters. Claude Code uses real directory copies for plugin cache compatibility. Codex `install.sh` falls back to file copy if symlinks aren't supported.

## Multi-Agent Parallel Workflows

Multiple agents can work on the same repo simultaneously. Each agent gets filesystem isolation via jj workspaces and VCS isolation via bookmarks.

### How it works

```
Agent A: .worktrees/feature-auth/  → bookmark: feature-auth
Agent B: .worktrees/feature-ui/    → bookmark: feature-ui
Agent C: .worktrees/feature-docs/  → bookmark: feature-docs
```

- **Filesystem isolation**: Each agent works in a separate directory under `.worktrees/`
- **VCS isolation**: Each agent's bookmark tracks an independent change ID
- **No file contention**: Different directories = no race conditions on file writes
- **Independent push**: Each bookmark pushes independently to its own remote branch

### After a PR merges

All agents should sync:
```bash
jj git fetch
jj bookmark set main -r main@origin
jj rebase -d main@origin   # rebase agent's local commits onto updated main
```

## Design Principles

1. **Single source of truth.** One repo. Shared skills, scripts, and reference docs. Platform adapters are thin wiring.
2. **Guard, don't just guide.** Programmatic enforcement (hooks, execpolicy) blocks git before execution.
3. **Colocated mode.** Both `.jj/` and `.git/` exist. Agents use jj for writes; git reads work naturally.
4. **Non-interactive by default.** Every command path works headlessly with `-m`, filesets, and explicit flags.

## Quick jj Reference

| Instead of | Use |
|------------|-----|
| `git status` | `jj st` |
| `git add . && git commit -m "msg"` | `jj commit -m "msg"` |
| `git push` | `jj git push` |
| `git pull` | `jj git fetch && jj bookmark set main -r main@origin` |
| `git pull --rebase` | `jj git fetch && jj rebase -d main@origin` |
| `git checkout -b feat` | `jj new main -m "feat: desc"` |
| `git stash` | `jj new` |
| `git log` | `jj log` |
| Undo anything | `jj undo` |

See [`shared/skills/jj-guide/SKILL.md`](shared/skills/jj-guide/SKILL.md) for the full reference.

## Acknowledgments

Inspired by [kawaz/claude-plugin-jj](https://github.com/kawaz/claude-plugin-jj), [kalupa/jj-workflow](https://github.com/kalupa/jj-workflow), [danverbraganza/jujutsu-skill](https://github.com/danverbraganza/jujutsu-skill), and [alexlwn123/jj-claude-code-plugin](https://github.com/alexlwn123/jj-claude-code-plugin). See [LICENSE.md](LICENSE.md) for details.

## License

[MIT](LICENSE.md)
