# jj-skipper: LLM Compatibility Layer for Jujutsu VCS

## Vision

**jj-skipper** makes jj (Jujutsu) the native VCS for AI coding agents across platforms. It provides a single source of truth for jj knowledge, guard logic, and workflow automation that works with both Claude Code and OpenAI Codex — without duplicating content or maintaining parallel configurations.

The name "skipper" represents how the agent steers the repo through tumultuous waters using jj. It also harkens to jj's ability to "skip" unbookmarked changes in the git commit history.

### Design Principles

1. **Single source of truth.** One repo. Shared skills, scripts, and reference docs. Platform adapters are thin wiring that point at shared content. Symlinks keep it DRY.
2. **Guard, don't just guide.** Where the platform supports enforcement (Claude Code hooks), block git mutations before execution. Where it doesn't (Codex), layer instruction-based guardrails in AGENTS.md.
3. **Colocated mode.** Repos use `jj git init --colocate` so both `.jj/` and `.git/` exist. This preserves compatibility with Codex worktrees, VSCode, `gh` CLI, and any tool expecting `.git/`. Agents use jj for all writes; git reads work naturally.
4. **Non-interactive by default.** Agents can't use TUIs. Every command path must work headlessly with `-m`, filesets, and explicit flags.
5. **Vendor once, use everywhere.** Claude Code installs via marketplace (symlinks followed during cache copy). Codex vendors via install script to `~/.codex/skills/`. Same content, no duplication.

### Inspirations & Credit

| Source | What we took | License |
|--------|-------------|---------|
| [kawaz/claude-plugin-jj](https://github.com/kawaz/claude-plugin-jj) | Three-layer architecture (hook → skill → agent), PreToolUse guard pattern, `:;git` escape hatch, comprehensive jj expert knowledge, non-interactive fileset patterns | MIT |
| [kalupa/jj-workflow](https://github.com/kalupa/jj-workflow) | WorktreeCreate/WorktreeRemove hook bridge to jj workspaces, `/develop` slash command, `/jj-commit` with pre-commit validation, session-start config inspection | MIT |
| [danverbraganza/jujutsu-skill](https://github.com/danverbraganza/jujutsu-skill) | "Describe first, then code" workflow philosophy, `allowed-tools` restriction pattern, atomic commit emphasis | MIT |
| [alexlwn123/jj-claude-code-plugin](https://github.com/alexlwn123/jj-claude-code-plugin) | Config import command (`/config` → CLAUDE.md), Context7 delegation pattern for edge cases | MIT |

---

## Platform Capabilities Matrix

| Capability | Claude Code | Codex (App + CLI) |
|-----------|------------|-------------------|
| **Hooks (PreToolUse)** | Yes — scripts run before tool calls, can deny/allow | No hooks, but `execpolicy` rules can `forbidden` commands by prefix (our guard for Codex) |
| **WorktreeCreate/Remove hooks** | Yes — lifecycle hooks intercept worktree requests | No — worktrees are built into the app UI, use git worktrees directly |
| **Skills (SKILL.md)** | `.claude/skills/` or via plugin. Progressive disclosure | `.codex/skills/` or `.agents/skills/`. Same SKILL.md format with frontmatter |
| **Slash commands** | `commands/*.md` in plugins → `/command-name` | Similar pattern. `$skill-name` invocation |
| **Sub-agents** | `agents/*.md`, scoped model + tools | No native sub-agents |
| **Project instructions** | `CLAUDE.md` at project root | `AGENTS.md` at project root (also reads `CLAUDE.md` as fallback) |
| **Plugin system** | Marketplace, `plugin.json`, hooks, agents, skills | Skills are primary extension. `$skill-installer` for distribution |
| **Built-in worktrees** | `--worktree` flag (uses git worktrees) | "Worktree" toggle in app UI (uses git worktrees) |

### What This Means for jj-skipper

**Shared across platforms (edit once):**
- SKILL.md files (identical format)
- Reference docs (git→jj mappings, revset guides)
- Shell scripts (guard logic, workspace cleanup)

**Claude Code adapter (thin wiring):**
- `hooks.json` (PreToolUse guard, WorktreeCreate/Remove bridge to jj workspaces)
- `.claude-plugin/plugin.json` manifest
- Sub-agent: `jj-doctor` (debugger for untangling state)
- Slash commands: `/jj-commit`, `/develop`

**Codex adapter (thin wiring):**
- `install.sh` to vendor shared skills into `~/.codex/skills/` and rules into `~/.codex/rules/`
- `jj-skipper.rules` — `execpolicy` rule that blocks all `git` commands with `decision = "forbidden"`
- `agents/openai.yaml` metadata for Codex app

**Per-project (both platforms):**
- CLAUDE.md / AGENTS.md instructions declaring jj-first policy and referencing the skill. Also settable via user preferences for Claude.

---

## Specification

### Repository Structure

```
jj-skipper/
├── shared/                              # PLATFORM-AGNOSTIC — the real content
│   ├── skills/
│   │   └── jj-guide/
│   │       ├── SKILL.md                 # Core jj knowledge (both platforms)
│   │       └── references/
│   │           └── git-to-jj.md         # Detailed command mapping
│   └── scripts/
│       ├── jj-guard.sh                  # Git command interceptor
│       └── cleanup-workspace.sh         # Workspace cleanup helper
│
├── claude-code/                         # CLAUDE CODE ADAPTER
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── hooks/
│   │   └── hooks.json
│   ├── scripts/
│   │   └── jj-guard.sh -> ../../shared/scripts/jj-guard.sh
│   ├── skills/
│   │   └── jj-guide -> ../../shared/skills/jj-guide
│   ├── commands/
│   │   ├── jj-commit.md
│   │   └── develop.md
│   └── agents/
│       └── jj-doctor.md
│
├── codex/                               # CODEX ADAPTER
│   ├── skills/
│   │   └── jj-guide -> ../../shared/skills/jj-guide
│   ├── rules/
│   │   └── jj-skipper.rules            # execpolicy: blocks git commands
│   ├── agents/
│   │   └── AGENTS.md
│   └── install.sh
│
├── README.md
├── LICENSE                              # MIT
└── CHANGELOG.md
```

### Vendoring Regime

**1. Claude Code (marketplace)**
```bash
/plugin marketplace add plasticbeachllc/jj-skipper
/plugin install jj-skipper@jj-skipper
```
Marketplace pulls from GitHub. Symlinks in `claude-code/` are followed during cache copy (confirmed: CC docs state "use symlinks, which are followed during copying"). `${CLAUDE_PLUGIN_ROOT}` resolves to `claude-code/`.

**2. Codex (install script)**
```bash
git clone https://github.com/plasticbeachllc/jj-skipper.git
./jj-skipper/codex/install.sh
```
Symlinks `shared/skills/*` into `${CODEX_HOME:-~/.codex}/skills/`. Copies `jj-skipper.rules` into `~/.codex/rules/` (execpolicy guard that blocks all `git` commands with `decision = "forbidden"`). Falls back to copy for skills if symlinks not supported.

**3. Per-project instructions (both platforms)**
Add to CLAUDE.md / AGENTS.md (or set in Claude user preferences):
```markdown
## Version Control

This project uses jj (Jujutsu) exclusively for version control. The repo is colocated
(both .jj/ and .git/ exist) but all VCS operations MUST use jj commands, never git.

Use the jj-guide skill for command reference. If VCS state gets tangled, invoke jj-doctor.

Key rules:
- Never run git commands directly (use jj equivalents)
- After `jj commit`, the commit with content is @- (parent), not @ (empty working copy)
- Use `jj git push -c @-` for auto-bookmark PR branches
- Use `jj bookmark set <name> -r @-` then `jj git push -b <name>` for named branches like main
```

---

### Component Specifications

Each component below includes a strong outline showing structure and key content. These outlines are designed to be iterated to final copy by an agent.

---

#### Shared: `jj-guard.sh`

**Purpose:** Block git mutations in jj repos. Dual-mode: reads CC hook JSON from stdin, also works standalone.

**Behavior:**
1. Read input (CC hook JSON or CLI argument)
2. Allow if: empty command, not starting with `git `, no `.jj/` in directory tree
3. Deny with: git→jj mapping, reference to jj-guide skill and jj-doctor agent
4. Escape hatch: `:;git` prefix

**Reference implementation:**

```bash
#!/usr/bin/env bash
# jj-guard: Blocks git mutations in jj-managed repositories.
# Inspired by kawaz/claude-plugin-jj and kalupa/jj-workflow.
set -euo pipefail

deny() {
  local reason="$1"
  if command -v jq &>/dev/null; then
    jq -cn --arg reason "$reason" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      }
    }'
  else
    echo "BLOCKED: $reason" >&2
  fi
  exit 1
}

# Read CC hook input; handle non-CC invocation gracefully
input=""
[ ! -t 0 ] && input=$(cat)

if [ -n "$input" ] && command -v jq &>/dev/null; then
  command=$(jq -r '.tool_input.command // empty' <<< "$input")
else
  command="${1:-}"
fi

[[ -z "$command" ]] && exit 0
[[ "$command" != git\ * ]] && exit 0

# Walk up to find .jj
check_dir="$(pwd)"
found_jj=false
while [[ "$check_dir" != "/" ]]; do
  [[ -d "$check_dir/.jj" ]] && found_jj=true && break
  check_dir="$(dirname "$check_dir")"
done
[[ "$found_jj" == false ]] && exit 0

git_subcmd=$(echo "$command" | awk '{print $2}')

case "$git_subcmd" in
  status)      jj_equiv="jj st" ;;
  diff)        jj_equiv="jj diff" ;;
  log)         jj_equiv="jj log" ;;
  show)        jj_equiv="jj show" ;;
  blame)       jj_equiv="jj file annotate" ;;
  add)         jj_equiv="(not needed — jj tracks all changes)" ;;
  commit)      jj_equiv="jj commit -m 'msg'" ;;
  push)        jj_equiv="jj git push" ;;
  pull)        jj_equiv="jj git fetch && jj rebase -d main" ;;
  fetch)       jj_equiv="jj git fetch" ;;
  clone)       jj_equiv="jj git clone" ;;
  init)        jj_equiv="jj git init" ;;
  checkout|switch) jj_equiv="jj new <rev> or jj edit <rev>" ;;
  branch)      jj_equiv="jj bookmark" ;;
  merge)       jj_equiv="jj new <rev1> <rev2>" ;;
  rebase)      jj_equiv="jj rebase" ;;
  reset)       jj_equiv="jj restore or jj abandon" ;;
  stash)       jj_equiv="(not needed — jj new)" ;;
  cherry-pick) jj_equiv="jj duplicate" ;;
  revert)      jj_equiv="jj revert" ;;
  tag)         jj_equiv="jj tag" ;;
  worktree)    jj_equiv="jj workspace" ;;
  *)           jj_equiv="(check jj --help)" ;;
esac

deny "This is a jj repository. Use jj instead of git.
  git $git_subcmd → $jj_equiv
Refer to jj:jj-guide for command reference.
For complex VCS issues, invoke jj-doctor.
For git-only operations (submodule, lfs), prefix with :;git"
```

---

#### Shared: `jj-guide` SKILL.md

**Purpose:** Core jj knowledge for daily agent use. Identical for both platforms.

**Outline (iterate to final copy):**

```markdown
---
name: jj-guide
description: "REQUIRED for any VCS operation in jj repositories (.jj/ directory present).
Activate on: commit, push, pull, status, diff, log, branch, PR, merge, rebase, stash,
or any version control task. In jj repos: use jj commands exclusively, never git."
---

# jj Guide for AI Agents

## Critical Rules
- NEVER run git commands in a jj repo. Use jj equivalents.
- ALWAYS use -m flags. Without -m, editors open and hang.
- NEVER use -i flags. Interactive TUI hangs in agent environments.
- After `jj commit -m "msg"`: content is @- (parent). New @ is empty.
  Target @- for bookmarks and pushes.
- Use change IDs (letters, e.g. nmwwolux) over commit IDs (hex). Stable across rewrites.

## Mental Model
- Working copy IS a commit (@). Edits auto-amend into @.
- No staging area. No git add. All changes tracked.
- Commits are mutable until pushed.
- Conflicts stored in commits — resolve later, not now.
- Operation log records everything. `jj undo` reverts any operation.

## Bookmark Rules of Thumb

### Named bookmark (main, long-lived branches):
    jj commit -m "message"
    jj bookmark set main -r @-          # @- has the content!
    jj git push -b main

### Auto-bookmark (PR feature branches):
    jj commit -m "feat: add thing"
    jj git push -c @-                   # auto-creates push-<changeid>

### Fix a bookmark that's pointing at the wrong commit:
    jj bookmark set <name> -r <change-id>
    jj git push -b <name>

## Common Workflows

### Start new work
    jj new main -m "feat: description"
    # edit files (auto-tracked)
    jj st

### Commit and continue
    jj commit -m "feat: description"
    # @ is now empty, ready for next task

### Amend current change
    jj describe -m "better message"     # message only
    jj squash                           # fold @ into parent

### PR lifecycle
    # Create:
    jj new main -m "feat: add feature"
    # ... work ...
    jj commit -m "feat: add feature"
    jj git push -c @-                   # auto-bookmark + push

    # Address review (rewrite):
    jj edit <change-id>                 # make it working copy
    # ... fix ...
    jj new                              # done editing
    jj git push                         # auto force-push

    # Address review (additive):
    jj new <bookmark-tip>
    # ... fix ...
    jj commit -m "address review"
    jj bookmark set <name> -r @-
    jj git push -b <name>

### Fetch and rebase
    jj git fetch
    jj rebase -d main

## Git → jj Quick Reference
[Table: status, diff, log, add+commit, amend, push, fetch, checkout,
 branch, stash, rebase, cherry-pick, blame, worktree]
[Full mapping: see references/git-to-jj.md]

## Non-Interactive Agent Operations
[Selective commit by filesets]
[Selective squash by filesets]
[Selective split by filesets]
[Fileset patterns: glob, root, operators (|, &, ~)]

## Workspace Model
- Colocated: both .jj/ and .git/ exist
- Claude Code: WorktreeCreate hook → jj workspace add (shared commit graph)
- Codex: built-in worktree toggle uses git worktrees (jj auto-imports)
- Both work. jj workspace = shared commits + isolated working copy.

## Revset Quick Reference
[Table: @, @-, trunk(), mine(), bookmarks(), ::, ..]

## Common Pitfalls
1. Bookmarks don't auto-advance after commit. Use -r @- explicitly.
2. @ after jj commit is empty. Content is in @-.
3. jj new ≠ git commit. jj new = new empty change. jj commit = finalize @.
4. :: is DAG range, .. is set difference.
5. Empty commits are normal — they're "ready to work here."

## Troubleshooting
- Undo anything: `jj undo`
- See operation history: `jj op log`
- Restore to past state: `jj op restore <op-id>`
- Complex issues (Claude Code): invoke jj-doctor
- Complex issues (Codex): describe problem, check jj op log, try jj undo
```

---

#### Claude Code: `hooks.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/jj-guard.sh"
          }
        ]
      }
    ],
    "WorktreeCreate": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "jj workspace add \"$WORKTREE_NAME\" --revision @ && cd \"$WORKTREE_NAME\" && jj new @ && echo \"$(pwd)\""
          }
        ]
      }
    ],
    "WorktreeRemove": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "jj workspace forget \"$WORKTREE_NAME\" 2>/dev/null || true; rm -rf \"$WORKTREE_NAME\" 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

---

#### Claude Code: `/jj-commit` Command Outline

```markdown
---
name: jj-commit
description: Create focused jj commits with selective file grouping
---

1. Run `jj st`, group changed files by category
   (source, config, docs, tests, other)
2. Single category → auto-select, confirm
   Multiple → present options, let user choose
3. If `.claude/jj-pre-commit.sh` exists and executable → run, block on failure
4. jj commit -m "<message>" <selected-files>
5. Show: jj log -r '@ | @-'
6. Remind: "Content is now in @-. To push:
   - Named bookmark: jj bookmark set <name> -r @- && jj git push -b <name>
   - Auto-bookmark: jj git push -c @-"
```

---

#### Claude Code: `/develop` Command Outline

```markdown
---
name: develop
description: Enter isolated jj workspace for parallel work
---

1. Generate name from task: claude-<feature>-YYYYMMDD
2. Call EnterWorktree tool (triggers WorktreeCreate hook → jj workspace add)
3. Explain: commits shared across workspaces, working copy isolated, no merge needed
4. On completion: jj workspace forget <name>, delete directory
```

---

#### Claude Code: `jj-doctor` Sub-Agent Outline

```markdown
---
model: sonnet
color: red
tools: [Read, Bash, Grep, Glob, WebFetch, WebSearch]
description: "Expert debugger for jj VCS issues. Invoke when commits are lost,
bookmarks wrong, conflicts stuck, or anything VCS-related has gone sideways."
---

# jj-doctor

## Persona
Meticulous debugger. Never guesses. Investigates actual state first.
Explains root cause clearly. Exact commands. Always offers jj undo as safety net.

## Diagnostic Protocol (always follow)
1. GATHER: jj st, jj log -r 'all()', jj op log --limit 20
2. CLASSIFY: which problem category?
3. EXPLAIN: root cause in plain language
4. FIX: exact commands, what each does
5. SAFETY: "If wrong, run jj undo to revert"

## Problem Categories

| Category | Symptoms | Fix Pattern |
|----------|----------|-------------|
| Lost changes | Files/commit gone | jj op log → jj op restore |
| Divergent changes | Same change ID, multiple commits | jj abandon or jj metaedit --update-change-id |
| Bookmark behind | Push wrong commit | jj bookmark set <n> -r <correct> |
| Bookmark conflict | Local/remote disagree | jj bookmark list --all, resolve |
| Merge conflicts | × in jj log | Edit files, jj squash into conflicted |
| Stuck rebase | Conflict chain | Resolve root, descendants auto-update |
| Wrong commit edited | Modified immutable | jj undo |
| Stale workspace | Out of sync | jj workspace update-stale |
| Git sync issues | Push fails | jj git import/export, :;git |
| Orphaned commits | Not in default log | jj log -r 'all()', jj new <id> |

## Deep Reference (full content in final copy)
- Revset expression language (all operators, functions, aliases)
- Fileset expression language (glob, root, operators)
- Template language (Commit methods, String, List, etc.)
- Rebase matrix: -r/-s/-b source × -o/-A/-B destination
- Non-interactive split: filesets + manual staged edit pattern
- Signing config: behavior (drop/keep/own/force), sign-on-push
- Config priority: built-in → user → repo → workspace → CLI
- Op log forensics: snapshot recovery, --at-op time travel
- jj absorb, jj parallelize, jj fix
```

---

#### Codex: `jj-skipper.rules`

**Purpose:** Programmatic guard for Codex. Blocks all `git` commands via execpolicy `forbidden` decision.

```starlark
# jj-skipper: Block git commands in jj repositories.
# Installed to ~/.codex/rules/jj-skipper.rules

prefix_rule(
    pattern = ["git"],
    decision = "forbidden",
    justification = "This is a jj repository. Use jj commands instead. See the jj-guide skill for mappings. For git-only ops (submodule, lfs), temporarily remove this rule.",
    match = [
        "git status",
        "git commit -m 'test'",
        "git push origin main",
        "git checkout -b feature",
        "git diff",
        "git log",
        "git add .",
        "git stash",
    ],
    not_match = [
        "jj git push",
        "jj st",
        "jj commit -m 'test'",
        "jj log",
    ],
)
```

Note: this blocks ALL `git *` commands globally when installed. The `not_match` examples confirm that `jj git push` (first token `jj`) is not caught. For repos that still use plain git, the user would need to remove or disable this rule. The `install.sh` should warn about this.

---

#### Codex: `install.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME/skills"
RULES_DIR="$CODEX_HOME/rules"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_SKILLS="$SCRIPT_DIR/../shared/skills"
RULES_SRC="$SCRIPT_DIR/rules/jj-skipper.rules"

# Install skills
mkdir -p "$SKILLS_DIR"

for skill_dir in "$SHARED_SKILLS"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$skill_name"
  [ -L "$target" ] || [ -d "$target" ] && rm -rf "$target"
  if ln -s "$(cd "$skill_dir" && pwd)" "$target" 2>/dev/null; then
    echo "Linked skill $skill_name → $target"
  else
    cp -r "$skill_dir" "$target"
    echo "Copied skill $skill_name → $target"
  fi
done

# Install execpolicy rules
mkdir -p "$RULES_DIR"
cp "$RULES_SRC" "$RULES_DIR/jj-skipper.rules"
echo "Installed execpolicy rules → $RULES_DIR/jj-skipper.rules"

echo ""
echo "jj-skipper installed for Codex."
echo ""
echo "  Skills: $SKILLS_DIR/jj-guide"
echo "  Rules:  $RULES_DIR/jj-skipper.rules (blocks all 'git' commands)"
echo ""
echo "  ⚠️  The execpolicy rule blocks 'git' commands GLOBALLY."
echo "     For repos still using plain git, remove or disable the rule:"
echo "     rm $RULES_DIR/jj-skipper.rules"
echo ""
echo "Restart Codex to pick up changes."
```

---

## Risks & Mitigations

### Risk 1: Agent falls back to git despite guard

**Likelihood:** Low (both platforms now have programmatic guards). **Impact:** In colocated mode, git mutations work but create messy operation history. No data loss — jj imports on next command.

**Mitigation:** CC: PreToolUse hook blocks before execution. Codex: `execpolicy` rule with `decision = "forbidden"` blocks all `git` commands. Both: jj auto-imports any mutations that slip through. Fallback: `git` PATH wrapper.

### Risk 2: Bookmark confusion

**Likelihood:** High — we hit this ourselves immediately. **Impact:** Push empty commit, bookmark on wrong revision.

**Mitigation:** Skill has explicit rules of thumb with examples. Default: `jj git push -c @-`. `/jj-commit` reminds about bookmarks. jj-doctor fixes stale bookmarks.

### Risk 3: Codex worktree + jj coexistence

**Likelihood:** Medium. **Impact:** Codex creates git worktrees; jj may not see workspace state cleanly.

**Mitigation:** Colocated mode means git worktrees work. jj auto-imports. Test both paths on Keel.

### Risk 4: Codex skill triggering

**Likelihood:** Medium. **Impact:** Codex doesn't load jj-guide for a VCS operation.

**Mitigation:** Even if the skill doesn't trigger, the `execpolicy` rule blocks `git` commands with a justification message pointing to jj-guide. This forces the agent to reconsider. Aggressive skill description + AGENTS.md as secondary layers. Tune description based on behavior.

### Risk 5: execpolicy rule blocks git globally

**Likelihood:** Certain — the rule applies to ALL Codex sessions, not just jj repos.

**Impact:** Users who work in both jj and plain-git repos will have git blocked everywhere.

**Mitigation:** `install.sh` warns prominently. README documents removal: `rm ~/.codex/rules/jj-skipper.rules`. Future: investigate per-repo execpolicy scoping if Codex adds it.

### Risk 6: jj version incompatibility

**Likelihood:** Medium. **Impact:** Commands fail.

**Mitigation:** Pin version. Stable commands only. jj-doctor WebSearches.

### Risk 7: Symlink packaging

**Likelihood:** Low — confirmed by CC docs. **Impact:** Shared content missing.

**Mitigation:** CC docs: "use symlinks (which are followed during copying)." Codex install.sh falls back to copy.

---

## Implementation Plan

### Phase 0: Prerequisites
- [ ] Install jj
- [ ] Colocate Keel: `cd ~/worktable/keel && jj git init --colocate`
- [ ] Verify: `jj st` + both `.jj/` and `.git/` exist
- [ ] Configure jj user identity
- [ ] Init jj-skipper repo, push to `plasticbeachllc/jj-skipper`
- [ ] Add jj-first policy to Keel's CLAUDE.md / AGENTS.md

### Phase 1: Shared Layer
- [ ] `shared/scripts/jj-guard.sh`
- [ ] `shared/scripts/cleanup-workspace.sh`
- [ ] Test: guard blocks `git status`, allows `jj st`, allows `:;git status`

### Phase 2: Shared Skill
- [ ] `shared/skills/jj-guide/SKILL.md` — iterate outline to final copy
- [ ] `shared/skills/jj-guide/references/git-to-jj.md`

### Phase 3: Claude Code Adapter
- [ ] `plugin.json`, `hooks.json`
- [ ] Symlinks to shared skills + scripts
- [ ] `/jj-commit` and `/develop` commands
- [ ] Test: local install, hooks fire, skills load, symlinks resolve

### Phase 4: Codex Adapter
- [ ] `jj-skipper.rules` (execpolicy guard — blocks all `git` commands)
- [ ] `install.sh` (skills + rules installation with global-scope warning)
- [ ] Symlinks to shared skills
- [ ] `openai.yaml`
- [ ] Test: install, `codex execpolicy check -- git status` returns `forbidden`
- [ ] Test: `codex execpolicy check -- jj st` returns no match (allowed)
- [ ] Test: Codex discovers skill, triggers on VCS ops

### Phase 5: jj-doctor
- [ ] Iterate outline to full agent definition
- [ ] Deep reference content (revset, fileset, template, rebase matrix, etc.)

### Phase 6: Packaging & Docs
- [ ] README, LICENSE, CHANGELOG
- [ ] Verify marketplace install end-to-end

### Phase 7: Integration Testing on Keel
- [ ] **CC:** guard blocks git, worktree→workspace, skill activates, PR loop, commands, doctor
- [ ] **Codex:** execpolicy blocks git, skill discovered, jj used for commits/push, worktree toggle
- [ ] **Cross-platform:** same skill, same bookmark patterns, PR handoff between agents

### Phase 8: Iteration
- [ ] Fix Phase 7 issues
- [ ] `git` PATH wrapper if both guards prove insufficient
- [ ] Investigate per-repo execpolicy scoping (if Codex adds it)
- [ ] Marketplace publication
