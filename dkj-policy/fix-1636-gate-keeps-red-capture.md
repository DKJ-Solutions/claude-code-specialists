## fix/1636-gate-keeps-red-capture

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

#### The finding, verified before it was repaired

Issue [#1636](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1636), read against the
tree: `Invoke-TestSuiteGate` in `../scripts/lib/native-capture-lib.ps1` wrote each suite's stdout and
stderr to `%TEMP%\test-suite-gate-<PID>\`, printed the block when the suite reaped, and deleted the
whole directory in its `finally` -- on a red run as well as a green one, with no flag to keep it. The
console was the only copy of a failing suite's output.

The report's reasoning was checked too, and it holds: #1622's own disclaimer concluded that losing the
block to a `tail` was the reader's error and not a gate defect. The first half is right and the
conclusion does not follow -- a scrollback limit, a truncated CI log, a closed terminal and a harness
that keeps only the tail lose it the same way, and the deletion is what makes any of them fatal rather
than unlucky. A gate run here costs 130-140s and the failure it carries is, by construction, one that
may not reproduce.

#### What this branch does NOT touch

`scripts/tests/sync-main.tests.ps1`. Its `Invoke-Git` discards the exit code as well, which is the
subject of [#1622](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1622) and is
repaired on the parked branch `fix/1622-fixture-git-judged`; the sibling suites are
[#1635](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1635). This branch stays inside
the gate's own lib so the three cannot conflict.

### CREATE

- [x] `Invoke-TestSuiteGate` records the failing suites' capture files in the reap loop -- the only
      moment a suite's exit code and its two paths are held at once.
- [x] Its `finally` keeps exactly those files and deletes the rest; a run with nothing failing deletes
      the directory as before, and an empty capture file is dropped so the path named on the verdict
      cannot point at nothing.
- [x] The red verdict line names the retained directory, indented under itself so nothing already
      parsing that line has to learn a new shape.
- [x] The docstring states the new behaviour where the capture files are introduced.
- [x] `build-shared-scripts.ps1` re-run -- the lib is mirrored into `dkj-policy` and
      `dkj-team-shopify`, and both mirrors are updated.

### TEST

- [x] `scripts/tests/test-suite-gate.tests.ps1` extended, both halves asserted against a KNOWN path:
      the fixture driver now prints its own `$PID`, so the cases name the capture directory the gate
      would have used instead of diffing the temp folder -- which any other live gate run, this suite's
      own outer one included, would have answered.
- [x] Green run: the directory is gone and the verdict says nothing about kept output.
- [x] Red run: the directory survives, the verdict names it, the failing suite's stdout capture is
      there and holds what the console printed, the passing sibling's capture is deleted, and the
      failing suite's empty stderr capture is not kept.
- [x] The suite removes what a red fixture run deliberately leaves behind -- those directories sit
      outside its own `$Fixture`, so the existing teardown could not reach them.
- [x] `test-suite-gate.tests.ps1`: 82 pass, 0 fail. Two asserts were red first and the repair matters:
      they named `z-broken.tests.ps1.out.txt` while the gate writes `$suite.BaseName + '.out.txt'` and
      `BaseName` strips only the last extension. The deleted-sibling assert had the same wrong name and
      was passing **vacuously** -- it now names `a-first.tests.out.txt` and tests something.
- [~] No separate pre-run of the full lint + test gate: `open-pr.ps1` runs both itself and refuses to
      push on an error or a failing suite, so a copy set going ahead of it proves nothing that gate
      would not have caught and records nothing it will credit.

### DEPLOY: fix/1636-gate-keeps-red-capture

A failing test suite's captured output now survives the run that produced it. `Invoke-TestSuiteGate`
buffers each suite's stdout and stderr to `%TEMP%\test-suite-gate-<PID>\` and printed each block on
reap, then deleted the directory in its `finally` whether the run was green or red -- so the console was
the only copy, with no flag to keep it, and a pipe through `tail`, a scrollback limit or a truncated CI
log lost the evidence for a 130-140s run whose failure may not reproduce. A red run now keeps the
**failing** suites' `.out.txt`/`.err.txt`, deletes every other capture, and names the directory on the
verdict line -- the line a session copies into a branch document, a commit message or an issue. A green
run still keeps nothing, and an empty capture file is dropped rather than padding a directory the
verdict has just recommended reading. `$captureDir` already carried `$PID`, so a retained directory
cannot collide with a later run's.

**Score:** 3

The next red gate is diagnosable from a file instead of from scrollback, which is the difference between
reading the failure and paying 140s to try to reproduce it. Not higher because nothing a session does
today changes and a green run is byte-for-byte as before.

#### What makes this deploy extra special

A consumer running the `dkj-policy` workflow runs this same gate through `open-pr` and `cut-release`,
and the lib is mirrored into both `dkj-policy` and `dkj-team-shopify`, so the retention arrives with the
next release. It is not a change they have to notice or act on, though: nothing they type differs, and
the only visible difference is one extra line under a red verdict.

**Score:** N/A

#### Pull Request

the test gate keeps a failing suite output
