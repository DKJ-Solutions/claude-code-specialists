# `workflow-davekjohn/scripts/` — the shared workflow scripts (mirror for consumers)

This folder is what a **consumer** of this workflow actually runs. It is a **mirror**, not the source:
the canonical copy of every script here lives in [`scripts/`](../../../../scripts/) at the root of this
repository, and that is where development and testing happen. The point of the arrangement is that
consumers (life-hub, smartwatchbanden, …) no longer keep a duplicate of these scripts per repo. The
rationale is in [issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

**The model — mirror, not a move:**
- The **workshop root copy is the canonical, tested source** (`scripts/…` in this repo). CI runs it from
  a bare checkout.
- The copy **here in the plugin is an LF-identical mirror** — that is what a consumer runs, via a skill.
  The workshop itself keeps using its root copy.
- A **drift lint** (`check-plugin-integrity.ps1`, check 8) guards that mirror and source stay equal, and
  the generator `scripts/sync/build-shared-scripts.ps1` updates the mirror. This way the mirror inherits
  the root copy's test coverage without our having to run it live in the workshop (which is impossible:
  the workshop consumes the last-pushed plugin, not your branch).

**Do not edit a file in this folder.** A change lands in the root source first and travels here through
the generator; the lint reports a hand edit as drift.

## The shared set

The registry is `Get-SharedScriptPairs` in
[`scripts/lib/shared-scripts-lib.ps1`](../../../../scripts/lib/shared-scripts-lib.ps1), and it is the
only place that knows the answer. It holds **23 pairs**, and they do **not** all land here: the shared
set spans three plugins, because a script travels to whichever plugin owns the surface that calls it.

| where the mirror lands | pairs | why there |
|---|---|---|
| `workflow-davekjohn` (this folder) | 20 | the branch/PR/release way of working, which is what this plugin *is* |
| `team-alpha` | 2 | `sync/check-roster-sync.ps1` and `lib/check-report-lib.ps1` — the roster check belongs to the core team, since the roster does |
| `workflow-default` | 1 | `lib/check-report-lib.ps1` again — one source, three destinations, because all three plugins report in the same `[OK]`/`[INFO]`/`[ERROR]` shape |

**The 20 that land here**, one row per registered pair — the complete set for this plugin. Not every one
is reached through a skill, and the **Skill** cell says so rather than linking one, so an absent link is
a fact rather than an oversight:

| Script | What it is | Skill |
|---|---|---|
| `task/new-branch.ps1` | creates the branch AND writes both `workflow-davekjohn/branch/` files plus the reference templates, in one move — a branch is never entry-less | [`new-branch`](../skills/new-branch/SKILL.md) |
| `task/park-branch.ps1` | commits all outstanding work + `git push -u` — no PR, no live action | [`park`](../skills/park/SKILL.md) |
| `task/adopt-config.ps1` | reads the config blueprint and places or proposes each seam answer | [`adopt-config`](../skills/adopt-config/SKILL.md) |
| `release/open-pr.ps1` | the gates, the push and the PR; lint gate via `Get-LintScript` in `repo-config` | [`open-pr`](../skills/open-pr/SKILL.md) |
| `release/ship-pr.ps1` | open → wait for CI → merge → fold, in one motion | [`ship-pr`](../skills/ship-pr/SKILL.md) |
| `release/verify-resolved-issues.ps1` | checks that a merged PR closed what it declared | [`ship-pr`](../skills/ship-pr/SKILL.md) |
| `release/fold-changelog-entry.ps1` | folds the entry into `CHANGELOG.md` at its ranked position and resets both branch files | [`fold-changelog`](../skills/fold-changelog/SKILL.md) |
| `release/cut-release.ps1` | the lockstep version bump, the release notes and the tag | [`cut-release`](../skills/cut-release/SKILL.md) |
| `release/new-internal-note.ps1` | the tier-1 note's skeleton, which needs the development notes as input | [`cut-release`](../skills/cut-release/SKILL.md) |
| `maintenance/fix-mojibake.ps1` | repairs encoding damage in the markdown the repo names | [`fix-mojibake`](../skills/fix-mojibake/SKILL.md) |
| `sync/check-script-contract.ps1` | read-only script-contract drift check | none — invoked by the `script-contract-sessioncheck` SessionStart hook |
| `lib/release-lib.ps1` | the pure release logic: version bump, changelog transformation, notes construction, `Test-ReleaseBumpEarned` | none — dot-sourced lib |
| `lib/entry-scaffold-lib.ps1` | the one definition of the entry format, read by the script that writes it and the gates that refuse it | none — dot-sourced lib |
| `lib/plugin-tree-lib.ps1` | which plugins this repo publishes and where each folder sits | none — dot-sourced lib |
| `lib/script-contract-lib.ps1` | the contract registry the check above reads | none — dot-sourced lib |
| `lib/pr-body-lib.ps1` | composes and refreshes the PR body from the entry | none — dot-sourced lib |
| `lib/pr-issues-lib.ps1` | reads the issues a PR declares it closes | none — dot-sourced lib |
| `lib/park-lib.ps1` | `Invoke-GitPark` — the one stage/commit/push behind both parking entry points | none — dot-sourced lib |
| `lib/native-capture-lib.ps1` | `Invoke-NativeCapture`, the stderr-safe native-command wrapper | none — dot-sourced lib |
| `lib/check-report-lib.ps1` | the `[OK]`/`[INFO]`/`[ERROR]` report helper | none — dot-sourced lib |

## How the mirror works

1. **Dual-context repo root.** A shared script resolves its repo root as `${CLAUDE_PROJECT_DIR}` (for a
   consumer running the mirror) or the git root (workshop root / outside a session). This way the same
   file works in both locations and the mirror stays byte-identical.
2. **Repo data stays local.** The script reads its repo-specific bit from the **consumer's root**:
   `scripts/repo-config.ps1` (the seam) and `scripts/lib/branch-info.ps1` (branch/type derivation).
   `${CLAUDE_PLUGIN_ROOT}` resolves only within plugin-owned components, so that injection runs via
   `${CLAUDE_PROJECT_DIR}`, not via the plugin root.
3. **The consumer invokes via a skill** (`/fold-changelog`) that runs the script with
   `${CLAUDE_PLUGIN_ROOT}/scripts/release/…`. A skill is the only docs-confirmed mechanism that both a
   human and Claude can invoke (`bin/` is only on the Bash tool's PATH and is not directly invokable by
   a human).

To add a script to the shared set: register the pair (source → mirror) in
`scripts/lib/shared-scripts-lib.ps1`, run `scripts/sync/build-shared-scripts.ps1`, and add a skill if
needed.

## What deliberately stays in the consumer's root (cannot move here)

- Everything **CI** invokes from a bare checkout without a plugin cache (the lint gate, the test suites
  and their libs). CI does not see the plugin cache.
- **`branch-info.ps1` cannot move.** It is riveted to the root by two independent callers:
  `release-lib.ps1` dot-sources it (for the branch types, `Get-BranchTypes`) and runs in **CI** from a
  bare checkout — and the root scripts dot-source it. As long as `release-lib` depends on `branch-info`,
  moving it would break the CI gate.
- **`repo-config.ps1`** is by definition repo data (repo name, blob URL, the release seam) and belongs
  locally per repo. The `specialists-init` bootstrap places `repo-config.ps1` + `branch-info.ps1` as a
  `VUL-IN` scaffold, so that a clean consumer does not crash the shared skills on a missing file; the
  scripts moreover pre-flight on it
  ([#86](https://github.com/DaveKJohn/claude-code-specialists/issues/86)).

## Precedent

The plugin runs `hooks/connector-sessioncheck.ps1` via `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}` in
every repo that enables **this** plugin, without registration in the consumer's `settings.json`. (It ran
in every consumer until August 8, 2026, when it moved out of the core team along with the rest of this
way of working — see the [connectors README](../../../../connectors/README.md#the-session-check-automatic).)
That hook mechanism is proven; the shared-scripts mirror + skill above extends that same SSOT principle
to standalone-invokable workflow scripts.
