---
name: jj-commit-push-pr
description: "Ship completed jj work: commit, update its bookmark, push, and open a GitHub PR. Activate only when the user asks to publish or finalize changes."
---

# Ship jj Work

1. Inspect state and identify the bookmark:

```bash
jj st
jj bookmark list
```

2. If `@` has no bookmark, create one:

```bash
jj bookmark create <feature-name> -r @
```

3. Commit and verify that the bookmark follows the content at `@-`:

```bash
jj commit -m "<message>"
jj bookmark list
jj bookmark set <feature-name> -r @-   # only if mispointed
```

4. Push and open the PR:

```bash
jj git push -b <feature-name>
gh pr create --repo <owner/repository> --base main --head <feature-name> \
  --title "<title>" --body "<body>"
```

Derive `<owner/repository>` from the `origin` URL shown by `jj git remote list`; do not add Git work-tree metadata to a jj workspace. Return the PR URL and `jj log -r '@ | @-'` summary.
