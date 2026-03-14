# Version Control — jj (Jujutsu)

This project uses jj exclusively. The repo is colocated (`.jj/` and `.git/` both exist). All VCS writes use jj. Git reads work naturally.

## Rules

- **Never run git commands.** Use jj equivalents. The jj-guide skill has full mappings.
- **Always use `-m` flags.** Without `-m`, editors open and hang the agent.
- **Never use `-i` flags.** Interactive TUI will hang.
- **Use change IDs** (letters like `nmwwolux`) over commit IDs (hex). Change IDs are stable across rewrites.

## Multi-Agent Model: One Bookmark per Agent/Feature

Before doing any work, create a bookmark:
```bash
jj new main -m "feat: description"
jj bookmark create <feature-name> -r @
```

After committing, the content is at `@-` (parent). `@` is always an empty working copy. The bookmark tracks the change ID, so it stays pointed at the right commit.

To push:
```bash
jj git push -b <feature-name>
```

To sync after a PR merges on GitHub:
```bash
jj git fetch
jj bookmark set main -r main@origin
```

Claude Code handles workspace creation automatically via the WorktreeCreate hook.
If `gh` CLI doesn't work in a worktree, run `direnv allow` or `source .envrc`.

## Quick Reference

| Instead of | Use |
|------------|-----|
| `git status` | `jj st` |
| `git add . && git commit -m "msg"` | `jj commit -m "msg"` |
| `git push` | `jj git push` |
| `git pull` | `jj git fetch && jj bookmark set main -r main@origin` |
| `git pull --rebase` | `jj git fetch && jj rebase -d main@origin` |
| `git checkout -b feat` | `jj new main -m "feat: desc"` |
| `git log` | `jj log` |
| `git stash` | `jj new` |

Use the jj-guide skill for full reference. Use `/jj-commit-push-pr` to ship code. If VCS state gets tangled, invoke jj-doctor.
