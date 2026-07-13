# jj Recovery

Inspect before changing state:

```bash
jj st
jj log -r 'all()' --limit 30
jj op log --limit 20
```

| Symptom | Recovery path |
|---|---|
| Recent operation was wrong | `jj undo` |
| Lost or hidden work | Find it with `jj log -r 'all()'` |
| Need an earlier repository state | `jj op log`, then `jj op restore <op-id>` |
| Inspect before restoring | `jj --at-op <op-id> log` or `diff` |
| Stale workspace | `jj workspace update-stale` |
| Bookmark points incorrectly | `jj bookmark set <name> -r <change-id>` |
| Local and remote bookmark disagree | `jj bookmark list --all`; fetch and resolve tracking |
| Divergent change IDs | Inspect both commits; abandon one or assign a new change ID |
| Immutable rewrite error | Rebase the mutable change with `jj rebase -o main@origin`; do not rewrite main itself |
| Git backend out of sync | `jj git import`, then `jj git export` if required |

Conflicts are stored in commits. Edit conflicted files, verify with `jj st`, then squash the resolution into the intended change if necessary. Descendants will rebase automatically.

Prefer change IDs during recovery because they survive rewrites. Do not abandon or restore until the current graph and operation history are understood.
