---
name: jj-guide
description: "REQUIRED for any VCS operation in jj repositories (.jj/ directory present).
Activate on: commit, push, pull, status, diff, log, branch, PR, merge, rebase, stash,
or any version control task. In jj repos: use jj commands exclusively, never git."
---

# jj Guide for AI Agents

## Critical Rules

- **NEVER** run git commands in a jj repo. Use jj equivalents exclusively.
- **ALWAYS** use `-m` flags for commit/describe. Without `-m`, editors open and hang the agent.
- **NEVER** use `-i` flags. Interactive TUI hangs in agent environments.
- After `jj commit -m "msg"`: content is in **@-** (parent). New **@** is empty.
  Target @- for bookmarks and pushes.
- Use **change IDs** (letters, e.g. `nmwwolux`) over commit IDs (hex). Change IDs are stable across rewrites.

## Mental Model

- Working copy IS a commit (@). File edits auto-amend into @.
- No staging area. No `git add`. All file changes are tracked automatically.
- Commits are mutable until pushed.
- Conflicts are stored in commits — resolve later, not at merge time.
- Operation log records everything. `jj undo` reverts any operation.

## Multi-Agent Bookmark Model

Each agent operates on its own named bookmark, branched from `main`. Isolation is structural — one bookmark per concern, not reactive splitting after the fact.

Use `/jj-status` before pushing to check for file conflicts with other agents' bookmarks.

### Start work (one bookmark per agent/feature)

Use `/jj-workspace` to create an isolated workspace with GIT_DIR wiring, or manually:

```bash
jj new main -m "feat: description"
jj bookmark create <feature-name> -r @   # bookmark tracks this change ID
# ... work ... (auto-tracked)
jj commit -m "feat: description"
# bookmark already points at @- (the content) — no set needed
jj git push -b <feature-name>
```

### Why `@` not `@-` on create?
The bookmark tracks the **change ID**, not the graph position. After `jj commit`, the change (with content) becomes `@-` and the bookmark still points at it.

### Bookmark lifecycle
- **Create before work**: `jj bookmark create <name> -r @` — gives agent context immediately
- **After commit**: verify with `jj bookmark list` — bookmark should point at `@-`
- **After PR merges**: clean up with `jj bookmark delete <feature-name>`
- **Fix mispointed bookmark**: `jj bookmark set <name> -r <change-id>`

### Workspaces in colocated repos
Secondary workspaces created by `jj workspace add` lack a `.git/` directory. The `WorktreeCreate` hook handles this automatically by writing a `.envrc` that sets `$GIT_DIR`. If `gh` CLI is not working in a worktree, verify `direnv` is installed and run `direnv allow` (or `source .envrc`) in that directory.

## Common Workflows

### Amend current change
```bash
jj describe -m "better message"     # change message only
jj squash                           # fold @ into parent
```

### Address PR review (rewrite)
```bash
jj edit <change-id>                 # make it working copy
# ... fix ...
jj new                              # done editing
jj git push                         # auto force-push
```

### Address PR review (additive)
```bash
jj new <bookmark-tip>
# ... fix ...
jj commit -m "address review"
jj bookmark set <name> -r @-
jj git push -b <name>
```

### Sync after PR merge (fast-forward)
```bash
jj git fetch
jj bookmark set main -r main@origin   # advance local bookmark
```

### Sync with local commits on top
```bash
jj git fetch
jj bookmark set main -r main@origin
jj rebase -d main@origin               # rebase YOUR commits, not main
```
> Never `jj rebase -s main` — `main` is an immutable tracked bookmark. Target the commit above it.

### Selective operations with filesets
```bash
# Commit only some files:
jj commit -m "msg" file1.rs file2.rs

# Commit by glob pattern:
jj commit -m "msg" 'glob:src/**/*.rs'

# Restore specific files:
jj restore --from @- file.txt

# Split a change (non-interactive):
jj split 'glob:tests/**'            # tests go to first commit, rest stays
```

### Advanced operations
```bash
# Auto-route hunks to correct ancestor commits:
jj absorb

# Compare how a change evolved across rewrites:
jj interdiff --from <rev1> --to <rev2>
```

## Git → jj Quick Reference

| Task | git | jj |
|------|-----|----|
| Status | `git status` | `jj st` |
| Diff | `git diff` | `jj diff` |
| Log | `git log` | `jj log` |
| Show commit | `git show <ref>` | `jj show <rev>` |
| Stage + commit | `git add . && git commit -m "msg"` | `jj commit -m "msg"` |
| Amend | `git commit --amend` | `jj squash` or `jj describe -m "msg"` |
| Push | `git push` | `jj git push` |
| Fetch | `git fetch` | `jj git fetch` |
| Pull (fast-forward) | `git pull` | `jj git fetch && jj bookmark set main -r main@origin` |
| Pull (rebase local) | `git pull --rebase` | `jj git fetch && jj rebase -d main@origin` |
| Switch branch | `git checkout <branch>` | `jj new <rev>` or `jj edit <rev>` |
| Create branch | `git checkout -b <name>` | `jj new main -m "desc"` (+ bookmark later) |
| List branches | `git branch` | `jj bookmark list` |
| Stash | `git stash` | `jj new` (old work stays in parent) |
| Stash pop | `git stash pop` | `jj edit <prev-change-id>` |
| Cherry-pick | `git cherry-pick` | `jj duplicate <rev>` |
| Revert | `git revert` | `jj revert -r <rev>` |
| Rebase | `git rebase <base>` | `jj rebase -d <dest>` |
| Blame | `git blame` | `jj file annotate` |
| Worktree | `git worktree add` | `jj workspace add` |
| Undo last | (complex) | `jj undo` |

Full mapping: see [references/git-to-jj.md](references/git-to-jj.md)

## Revset Quick Reference

| Expression | Meaning |
|------------|---------|
| `@` | Current working copy |
| `@-` | Parent of working copy |
| `@--` | Grandparent of working copy |
| `trunk()` | Main/master branch tip |
| `mine()` | Changes authored by you |
| `bookmarks()` | All bookmark tips |
| `remote_bookmarks()` | All remote bookmark tips |
| `x::y` | DAG range: ancestors of y that are descendants of x |
| `::x` | All ancestors of x |
| `x..y` | Set difference: (::y) ~ (::x) — commits in y but not x |
| `heads(x)` | Commits in x with no children in x |
| `roots(x)` | Commits in x with no parents in x |
| `description(pat)` | Commits whose description matches pattern |
| `file(path)` | Commits that modified the given path |
| `present(x)` | x if it exists, empty set otherwise |
| `empty()` | Commits with no diff |
| `conflicts()` | Commits with unresolved conflicts |
| `x \| y` | Union |
| `x & y` | Intersection |
| `~x` | Complement (not in x) |

## Workspace Model

- **Colocated**: both `.jj/` and `.git/` exist. Git tools read `.git/` naturally.
- **Claude Code**: `WorktreeCreate` hook → `jj workspace add` + `.envrc` for `$GIT_DIR`. Automatic.
- **Codex**: built-in worktree toggle uses git worktrees; jj auto-imports changes.
- **Multi-agent isolation**: one bookmark per agent/feature (see above) + workspace per agent for filesystem isolation.

## Common Pitfalls

1. **Bookmarks don't auto-advance** after commit. `bookmark create` tracks the change ID (stays correct). `bookmark set` on named bookmarks like `main` needs `-r @-` explicitly.
2. **@ after jj commit is empty.** Content is in @-. Don't push @ — push @-.
3. **jj new ≠ git commit.** `jj new` = new empty change. `jj commit` = finalize @.
4. **:: is DAG range, .. is set difference.** They are NOT interchangeable.
5. **Empty commits are normal** — they mean "ready to work here."
6. **Forgot to describe?** Use `jj describe -m "msg"` on @ or `jj describe -m "msg" -r <rev>` on any mutable commit.
7. **`Commit is immutable` error** — you targeted a tracked bookmark (e.g. `main`) directly in a rebase. Target the commit above it, or use `main@origin` as the destination instead.

## Troubleshooting

- Undo anything: `jj undo`
- See operation history: `jj op log`
- Restore to past state: `jj op restore <op-id>`
- Stale workspace: `jj workspace update-stale`
- Complex issues (Claude Code): invoke jj-doctor
- Complex issues (Codex): describe problem, check `jj op log`, try `jj undo`
