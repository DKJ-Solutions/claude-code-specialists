## Development: `fix/suite-gate-fixture-assert-line-scoped` · 20260903-165933

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

Issue #1326: `test-suite-gate.tests.ps1`'s per-process fixture assert scans line by line, so a
PowerShell backtick continuation puts the discriminator (`$PID`, a fresh GUID) on the next line and a
safe path is reported as an offender. Direction taken: keep the line scan for its simplicity but fold
backtick continuations before scanning, so the unit judged is a statement, not a physical line.

### CREATE

- [x] Add `Join-BacktickContinuation` -- glues a line ending in a backtick to the next, keeps the
      starting physical line number for the offender message.
- [x] Route the scan through it; judge `$stmt.Text` instead of a raw line.
- [x] Exclude the guard file itself from the scan -- it now carries `GetTempPath()`/`Join-Path` in its
      own prose and in the fold test data, which are not paths a run creates.

### TEST

- [x] Three new asserts exercise the fold directly: a split safe path folds to one statement with its
      discriminator in view, and a split bare literal is still caught.
- [x] `scripts/tests/test-suite-gate.tests.ps1` green (56 pass, 0 fail); the temp-path scan count rose
      from ~52 to 93 as folding also surfaced statements split across `GetTempPath()`/`Join-Path`.
- [~] Lint + tests green, then PR + merge + fold -- dropped: this is the post-merge chain, not a
      step of the branch's own plan; open-pr runs the gates.

### DEPLOY: `fix/suite-gate-fixture-assert-line-scoped`

`test-suite-gate.tests.ps1`'s per-process fixture assert folded backtick continuations before judging
a temp path, so a path whose `$PID`/GUID discriminator sat after a `-continuation is no longer
reported as an offender. The guard no longer scans itself.

**Score:** 2

#### What makes this deploy extra special

N/A -- a test-suite internal assert; no subscriber of any service reaches it.

**Score:** N/A

#### Pull Request

test-suite-gate fixture assert folds backtick continuations before judging a temp path

