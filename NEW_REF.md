# jj-skipper Implementation Spec
## Post-Session Update — Multi-Agent Bookmark Workflow

**To:** Plugin Maintainer
**From:** Taylor / plasticbeachllc
**Date:** March 11, 2026
**Scope:** This spec covers three areas of work that emerged from a live session. The maintainer has already consumed prior changes. This document picks up from there.

---

## Context

A live working session surfaced two workflow gaps and validated a new operating model for multi-agent development. The changes below should be treated as a coherent unit — they are interdependent.

**What changed conceptually:**

The previous model assumed agents would pile changes into a shared working copy and use `jj split` reactively to separate concerns before pushing. This is fragile at velocity. The new model is structural: each agent receives an isolated bookmark at the start of its work. Commits are already separated by design. Splitting is rarely needed.

This has downstream consequences for the `/jj-commit` command, the jj-guide skill, and the CLAUDE.md boilerplate — all of which are addressed below.

---

## 1. New Skill: `jj-pr-workflow`

Create a new skill at `shared/skills/jj-pr-workflow/SKILL.md` and symlink into both platform adapters. This skill covers the full lifecycle of a PR from a colocated repo against GitHub.

### 1a. Scope of the skill

The skill must cover three distinct sub-workflows:

**Opening a PR (new bookmark model)**

The canonical flow for an agent starting a new unit of work:

```bash
# Start from current main
jj new main -m "feat: brief description"

# Create a named bookmark pointing at the working copy parent
jj bookmark create <feature-name> -r @-

# Do work — jj snapshots automatically, no staging needed

# Commit with a full message
jj commit -m "feat: full commit message"

# Push the bookmark as a branch and open PR
jj git push -b <feature-name>
gh pr create --base main --head <feature-name> --title "..." --body "..."
```

Key note for the skill: after `jj commit`, the content is at `@-` (parent), not `@` (empty working copy). This is the most common agent mistake and must be called out explicitly.

**Syncing after a PR is merged on GitHub**

This must be documented as the canonical "pull" flow. The naive `jj rebase -s main -d main@origin` will fail with an immutability error because `main` is a tracked bookmark and therefore immutable. The correct two-step flow:

```bash
jj git fetch
jj bookmark set main -r main@origin
```

The skill should distinguish two cases:
- **No local commits on top of main** (clean sync): the two steps above are sufficient.
- **Local commits on top of main**: after the two steps above, rebase local work with `jj rebase -s <divergence commit> -d main@origin`. Do not use `-s main` — main is immutable.

**Handling the immutability error**

If an agent encounters `Error: Commit X is immutable`, document what it means (the target is a tracked remote bookmark) and the correct response (target the commit above it, or use `jj bookmark set` for fast-forward cases).

### 1b. What the skill should NOT cover

The PR workflow skill is not a general jj reference. Keep it narrow. The jj-guide skill handles mental model, revsets, filesets, and command mapping. The PR workflow skill handles GitHub-facing operations only.

---

## 2. Update: `jj-guide` Skill

The existing jj-guide skill needs two additions.

### 2a. Multi-agent bookmark model

Add a section documenting the canonical operating model for parallel agent work. The key points:

- Each agent operates on its own named bookmark, branched from `main`
- Bookmarks are created at the start of work, not after
- `jj workspace add` is explicitly **not** the recommended approach for colocated repos — secondary workspaces lose colocation, breaking `gh` CLI and other git-expecting tools
- Isolation is structural (one bookmark per concern) not reactive (split after the fact)

Include a brief explanation of why `jj workspace add` doesn't work here: secondary workspaces in a colocated repo become pure jj workspaces without a `.git` directory, which breaks `gh` CLI and any other tool that expects `.git/`.

### 2b. Bookmark lifecycle rules

Add explicit rules for bookmark hygiene:

- Always create the bookmark before doing work, pointing at `@-`
- After `jj commit`, the bookmark should already point at the right commit — verify with `jj bookmark list`
- After a PR merges, clean up the remote bookmark: `jj bookmark delete <feature-name>`
- Use `jj bookmark list` to audit state before pushing

---

## 3. Rework: `/jj-commit` Command

The current `/jj-commit` command was designed around reactive file grouping — the assumption that an agent would have mixed changes in a working copy and need to split them into separate commits before pushing. This assumption no longer holds under the new model.

### 3a. What to remove

Remove or deprecate guidance around:
- Using `jj split` as a primary workflow step
- Grouping files from a shared working copy into separate commits
- Any framing that treats the working copy as a shared accumulation point

### 3b. What to replace it with

Reframe `/jj-commit` as a **focused commit and push command** for the single-bookmark model:

```
/jj-commit <bookmark-name> "<commit message>"
```

The command should:

1. Verify the current working copy has changes (`jj st`)
2. Commit with the provided message (`jj commit -m "..."`)
3. Confirm the bookmark is pointing at `@-` — if not, set it (`jj bookmark set <name> -r @-`)
4. Push (`jj git push -b <bookmark-name>`)
5. Remind the agent that `@` is now an empty working copy and `@-` is the commit with content

### 3c. Split as escape hatch

`jj split` is still valid in edge cases — e.g. an agent accidentally accumulated unrelated changes on one bookmark. Document it briefly as an escape hatch in the jj-guide skill, not as a primary workflow. The split interactive flow (`jj split` with file selection) works for this purpose but should not be the default path.

---

## 4. Update: CLAUDE.md / AGENTS.md Boilerplate

The per-project instructions block in the README and in any generated CLAUDE.md/AGENTS.md boilerplate needs to reflect the new model. Suggested replacement for the key rules section:

```markdown
## Version Control

This project uses jj (Jujutsu) exclusively. The repo is colocated (.jj/ and .git/ both
exist). All VCS writes use jj. Git reads work naturally.

**Multi-agent model: one bookmark per agent/feature.**

Before doing any work, create a bookmark:
  jj new main -m "feat: description"
  jj bookmark create <feature-name> -r @-

After committing, the content is at @- (parent). @ is always an empty working copy.

To push:
  jj git push -b <feature-name>

To sync after a PR merges on GitHub:
  jj git fetch
  jj bookmark set main -r main@origin

Never use jj workspace add in a colocated repo — secondary workspaces lose .git/
compatibility and break gh CLI.

Use the jj-guide skill for full reference. Use jj-pr-workflow skill for GitHub operations.
If VCS state gets tangled, invoke jj-doctor.
```

---

## 5. Dependency and Sequencing Notes

The maintainer should implement in this order:

1. **jj-pr-workflow skill** — new content, no conflicts with existing work
2. **jj-guide additions** — additive, low risk
3. **CLAUDE.md boilerplate** — depends on both skills being in place so references are valid
4. **`/jj-commit` rework** — highest risk of behavior change, do last so the new skills are available to reference

---

## 6. Out of Scope for This Spec

The following are known gaps but not addressed here:

- `jj-doctor` logic for diagnosing stale or orphaned bookmarks from the old split-based workflow — worth a follow-up once the new model is in use
- Codex adapter parity for the new PR workflow skill — the symlink approach in the existing structure should handle this automatically, but verify
- Testing the `jj workspace add` workaround using `$GIT_DIR` + direnv for cases where true workspace isolation is needed — documented in jj's GitHub docs but not validated against this stack