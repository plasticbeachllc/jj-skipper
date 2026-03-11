# jj-skipper — Codex Agent Instructions

This project uses jj exclusively. The repo is colocated (`.jj/` and `.git/` both exist). All VCS writes use jj. Git reads work naturally.

## Rules

- **Never run git commands.** Use jj equivalents.
- **Always use `-m` flags.** Without `-m`, editors open and hang the agent.
- **Never use `-i` flags.** Interactive TUI will hang.
- **Use change IDs** (letters like `nmwwolux`) over commit IDs (hex). Change IDs are stable across rewrites.

## Workflow: One Bookmark per Feature

```bash
jj new main -m "feat: description"
jj bookmark create <feature-name> -r @
# ... work ...
jj commit -m "feat: description"
jj git push -b <feature-name>
```

After `jj commit`, content is at `@-`. The bookmark tracks the change ID and stays pointed correctly.

To sync after a PR merges:
```bash
jj git fetch
jj bookmark set main -r main@origin
```

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
| Undo anything | `jj undo` |

## Troubleshooting

- Undo anything: `jj undo`
- Operation history: `jj op log`
- Restore to past state: `jj op restore <op-id>`

See the jj-guide skill for the full command reference.
