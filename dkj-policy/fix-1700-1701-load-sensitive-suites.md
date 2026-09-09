## fix/1700-1701-load-sensitive-suites

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

#### One class, twice reopened

[#1232](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1232) is closed and its title
is what happened twice more: *"the test gate refuses a push for a race the branch had no part in."*
[#1700](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1700) measured both rungs of
its retry ladder losing inside one gate run;
[#1701](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1701) measured six assertions
failing because a 30-second bound in the hook a suite drives was reached under sixteen lanes. Both
branches read nothing either suite touches. Both cost a 33-minute re-run and a hand-lowered
`-MaxParallel`.

#### The shape of the answer, since neither issue chose one

Neither is repaired by a wider number. A bound sized against a measurement rather than above it is
what #1232 shipped, and #1700's own table is the receipt. So in both cases the RACE is removed rather
than the margin widened, and in both cases the assertion is left exactly as strong as it was.

### CREATE

- [x] #1700: derive the ladder's rungs from a calibration launch taken on this machine at this moment,
      instead of the fixed 3s/12s
- [x] #1701: give the hook's bound a parameter defaulted to today's 30s, and raise it once in the
      helper that runs the real engine -- production behaviour unchanged
- [x] A scenario that forces the degraded branch deterministically, so the parameter is proved read
      and the exit-124 line stays pinned

### TEST

- [x] Both suites green standalone, and the whole gate green
- [x] The calibration prints what it measured, so a future failure names the machine

### DEPLOY: fix/1700-1701-load-sensitive-suites

Two test suites stopped racing a wall-clock bound under the test gate's own parallel lanes, and in
neither case by widening a number -- which is what
[#1232](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1232) did, and why this class
reopened twice.

`native-capture.tests.ps1` no longer guesses how long two cold PowerShell 5.1 startups take: it runs the
same launch once, unbounded and unkilled, polls for the grandchild's marker with a stopwatch, and derives
its ladder from that reading -- 4x, floored at 6s so an idle machine pays roughly what this fixture always
paid, capped at 60s so a pathological reading cannot hang the gate behind one suite. The ladder survives,
with one derived rung above the calibrated one, because a calibration is itself a sample. The measured
figure is printed and named in the assert that would fail, so a miss at both rungs reads as the machine
rather than as the code under test.

`connector-sessioncheck.ps1`'s 30s version bound is now `-VersionTimeoutSeconds`, defaulted to 30 -- a real
session start behaves exactly as before. The bound was a literal at its call site, where the one caller that
must raise it, this hook's own suite, could not; that suite now raises it once in the helper every block
shares. The un-degraded output stays pinned rather than being relaxed to "either shape", and the degraded
shape gets a scenario of its own: a fake engine that sleeps five seconds against a bound of one, so the
exit-124 line is forced on any machine at any load instead of being raced for.

**Score:** 2

#### What makes this deploy extra special

N/A. The hook travels in `dkj-policy`, so a consumer receives the new parameter, but its default is the
figure the call site already used and nothing on their side passes it -- a session start there prints
exactly what it printed before. The two suites are this repo's own gate and are mirrored into no plugin.

**Score:** N/A

#### Pull Request

Two suites stop racing a wall-clock bound under the gate's own load

Plugins: dkj-policy
