# Version Control — jj

In repositories containing `.jj`, use jj for every VCS operation. Do not run bare Git unless a Git-only feature requires the explicit `:;git` escape hatch. Keep commands non-interactive: pass `-m`; never use `-i` or open an editor. Prefer change IDs. The working copy is `@`; after `jj commit`, committed content is at `@-`.

Use `jj-workspace` for isolated parallel work, `jj-commit-push-pr` for delivery, and `jj-guide` only for unfamiliar operations or recovery.
