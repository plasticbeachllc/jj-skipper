# Version Control — jj (Jujutsu)

When a workspace is tracked by jj (`.jj/` directory present), use jj exclusively for all VCS operations. Never run bare `git` commands in jj-managed workspaces.

## Rules

- **Always use `-m` flags** — editors hang agents.
- **Never use `-i` flags** — interactive TUI hangs agents.
- **Prefer change IDs** (letters like `nmwwolux`) over commit IDs (hex) — they survive rewrites.
- **Codex shipping preflight** — before commit/push in colocated repos, do a quick `.git` write probe. In sessions started with `-a never`, treat a failed probe as "edit/test only" and ship from a local shell instead.

## Workflow

```bash
jj new main -m "feat: description"
jj bookmark create <feature-name> -r @
# ... work ...
jj commit -m "feat: description"
jj git push -b <feature-name>
```

After `jj commit`, content is at `@-` (parent). `@` is always an empty working copy.

## Quick Reference

| Instead of | Use |
|------------|-----|
| `git status` | `jj st` |
| `git add && git commit` | `jj commit -m "msg"` |
| `git push` | `jj git push` |
| `git pull` | `jj git fetch && jj bookmark set main -r main@origin` |
| `git checkout -b feat` | `jj new main -m "feat: desc"` |
| `git log` | `jj log` |
| Undo anything | `jj undo` |

## Skills

- **jj-guide** — full command reference and git-to-jj mappings
- **jj-workspace** — create isolated workspaces for parallel development
- **jj-commit-push-pr** — commit, push, and open a PR
- **jj-doctor** — diagnose and fix tangled VCS state
