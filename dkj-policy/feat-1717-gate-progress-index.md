## feat/1717-gate-progress-index

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
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

Emit started/done/running counts from `Invoke-TestSuiteGate` itself, plus a nesting depth so a
fixture's own gate run is distinguishable from the run the operator is waiting on.

#### What issue #1717 asked for, and what it deliberately did not

The issue proposed an index on the block header the gate already prints
(`== [37/84] roster-sync.tests.ps1 ==`) and left elapsed/remaining to whoever picked it up. Both
halves are answered here, and one is answered by declining:

- The index is a **line of its own, printed immediately above the header** rather than inside it. It
  reads as the index the issue asked for, and `== <suite> ==` stays byte for byte what it was -- which
  the issue itself named as the constraint (attribution when 16 lanes interleave), and which this
  suite's own case 2 asserts as "the suite's own output is the very next line".
- **Started is reported as well as done**, per the issue's own second comment: the queue dequeues
  longest-first since #1358, so on a truthful hints file nothing COMPLETES -- and nothing is printed --
  for the first ~15 minutes of an 84-suite run.
- **No remaining-time estimate.** The hints the queue is ordered by are CI's seconds, and #1713
  corrected this very file for claiming they convert to a local machine by a ratio; the sign of the
  difference is not even fixed. An ETA from them would be that mistake again, printed 168 times a run.

### CREATE

- [x] `Format-GateProgressLine` and `Get-GateNestingDepth` in `scripts/lib/native-capture-lib.ps1`,
      beside `Format-GateSeconds` -- pure, so the shape is assertable without a gate run
- [x] `Invoke-TestSuiteGate`: one line per lane opening and one per suite reaped, the counters kept
      explicitly, running derived as `started - done` (the one identity both call sites use)
- [x] `DKJ_TEST_GATE_DEPTH` set for the pool's children and restored in its `finally`, first, ahead
      of the capture-retention block
- [x] The docstring banner, pointing at the two helpers rather than restating them
- [x] `scripts/sync/build-shared-scripts.ps1`: the two plugin mirrors of the lib

### TEST

- [x] `test-suite-gate.tests.ps1` case 9, +20 asserts: the line's shape under nl-NL, the depth's five
      malformed inputs, a real run's counters, the header adjacency, the nested run at depth 2, and
      that the variable does not outlive the run
- [x] `test-suite-gate.tests.ps1` green standalone: 150 pass, 0 fail
- [x] **And green as a gate CHILD, which standalone did not prove.** The first `open-pr` run failed
      1 of 86 -- this suite -- with nine asserts holding a literal depth: the gate sets
      `DKJ_TEST_GATE_DEPTH` for its children, and this suite *is* one of them under the pool, so every
      driver run inherited depth 1 and reported 2, and the gate a fixture suite drives reported 3.
      Fixed in the fixture rather than in the asserts: `Invoke-Gate` now removes the variable around
      each child launch, so the driver's depth is the one an operator sees. Re-verified by running the
      suite with `DKJ_TEST_GATE_DEPTH=1` set, which is the exact condition that failed
- [x] The lint gate and the full suite pool via `open-pr.ps1`

#### The lesson, recorded where it happened

Shared state a fixture must OWN rather than inherit -- the same class as the `SetConsoleOutputCP`
cross-talk this lib documents from inbound #821. The suite that tests the gate necessarily runs as a
gate child, so any literal it asserts about the gate's environment is true standalone and false under
the pool. The docstring's own rule (#1033: *"a suite green under the gate and red standalone is
reporting a real defect"*) held in the mirror direction here: red under the gate, green standalone,
and it was a real defect -- in the test, not in the subject.

### DEPLOY: feat/1717-gate-progress-index

The test gate now reports its own progress. It prints one line as each lane opens and one as each
suite leaves one -- `test gate: progress [depth 1] 37/84 started, 30 done, 7 running (+412.6s) --
started roster-sync.tests.ps1` -- so a 15-30 minute local run no longer goes silent between walls of
completion-order output. Started is reported as well as done because the queue dequeues longest-first
(#1358): a done-count alone sits at 0 through exactly the window an operator is asking the question
in. The `[depth N]` marker is what makes the count dedupable -- the gate's own suite drives the gate
over a fixture, so a nested run is unavoidable here, and every external way of deriving this number
failed on it (#1717 measured three, each differently). The `== <suite> ==` header is untouched, and
no remaining-time estimate is printed: the duration hints are CI's seconds, and #1713 established
they do not convert to another machine.

**Score:** 3

#### What makes this deploy extra special

N/A -- the gate is a maintainer's tool. A subscriber of this system never watches it run; what
reaches them is a release, and this changes nothing about one.

**Score:** N/A

#### Pull Request

Report the test gate's own progress: started, done and running, per suite
