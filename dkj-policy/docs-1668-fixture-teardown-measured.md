## docs/1668-fixture-teardown-measured

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### What #1668 asked for, and why the answer is not what it proposed

#1668 reports 413 leftover fixture entries under the OS temp directory and names a cause:
`fold-changelog.tests.ps1`'s per-case tree helper "creates a per-case tree under the temp directory and
**never removes it**", with neither of the suite's `finally` blocks reaching those trees. It proposes
either a per-suite teardown or a central sweep in the test gate, and flags that it may not be worth
doing at all.

The reason is verified before the repair, per `CLAUDE.md`. It does not hold, so the repair changes with
it -- building the proposed teardown would satisfy the report and be wrong, and it would now carry a
citation.

### CREATE

- [x] Verify the stated cause against the tree. The helper registers each tree it builds
      (`fold-changelog.tests.ps1:205`, `$script:fixtures += $dir`) and the register is swept twice
      (`:1359` mid-file, `:1605` on the way out). Both lines date from the file's creation commit,
      `9706d8cb`, 2026-07-24 -- so there has never been a moment at which that helper had no teardown.
- [x] Measure whether a completed run actually leaks. `fold-changelog.tests.ps1`: 107 entries standing
      before, 107 after, **0 leaked**, 254 asserts green in 74s. `new-branch.tests.ps1` (the second
      largest contributor, 96 entries): **0 leaked**, 255 asserts green.
- [x] Establish what the standing entries then are. Every leaked `fold-test-*` label is one registered
      *after* the mid-file sweep -- `duplicate`/`notduplicate` (46 distinct pids each), `staletrunk*`,
      `racedfold*`, `noorigin` -- and none at all from the ~1350 lines of cases before it. That is the
      signature of a run interrupted or thrown in its back half, not of a helper without a teardown.
- [x] Re-attribute the 413. Of the directory measured: 546 `sync-pr-body-*` files written on purpose by
      `scripts/task/sync-main.ps1:1276` for the operator to paste into `gh pr create --body-file`, which
      must outlive their run; 162 `mat-debug-*.log` belonging to an unrelated tool; 107 `fold-test-*`,
      96 `new-branch-test-*` and 12 `native-capture-*` from this repo's suites. The suites' share is
      ~215, and the largest single group in that directory is not a fixture at all.
- [x] Check whether any suite is missing a teardown outright. Scanned all 68 suites that compose a temp
      path: every one carries at least one `Remove-Item` and a `finally`. There is no missing teardown
      to add anywhere.
- [x] Record the corrected measurement in `scripts/README.md`, beside the `$PID` fixture convention and
      the `New-ScratchPath` rule it reasons from -- the place the next person measuring the temp
      directory will look.

### TEST

- [x] `scripts/tests/fold-changelog.tests.ps1` -- 254 pass, 0 fail, 0 fixtures leaked.
- [x] `scripts/tests/new-branch.tests.ps1` -- 255 pass, 0 fail, 0 fixtures leaked.
- [x] The lint gate and the full suite set, via `open-pr.ps1`.

No new test is added, and that is a deliberate answer rather than a gap: the change is a paragraph of
prose, and the property it records is already enforced -- `test-suite-gate.tests.ps1` holds fixture
paths to `$PID` or a guid, and `native-capture.tests.ps1` holds the shipping layer to the composer. A
suite asserting that a suite tears down would be re-measuring what the two runs above measured directly.

### DEPLOY: docs/1668-fixture-teardown-measured

#1668 reported 413 leftover fixture trees in the temp directory and named a cause:
`fold-changelog.tests.ps1`'s per-case tree helper never tears down. Measured, the cause does not hold.
The helper registers every tree it builds and the register is swept twice, both since the file's
creation commit on July 24, 2026; run to completion the suite leaks **zero**, and so does
`new-branch.tests.ps1`, the second-largest contributor. What the standing entries have in common is
*where* they were registered -- all after a suite's last completed sweep -- which is the signature of an
interrupted run, and no in-process teardown reaches those.

The count was also read for more than it was. Of the directory measured, 546 entries were
`sync-pr-body-*`, written deliberately by `sync-main.ps1` for an operator to paste into
`gh pr create --body-file` and therefore required to outlive their run, and 162 belonged to an unrelated
tool; the suites' own share was ~215, not 413. So the largest group counted as litter was the one thing
in that directory that is retained on purpose.

`scripts/README.md` now carries both findings beside the `$PID` fixture convention, because the
distinction decides the repair: the obvious fix is to give a helper a teardown it already has, and the
fix that would actually reach an interrupted run's residue is a sweep by name pattern in a shared temp
directory -- the same delete primitive `New-ScratchPath` was introduced to remove. Written down rather
than re-measured, so the next reader of that directory does not re-file it.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service sees. `scripts/README.md` documents this repo's own script
layer, ships in no plugin, and no behaviour a consumer invokes changes.

**Score:** N/A

#### Pull Request

The fixture convention records that suites DO tear down, and what a leftover actually means
