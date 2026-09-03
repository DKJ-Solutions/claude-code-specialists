## Development: `fix/test-gate-summary-omits-lanes` · 20260903-160005

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Issue #1318: the green and red summary lines of Invoke-TestSuiteGate carry the suite count and the seconds but not the parallel lane count that makes the seconds mean anything -- the #1314 defect upstream. Put the lane count on both lines, decide the machine question (no: lanes plus the cores-2 vs cores shape already distinguish dev box from CI), update test-suite-gate.tests.ps1.

### CREATE

- [x] `scripts/lib/native-capture-lib.ps1` -- `Invoke-TestSuiteGate`: build a `$laneNote` from the
  resolved `$MaxParallel` (`" (N lanes)"`, singular `lane` at 1) and append it to BOTH summary lines,
  green (`:807`) and red (`:811`), between the seconds and the closing `.`/`:`. Guarded on
  `$suites.Count -gt 0` so a commands-only gate -- which never resolves `$MaxParallel` and runs its
  commands one at a time -- states no lane count.
- [x] Machine question decided NO: the comment records why -- CI passes
  `-MaxParallel ([Environment]::ProcessorCount)` and a dev box takes `- 2`, so the lane number already
  tells a hosted runner from a workstation without a hostname landing in a public repo's changelog.
- [x] `scripts/sync/build-shared-scripts.ps1` -- mirrored the source change into the two plugin copies
  (`contributing-davekjohn`, `team-shopify`); `-Check` clean.
- [x] `scripts/tests/test-suite-gate.tests.ps1` -- asserts added/updated on the summary line: the green
  line names the lane count (case 2, shape not value), the red line carries it before the colon
  (cases 3 and 6), `-MaxParallel 1` prints singular `(1 lane)` (case 4), and a commands-only gate
  carries no lane note (case 6). 52/52 pass.
- [x] The lint gate's own wall-clock (issue #1318's second open question) is NOT touched here: it lives
  in `gate-lib.ps1`, is a different function with its own caching/skip behaviour, and is filed
  separately.

### TEST

`scripts/tests/test-suite-gate.tests.ps1`: 52 pass, 0 fail. Siblings that name `Invoke-TestSuiteGate`
at wiring level unaffected -- `gate-lib.tests.ps1` (111), `native-capture.tests.ps1` (60),
`cut-release-guardrail.tests.ps1` (92) all green. `build-shared-scripts.ps1 -Check`: in sync. Full
lint + test gate via `open-pr.ps1` below.

### DEPLOY: `fix/test-gate-summary-omits-lanes`

`Invoke-TestSuiteGate` printed the parallel lane count only on the opening line nobody quotes and left
it off the summary line that gets copied into branch documents, changelog entries and commit messages
-- so the seconds on that line were a draw from a spread of at least 4.5x with nothing stating the
run's parallelism (issue #1318, the #1314 defect one step upstream). The lane count now rides both
summary lines, green and red: `test gate: all 62 suites passed in 89s (16 lanes).` The machine is
deliberately not added -- the lane number already separates a hosted runner (`ProcessorCount` lanes)
from a workstation (`ProcessorCount - 2`). Source lib plus its two plugin mirrors;
`test-suite-gate.tests.ps1` gains the summary-line asserts.

A consumer who quotes a gate figure gets the lane count for free from now on, but it is a parenthetical
on one line and nobody is blocked without it.

**Score:** 2

#### What makes this deploy extra special

A one-line output change to a gate, proven by that gate's own suite -- no migration, no irreversible
step, no visible result to judge by eye.

**Score:** N/A

#### Pull Request

Invoke-TestSuiteGate summary line names its lane count

