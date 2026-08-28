## Development: `docs/the-gate-red-was-load-not-its-caller-v1` · 20260828-201259

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

Issue #1033 asked whether `Invoke-TestSuiteGate`'s verdict depends on its caller. Measured on `f2ca263f`:
it does not, and the axis the report names does not exist — `cut-release.ps1` dot-sources the same two
libs the "polluted" session did. Record the measurement where the gate's cost already lives, and give the
docstring the converse of its own #821 rule.

### CREATE

- [x] Verify the report against the tree before routing it: `cut-release.ps1:262,275` dot-sources
      `repo-config.ps1` and `native-capture-lib.ps1`, so the green and red runs had identical state.
- [x] Re-run the gate five times on one tree across the named axes (16/18 lanes, CP 850/65001, idle and
      2x load): 194s, 216s, 203s, 421s, 419s — all 54/54 green.
- [x] `Invoke-TestSuiteGate`'s docstring gains the converse of its inbound-#821 rule, and the mirror in
      `plugins/workflows/contributing-davekjohn/` is rebuilt from it.
- [x] Nolan #25's lens gains the n=5 table and what it retires: 443s was a load reading, not the cost.
- [x] Sylvester #15's fan-out bullet gains the third sighting, and says the tested runner does it too.

### TEST

- [x] Lint gate + all 54 suites green before the PR (`open-pr.ps1` runs both).
- [~] No new test: nothing executable changed — a docstring and two lenses. The dead-link check in
      `check-plugin-integrity.ps1` already judges the two new cross-lens anchors, and
      `shared-scripts.tests.ps1` already judges the mirror against its source.

### DEPLOY: `docs/the-gate-red-was-load-not-its-caller-v1`

The test gate's verdict does not depend on who calls it, and the release figure that said the suites cost
443s was measuring the machine.

Inbound [#1033](https://github.com/DaveKJohn/claude-code-specialists/issues/1033) came out of the
`v4.22.0` cut, where the same tree answered green in 443s inside `cut-release.ps1` and **11 of 54 failed
in 626s** when the gate was driven from the session afterwards — with one of the eleven passing alone in a
fresh process. It read that as the gate depending on whether its caller had dot-sourced the libs, and
concluded that CI is on the failing side. The two files it names say otherwise: `cut-release.ps1`
dot-sources `repo-config.ps1` and `native-capture-lib.ps1` before it calls the gate, so both runs had
identical state, and CI's `ProcessorCount` is **four** on its runner against the eighteen lanes the red
run used.

Re-measured across every axis the report did name — 16 and 18 lanes, console CP 850 and 65001, idle and
under a second identical gate — **five full runs, all 54/54 green**: 194s, 216s, 203s, 421s, 419s. The
last pair is the one that pays: two gates side by side reproduce the release's own *green* 443s to within
5%, which retires that number as a cost figure. This gate costs about **200s** on that tree; 443s was a
reading of what else the machine was doing, and 626s was more of the same.

What is left is real but older than the report. Red under the gate and green alone, on these same suites,
has now been seen three times — the `Start-Job` fan-out of August 12, the two post-split reds of August
16, and these eleven — and none of the three reproduces. Six of the eleven scan the live tree and five do
not, so the known collision covers part of it and nothing covers the rest. So it is named where it fires:
`Invoke-TestSuiteGate`'s docstring now carries the converse of its own inbound-#821 rule, pointing at the
two lenses that already held the standing response — *re-run the red suite alone before believing its
assert*. Not reaching those two pages is what cost that release 22 minutes, not the flake.

**Score:** 2

#### What makes this deploy extra special

The docstring half travels: `native-capture-lib.ps1` is mirrored into `workflow-davekjohn`'s
`contributing-davekjohn` plugin, so a consumer running that workflow gets the same warning above their own
gate on their next update. The measurements stay here, in the two lenses, because they are this machine's.

**Score:** 1

#### Pull Request

the gate's red was the machine, not who called it
