# jj-skipper — Codex Agent Instructions

Use **jj** exclusively for version control. Projects are colocated (both `.jj/` and `.git/` exist) but all VCS operations MUST use jj commands, never git directly.

## Rules

- **Never run git commands.** Use jj equivalents. The jj-guide skill has full mappings.
- **Always use `-m` flags.** Without `-m`, editors open and hang the agent.
- **Never use `-i` flags.** Interactive TUI will hang.
- **After `jj commit -m "msg"`**: the content is in **@-** (parent). New **@** is empty. Target @- for bookmarks and pushes.
- **Use change IDs** (letters like `nmwwolux`) over commit IDs (hex). Change IDs are stable across rewrites.

## Quick Reference

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

## Push Patterns

### Named bookmark (main, long-lived branches):
```bash
jj commit -m "message"
jj bookmark set main -r @-
jj git push -b main
```

### Auto-bookmark (PR feature branches):
```bash
jj commit -m "feat: add thing"
jj git push -c @-
```

## Troubleshooting

- Undo anything: `jj undo`
- Operation history: `jj op log`
- Restore to past state: `jj op restore <op-id>`

See the jj-guide skill for the full command reference.
