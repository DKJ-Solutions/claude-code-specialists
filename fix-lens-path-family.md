### Lens path: the family segment is a constant, and every reader shares it · Fix · 2026-07-25

`specialists-init` and the roster check disagreed about **where a repo lens lives**: one wrote a
derived path, the other read a hardcoded one, and they only lined up by coincidence.
`bootstrap.ps1` derived the family segment from the install path, which in the plugin-cache layout
(`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`) yields the **marketplace name** — so a
repo installed through `specialists@davekjohns-workshop` got its lenses in
`.claude/plugins/davekjohns-workshop/specialists/`, where `check-roster-sync.ps1` never looked. In
`djcylow-react` that produced **30 errors of which 24 were false**: 12 perfectly good lenses, each
counted twice (missing lens + missing roster row). Worse than a plain miss — the fix the report
suggested would have left the repo with two copies of every lens on two paths, with the `@`-import
in `CLAUDE.md` still pointing at the wrong one.

**One source, used by writers and readers alike.** `scripts/lib/check-report-lib.ps1` (mirrored into
the plugin) gains two helpers:

- **`Get-LensFamily`** — the family segment as a **constant** (`claude-specialists`). It is a
  property of the plugin family, not of the marketplace the plugin was fetched from, so it is no
  longer derived from anything. The writers use it: `bootstrap.ps1` (both the lens path and the
  `@`-import it writes into `CLAUDE.md`) and `sync-roster.ps1`.
- **`Get-LensDirCandidates`** — the ordered locations a lens may be read from: the canonical path
  first, then any other family segment a pre-fix bootstrap left behind, then the legacy
  `.claude/extensions/`. Every reader now walks that list: `check-roster-sync.ps1`,
  `check-connectors.ps1`, and `check-consumer-drift.ps1` — the last two carried the same hardcoded
  segment and therefore the same false-missing bug.

Consequence: **no migration needed.** A consumer bootstrapped before this fix keeps working — its
lenses are found and counted as present, and the check adds one soft `[INFO]` per directory (not per
lens) pointing at the misalignment. `sync-roster` additionally refuses to write a scaffold when a
lens for that id already exists on a non-canonical path, so it can never produce the second copy.

Covered by regression tests in `scripts/tests/roster-sync.tests.ps1` (scenario 9b: off-path lenses
are found, no false `[ERROR]`, exactly one `[INFO]` per directory) and
`scripts/tests/bootstrap-drift.tests.ps1` (the version-cache scenario now asserts the canonical path,
no lenses under the marketplace name, and a canonical `@`-import). From inbound issue #179 (source:
DaveKJohn/djcylow-react).
