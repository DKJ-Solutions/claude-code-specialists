# `specialists/scripts/` — shared workflow scripts (mirror for consumers)

This folder is the **single source of truth** home of the repo-agnostic workflow scripts, so that
consumers (life-hub, smartwatchbanden, …) no longer duplicate them per repo. The rationale is in
[issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

**The model — mirror, not a move:**
- The **workshop root copy is the canonical, tested source** (`scripts/…` in this repo). That is where
  development and testing happen; CI runs it from a bare checkout.
- The copy **here in the plugin is an LF-identical mirror** — that is what a **consumer** runs
  (via a skill). The workshop itself keeps using its root copy.
- A **drift lint** (`check-plugin-integrity.ps1`) guards that mirror and source stay equal, and the
  generator `scripts/sync/build-shared-scripts.ps1` updates the mirror. This way the mirror inherits the
  root copy's test coverage without our having to run it live in the workshop (which is impossible:
  the workshop consumes the last-pushed plugin, not your branch).

## Status

This table mirrors the full registry in
[`scripts/lib/shared-scripts-lib.ps1`](../../../scripts/lib/shared-scripts-lib.ps1)'s
`Get-SharedScriptPairs` -- one row per registered pair, so this is the **complete** shared set, not
a skill-only subset. Not every pair is reached through a skill, though: `check-roster-sync` /
`check-script-contract` are read-only checks invoked by a SessionStart hook instead, and
`check-report-lib` / `native-capture-lib` are dot-sourced libs with no standalone entry point of
their own -- their **Skill** cell says so rather than linking one, so their absence from a skill
link is not an oversight.

| Script | Status | Skill |
|---|---|---|
| `release/fold-changelog-entry.ps1` | **Shared** (mirror active) | [`fold-changelog`](../skills/fold-changelog/SKILL.md) |
| `release/open-pr.ps1` | **Shared** (mirror active; lint gate via `Get-LintScript` in `repo-config`) | [`open-pr`](../skills/open-pr/SKILL.md) |
| `task/new-branch.ps1` | **Shared** (mirror active; creates the branch AND writes both `branch/` files plus the reference templates, in one move -- a branch is never entry-less) | [`new-branch`](../skills/new-branch/SKILL.md) |
| `task/park-branch.ps1` | **Shared** (mirror active; commits all outstanding work + `git push -u` -- no PR, no live action; self-contained, no repo-owned config) | [`park`](../skills/park/SKILL.md) |
| `sync/check-roster-sync.ps1` | **Shared** (mirror active; read-only roster/lens drift check) | none -- invoked by the `roster-sessioncheck` SessionStart hook |
| `sync/check-script-contract.ps1` | **Shared** (mirror active; read-only script-contract drift check) | none -- invoked by the `script-contract-sessioncheck` SessionStart hook |
| `lib/check-report-lib.ps1` | **Shared** (mirror active; dot-sourced `[OK]`/`[INFO]`/`[ERROR]` report helper lib, no standalone entry point) | none -- consumed by the sync/check scripts |
| `lib/native-capture-lib.ps1` | **Shared** (mirror active; dot-sourced `Invoke-NativeCapture` helper lib -- the stderr-safe native-command wrapper -- no standalone entry point) | none -- consumed by every native-command call site (release/task scripts) |
| `lib/park-lib.ps1` | **Shared** (mirror active; dot-sourced `Invoke-GitPark` -- the one stage/commit/push behind both parking entry points, with the scope choosing the pathspec and the commit words together; no standalone entry point) | none -- consumed by `task/park-branch.ps1` and `task/new-branch.ps1 -Park` |

## How the mirror works

1. **Dual-context repo root.** A shared script resolves its repo root as
   `${CLAUDE_PROJECT_DIR}` (for a consumer running the mirror) or the git root (workshop root /
   outside a session). This way the same file works in both locations and the mirror stays byte-identical.
2. **Repo data stays local.** The script reads its repo-specific bit from the **consumer's
   root**: `scripts/repo-config.ps1` (repo name) and `scripts/lib/branch-info.ps1`
   (branch/type derivation). `${CLAUDE_PLUGIN_ROOT}` resolves only within plugin-owned components,
   so that injection runs via `${CLAUDE_PROJECT_DIR}`, not via the plugin root.
3. **The consumer invokes via a skill** (`/fold-changelog`) that runs the script with
   `${CLAUDE_PLUGIN_ROOT}/scripts/release/…`. A skill is the only docs-confirmed mechanism
   that both a human and Claude can invoke (`bin/` is only on the Bash tool's PATH and is
   not directly invokable by a human).

To add a script to the shared set: register the pair (source → mirror) in
`scripts/lib/shared-scripts-lib.ps1`, run `scripts/sync/build-shared-scripts.ps1`, and add a skill if
needed.

## What deliberately stays in the consumer's root (cannot move here)

- Everything **CI** invokes from a bare checkout without a plugin cache (the lint gate, the test suites
  and their libs). CI does not see the plugin cache.
- **`branch-info.ps1` cannot move.** It is riveted to the root by two independent callers:
  `release-lib.ps1` dot-sources it (for the branch types, `Get-BranchTypes`) and runs in
  **CI** from a bare checkout — and the root scripts dot-source it. As long as `release-lib` depends on
  `branch-info`, moving it would break the CI gate.
- **`repo-config.ps1`** is by definition repo data (repo name, blob URL) and belongs locally per repo.
  The `specialists-init` bootstrap places `repo-config.ps1` + `branch-info.ps1` as a `VUL-IN` scaffold,
  so that a clean consumer does not crash the shared skills on a missing file; the scripts moreover
  pre-flight on it ([#86](https://github.com/DaveKJohn/claude-code-specialists/issues/86)).

## Precedent

The plugin already runs `hooks/connector-sessioncheck.ps1` via `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}`
in every consumer, without registration in the consumer's `settings.json`. That hook mechanism is proven;
the shared-scripts mirror + skill above extends that same SSOT principle to standalone-invokable
workflow scripts.
