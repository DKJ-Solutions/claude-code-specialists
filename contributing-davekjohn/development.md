## Development: `fix/gate-seconds-invariant-v1` · 20260831-132139

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

Fix committed: Invoke-TestSuiteGate's summary lines now route the elapsed figure through Format-GateSeconds (InvariantCulture), so 2182s no longer prints as '2.182s' on a nl-NL machine (#1159). Regression case added under nl-NL in test-suite-gate.tests.ps1. Next: PR.

### CREATE

- [x] Added `Format-GateSeconds` to `scripts/lib/native-capture-lib.ps1` -- a one-line helper
      that formats a seconds figure with `{0:N0}` through `InvariantCulture`, with a docstring
      stating the hazard (issue #1159) and pointing at `measure-skill-lib.ps1`'s Format-* helpers.
- [x] Routed `Invoke-TestSuiteGate`'s two summary lines (`test gate: all N suites passed in ...`
      / `... N of M suites FAILED in ...`) through it instead of a bare `-f "{...:N0}s"`.
- [x] Re-synced the plugin mirror via `scripts/sync/build-shared-scripts.ps1` -- the mirror
      `plugins/workflows/contributing-davekjohn/scripts/lib/native-capture-lib.ps1` is byte-identical again.

### TEST

- [x] Added case 0 to `scripts/tests/test-suite-gate.tests.ps1`: dot-sources the real lib and,
      under `nl-NL`, asserts `Format-GateSeconds 2182.4` is `2,182` (not `2.182`), that a sub-1000
      figure carries no separator, and that it rounds to whole seconds. A regression would pass in
      en-US, so the case forces the Dutch culture -- measure-skill's lesson.
- [x] `test-suite-gate.tests.ps1` -- 49 pass, 0 fail.
- [x] `native-capture.tests.ps1`, `cut-release-guardrail.tests.ps1`, `shared-scripts.tests.ps1` -- all green.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors (ASCII gate 27 and the link/import scans included).

### DEPLOY: `fix/gate-seconds-invariant-v1`

`Invoke-TestSuiteGate` (the test gate `open-pr.ps1`, `cut-release.ps1` and CI all run) now formats
its elapsed-seconds figure invariantly. `-f "{...:N0}s"` formats in the operator's culture, so on a
`nl-NL` machine a run over 1000s printed `test gate: all 55 suites passed in 2.182s.` for a run that
took 2182 seconds -- a factor of a thousand off and still plausible, and latent below 1000s, which is
exactly where every figure this gate had ever printed sat. The new `Format-GateSeconds` helper routes
the figure through `InvariantCulture` (the position `measure-skill-lib.ps1` already took and stated at
length for its own Format-* helpers), so the two summary lines now read `2,182s` on any machine.
Inbound #1159.

**Score:** 2

#### What makes this deploy extra special

A consumer runs this gate through the `contributing-davekjohn` plugin skill (`open-pr` / `ship-pr`),
from the mirrored copy of this lib. A consumer on a European locale -- where `.` is the thousands
separator -- with a test suite slow enough to cross 1000s would have been handed a runtime that looked
a thousand times better than it was, at the one moment (a slow run) the number is worth reading. They
receive the invariant formatting through the plugin update.

**Score:** 2

#### Pull Request

Format the test gate's elapsed seconds invariantly

Plugins: contributing-davekjohn

