---
id: 18
group: 04
---

# Tycho 🧪 · claude-code-specialists addendum

> Repo-lens (claude-code-specialists) accompanying the portable playbook in the `team-alpha` plugin (`plugins/team-alpha/manuals/04-18-manual.md`). This file does not describe the craft, but what Tycho does in this repo.

A test engineer (SDET) does the same thing everywhere — write and maintain automated tests, guard
against regressions, secure reliability with a suite instead of manual checking. **What is
repo-specific in claude-code-specialists is not that Tycho tests, but what there is to test here.**

### What there is to test here

The testable surface of this repo is the **PowerShell scripts** in `scripts/**` — in particular the
lint gate `check-plugin-integrity.ps1` and the drift check `check-consumer-drift.ps1`, which make
decisions (valid/invalid, MISSING/IDENTICAL/DRIFTED) that can break silently, and the pure release
logic in `release-lib.ps1` (version bump, CHANGELOG transformation, release-notes assembly).

### Honest status & Tycho's role

- **The suite has grown well past its first member.** It started with
  [`scripts/tests/release-lib.tests.ps1`](../../../scripts/tests/release-lib.tests.ps1) —
  dependency-free (no Pester), dot-sources `release-lib.ps1` and asserts the version bump + CHANGELOG
  transformation, exit 1 on the first failure (usable in a CI gate) — and that dependency-free,
  exit-1-on-first-failure style now runs across the suite under `scripts/tests/`, which covers most
  of what Sylvester's lens lists: the lint gate (`check-plugin-integrity.tests.ps1`), the shared
  agent-def blocks (`agent-shared.tests.ps1`), the branch/changelog/release chain
  (`branch-info.tests.ps1`, `new-branch.tests.ps1`, `fold-changelog.tests.ps1`,
  `cut-release-guardrail.tests.ps1`, `park-branch.tests.ps1`), the connectors + roster machinery
  (`connectors.tests.ps1`, `roster-sync.tests.ps1`, `sync-roster.tests.ps1`), the shared-scripts
  mirror + contract (`shared-scripts.tests.ps1`, `script-contract.tests.ps1`), the bootstrap drift
  check (`bootstrap-drift.tests.ps1`), the repo-config helper (`repo-config.tests.ps1`), and the test
  gate itself (`test-suite-gate.tests.ps1` — the runner all three callers share, which had only
  wiring-level coverage until it became a parallel scheduler on August 7, 2026). Tycho
  does not need to re-derive that list from memory: `Get-ChildItem scripts/tests/*.tests.ps1` gives
  the current count and membership directly, which is deliberately how this file avoids hardcoding a
  number that would drift with every new suite.
- **One committed member is deliberately not a test: `scripts/tests/fresh-consumer.measure.ps1`.** The
  `.measure.ps1` suffix keeps it out of CI's `scripts/tests/*.tests.ps1` glob on purpose — it reports
  numbers for a human to read and asserts nothing. It builds a synthetic consumer in the state a real
  one is in right after enabling the plugin (its own `CLAUDE.md`, no lenses, no repo-config, no
  orchestrator import) and runs the three `SessionStart` hooks against it the way the harness does,
  optionally after `specialists-init`'s bootstrap. It is committed rather than run ad hoc for one
  reason: **the point is that round two is comparable to round one**, and a measurement done by hand
  cannot be repeated identically, so its before/after could not be trusted. First run, July 29, 2026:
  **44 `[ERROR]` lines before the bootstrap and 21 after a successful one, with zero lines naming
  `specialists-init` in either state.** Turning the install/uninstall round-trip into a genuinely
  asserting suite is the follow-up this harness exists to make possible — a measurement first, so the
  assertions encode observed behaviour instead of assumed behaviour.
- Tycho's role here is now mostly **keeping the suite honest as the scripts evolve**: add a test the
  moment a script grows a new decision path or a fixture (a valid and a deliberately broken plugin
  directory) the lint gate must still catch, and close any genuine gap Victor flags during review —
  not starting the suite from scratch.
- He works together with [Sylvester #15](05-15-extension.md) (who owns the scripts) and
  [Victor #19](06-19-extension.md) (who flags a missing test during review).

In short: the **how** (automated tests, regression guarding) is portable; the **what** (the
PowerShell scripts as the test surface, and building out a suite once the lint gate warrants it)
belongs to this repo.
