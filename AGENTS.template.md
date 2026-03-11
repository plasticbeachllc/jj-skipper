# Version Control — jj (Jujutsu)

Use **jj** exclusively for version control. Projects are colocated (both `.jj/` and `.git/` exist) but all VCS operations MUST use jj commands, never git directly.

## Rules

- **Never run git commands.** Use jj equivalents. The jj-guide skill has full mappings.
- **Always use `-m` flags.** Without `-m`, editors open and hang the agent.
- **Never use `-i` flags.** Interactive TUI will hang.
- **After `jj commit -m "msg"`**: the content is in **@-** (parent). New **@** is empty. Target @- for bookmarks and pushes.
- **Use change IDs** (letters like `nmwwolux`) over commit IDs (hex). Change IDs are stable across rewrites.

## Workflows

### Commit and push (named bookmark like main):
```bash
jj commit -m "message"
jj bookmark set main -r @-
jj git push -b main
```

### Commit and push (PR auto-bookmark):
```bash
jj commit -m "feat: add thing"
jj git push -c @-
```

### Start new work:
```bash
jj new main -m "feat: description"
```

### Fetch and rebase:
```bash
jj git fetch
jj rebase -d main
```

### Undo anything:
```bash
jj undo
```

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

## Troubleshooting

If VCS state gets tangled: check `jj op log`, try `jj undo`. For Claude Code, invoke jj-doctor.
