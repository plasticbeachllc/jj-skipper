# MEMO

**TO:** Architect, jj-skipper skill
**FROM:** Taylor / plasticbeachllc
**DATE:** March 10, 2026
**RE:** Proposed update — PR merge sync flow for guide/doctor

---

## Background

During a live session, I attempted to sync my local colocated jj repo after merging a PR on GitHub. The flow was not documented and required several steps of trial and error to resolve. This memo captures the correct flow for inclusion in the skill guide or doctor output.

## What Went Wrong

The naive approach of running `jj rebase -s main -d main@origin` after a fetch failed with an immutability error, because `main` itself is an immutable tracked bookmark. The skill should anticipate this and document the correct two-step flow.

## Recommended Flow: Post-PR Merge Sync

For a colocated repo (jj + git) after merging a PR on GitHub:

**Step 1 — Fetch from origin**

```
jj git fetch
```

**Step 2 — Advance local bookmark to match origin**

```
jj bookmark set main -r main@origin
```

This is the jj equivalent of `git pull` on a fast-forward. It moves the local `main` bookmark to the updated remote position without attempting to rewrite immutable commits.

## Edge Cases to Document

- **Local commits on top of main:** Use `jj rebase -s <divergence commit> -d main@origin`. Do NOT use `-s main` as `main` itself is immutable.
- **Named branches descending from main:** The `-s` flag cascades to all descendants automatically, so named branches forked off `main` will follow.
- **Immutability error:** If you see `Commit is immutable`, you are targeting a bookmark directly. Target the commit above it instead.

## Suggested Doctor / Guide Addition

The skill guide or doctor output should include a section titled something like "Syncing after a GitHub PR merge" with the two-step flow above as the canonical answer, and a note distinguishing the fast-forward case (no local commits) from the rebase case (local commits exist on top).

---

*Happy to pair on the wording if useful.*