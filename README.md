# jj-skipper

Native [Jujutsu (`jj`)](https://docs.jj-vcs.dev/) workflows for AI coding agents.

jj-skipper helps Claude Code and OpenAI Codex operate safely in jj repositories. It blocks accidental bare Git commands, supplies concise jj guidance only when relevant, and provides focused workflows for parallel work and delivery.

## Capabilities

| Capability | Claude Code | Codex |
|---|:---:|:---:|
| Block bare `git` inside jj repositories | ✓ | ✓ |
| Inject minimal jj context at session start | ✓ | ✓ |
| On-demand jj guidance | ✓ | ✓ |
| Workspace and pull-request workflows | ✓ | ✓ |
| Automatic worktree-to-workspace bridge | ✓ | — |
| `jj-doctor` diagnostic agent | ✓ | — |

The guard is repository-aware: it activates only when `.jj/` is present and leaves ordinary Git repositories unchanged. For a Git-only operation, use the explicit `:;git` escape hatch.

Codex also includes an optional machine-wide [strict rule](codex/rules/jj-skipper-strict.rules). It is not installed by default.

## Requirements

- [`jj`](https://docs.jj-vcs.dev/latest/install-and-setup/)
- [`jq`](https://jqlang.github.io/jq/download/)

Colocated repositories are recommended. They retain `.git/` compatibility for tools such as GitHub CLI and editors while jj remains the VCS interface for agents.

```bash
jj git init --colocate
```

## Installation

### Claude Code

Run inside Claude Code:

```text
/plugin marketplace add plasticbeachllc/jj-skipper
/plugin install jj-skipper@jj-skipper
/reload-plugins
```

For local development, replace the GitHub repository with this checkout:

```text
/plugin marketplace add /path/to/jj-skipper
/plugin install jj-skipper@jj-skipper
/reload-plugins
```

### Codex

```bash
codex plugin marketplace add plasticbeachllc/jj-skipper
codex plugin add jj-skipper@jj-skipper
```

Start a new Codex session, then review and trust the bundled hook when prompted. For local development, pass the checkout path to `codex plugin marketplace add` instead.

The legacy [standalone installer](codex/install.sh) remains available for environments without native plugin support:

```bash
bash codex/install.sh
```

## Usage

The guard and startup context work automatically. Skills activate only for matching tasks:

| Skill | Purpose |
|---|---|
| `jj-guide` | Complex commands, rewriting, revsets, or recovery |
| `jj-workspace` | Isolated workspaces and bookmarks for parallel work |
| `jj-commit-push-pr` | Commit, push, and open a GitHub pull request |

Claude Code also provides `jj-doctor` for diagnosing lost work, bookmark problems, conflicts, and stale state.

Automated Claude worktrees start from the locally known non-root `trunk()` revision, falling back to `@-` in a local repository without one. Set `JJ_SKIPPER_WORKSPACE_BASE=head` to base them on the current local change. The custom hook does not alter `.envrc`; use explicit repository selectors such as `gh pr create --repo owner/repository` for Git-dependent tools.

For environments without plugin support, copy [AGENTS.template.md](AGENTS.template.md) into the appropriate project instructions file.

## Context model

jj-skipper keeps its default context footprint deliberately small:

- Non-jj repositories receive no startup guidance.
- jj repositories receive only a short set of core invariants.
- Routine commands do not load the general guide.
- Detailed workflows, revsets, translations, and recovery material load on demand.
- Tests enforce word budgets for every eagerly discoverable instruction.

## Architecture

`shared/` is the source of truth. The Claude Code and Codex plugin directories contain generated copies so each installed package is self-contained.

```text
shared/          canonical skills and guard
claude-code/     Claude Code plugin, hooks, and diagnostic agent
codex/           Codex plugin, hooks, and legacy installer
scripts/         adapter synchronization
test.sh          structural and behavioral test suite
```

After editing shared content, regenerate the adapters and run the test suite:

```bash
bash scripts/sync-adapters.sh
bash test.sh
```

The suite checks plugin contracts, hook behavior, workspace lifecycle, adapter synchronization, shell syntax, and context budgets.

## Quick reference

| Git habit | jj equivalent |
|---|---|
| `git status` | `jj st` |
| `git add -A && git commit -m "msg"` | `jj commit -m "msg"` |
| `git checkout -b feature` | `jj new main -m "description"`, then create a bookmark |
| `git pull --rebase` | `jj git fetch`, then `jj rebase -o main@origin` |
| `git push` | `jj git push` |
| `git stash` | `jj new` |
| `git reflog` | `jj op log` |

See the [Git-to-jj reference](shared/skills/jj-guide/references/git-to-jj.md) for a broader mapping.

## Acknowledgments

Inspired by [kawaz/claude-plugin-jj](https://github.com/kawaz/claude-plugin-jj), [kalupa/jj-workflow](https://github.com/kalupa/jj-workflow), [danverbraganza/jujutsu-skill](https://github.com/danverbraganza/jujutsu-skill), and [alexlwn123/jj-claude-code-plugin](https://github.com/alexlwn123/jj-claude-code-plugin). See [LICENSE.md](LICENSE.md) for attribution details.

## License

[MIT](LICENSE.md)
