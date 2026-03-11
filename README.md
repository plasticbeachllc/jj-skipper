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
- **WorktreeCreate/Remove hooks**: Bridge Claude Code worktrees to `jj workspace` (shared commit graph, isolated working copy).
- **`/jj-commit`**: Focused commits with selective file grouping and push reminders.
- **`/develop`**: Enter an isolated jj workspace for parallel work.
- **jj-doctor**: Sub-agent for debugging lost commits, stale bookmarks, conflicts, and other VCS tangles.

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

This project uses jj (Jujutsu) exclusively for version control. The repo is colocated
(both .jj/ and .git/ exist) but all VCS operations MUST use jj commands, never git.

Use the jj-guide skill for command reference. If VCS state gets tangled, invoke jj-doctor.

Key rules:
- Never run git commands directly (use jj equivalents)
- After `jj commit`, the commit with content is @- (parent), not @ (empty working copy)
- Use `jj git push -c @-` for auto-bookmark PR branches
- Use `jj bookmark set <name> -r @-` then `jj git push -b <name>` for named branches
```

## Repository Structure

```
jj-skipper/
├── shared/                          # Platform-agnostic content
│   ├── skills/jj-guide/            # Core jj knowledge (both platforms)
│   │   ├── SKILL.md
│   │   └── references/git-to-jj.md
│   └── scripts/
│       ├── jj-guard.sh             # Git command interceptor
│       └── cleanup-workspace.sh    # Workspace cleanup helper
│
├── claude-code/                     # Claude Code adapter
│   ├── .claude-plugin/plugin.json
│   ├── hooks/hooks.json            # PreToolUse + Worktree hooks
│   ├── scripts/                    # Worktree bridge scripts
│   ├── skills/jj-guide             # Symlink → ../../shared/skills/jj-guide
│   ├── commands/                   # /jj-commit, /develop
│   └── agents/jj-doctor.md        # VCS debugger sub-agent
│
├── codex/                           # Codex adapter
│   ├── skills/jj-guide             # Symlink → ../../shared/skills/jj-guide
│   ├── rules/jj-skipper.rules     # execpolicy guard
│   ├── agents/AGENTS.md
│   └── install.sh
│
├── LICENSE.md
├── README.md
└── CHANGELOG.md
```

Symlinks keep it DRY — shared content is edited once, used by both adapters. Claude Code follows symlinks during plugin cache copy. Codex `install.sh` falls back to file copy if symlinks aren't supported.

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
| `git pull --rebase` | `jj git fetch && jj rebase -d main` |
| `git checkout -b feat` | `jj new main -m "feat: desc"` |
| `git stash` | `jj new` |
| `git log` | `jj log` |
| Undo anything | `jj undo` |

See [`shared/skills/jj-guide/SKILL.md`](shared/skills/jj-guide/SKILL.md) for the full reference.

## Acknowledgments

Inspired by [kawaz/claude-plugin-jj](https://github.com/kawaz/claude-plugin-jj), [kalupa/jj-workflow](https://github.com/kalupa/jj-workflow), [danverbraganza/jujutsu-skill](https://github.com/danverbraganza/jujutsu-skill), and [alexlwn123/jj-claude-code-plugin](https://github.com/alexlwn123/jj-claude-code-plugin). See [LICENSE.md](LICENSE.md) for details.

## License

[MIT](LICENSE.md)
