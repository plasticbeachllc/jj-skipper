---
name: jj-status
description: "Show multi-agent workspace status, active bookmarks, and potential
file conflicts between parallel agents. Activate when coordinating parallel work,
checking what other agents are doing, or before pushing to detect conflicts."
---

# Multi-Agent Status Check

Use this before pushing or when coordinating with other parallel agents.

## 1. Survey the landscape

```bash
jj workspace list
jj bookmark list
jj log -r 'bookmarks() | @' --limit 20
```

Report:
- **Your workspace**: name and bookmark
- **Other workspaces**: what other agents are working on
- **Bookmark status**: which bookmarks are ahead of main, behind, or conflicting

## 2. Check for file conflicts (before push)

Compare your changed files against other active bookmarks:

```bash
# Files you've changed:
jj log -r 'main..@' --no-graph --stat

# Files another bookmark changed:
jj log -r 'main..<other-bookmark>' --no-graph --stat
```

If overlap exists, warn the user:
> **Potential conflict**: your bookmark and `<other-bookmark>` both modify `<file>`.
> Consider rebasing one onto the other: `jj rebase -d <other-bookmark>`

## 3. Sync recommendation

If `main` has advanced (another PR merged):
```bash
jj git fetch
jj bookmark set main -r main@origin
jj rebase -d main@origin
```

## 4. Push readiness

Before pushing, confirm:
- [ ] Bookmark points at content (`@-` after commit, not empty `@`)
- [ ] No unresolved conflicts: `jj log -r @ | grep -v '×'`
- [ ] Files don't overlap with other active bookmarks (or overlap is intentional)

Then push:
```bash
jj git push -b <bookmark-name>
```
