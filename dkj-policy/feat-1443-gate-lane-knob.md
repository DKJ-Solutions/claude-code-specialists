## feat/1443-gate-lane-knob

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

Add a -MaxParallel passthrough from ship-pr.ps1 and open-pr.ps1 down through Invoke-WorkflowGates to Invoke-TestSuiteGate, so an OOM-killed gate run can be run smaller instead of skipped with -SkipTests.

### CREATE

- [x] `Invoke-WorkflowGates` (`scripts/lib/gate-lib.ps1`) takes `[int]$MaxParallel = 0` and forwards it to
      `Invoke-TestSuiteGate` -- the missing hop, and the one that adds no policy of its own
- [x] `open-pr.ps1` takes `-MaxParallel` and passes it at BOTH call sites: the PR path and `-GatesOnly`
- [x] `ship-pr.ps1` takes it and forwards it to `open-pr` only when non-zero, the way `-Title` is forwarded
- [x] `cut-release.ps1` too -- the third local caller, which #1443 did not name. It calls
      `Invoke-TestSuiteGate` directly rather than through `gate-lib`, so it had the same gap; and it is the
      caller where substituting `-SkipTests` costs most, because it commits and tags on the trunk
- [x] The four plugin mirrors regenerated via `scripts/sync/build-shared-scripts.ps1`
- [x] Docs: the `open-pr` skill page gets its own section (the measurement, and why it is reached for before
      `-SkipTests`), the `ship-pr` and `cut-release` pages a flag entry each, `CONTRIBUTING.md` the third-case
      paragraph beside the two escape valves, and Sylvester's lens the note that CI is no longer the only
      caller that can choose
- [~] The default lane formula is NOT changed -- dropped on #1443's own reasoning: the reservation reasons
      about cores, what ran out was memory, and one machine is not a measurement of a formula. This branch
      adds the way past, not a new policy

### TEST

### DEPLOY: feat/1443-gate-lane-knob

`open-pr.ps1`, `ship-pr.ps1` and `cut-release.ps1` now take **`-MaxParallel <n>`** and hand it down to the
test gate, so a gate that will not *finish* can be run **smaller** instead of not at all. `0` -- the
default -- resolves exactly where it always did, inside `Invoke-TestSuiteGate`, so an ordinary run is
unchanged.

The parameter has existed at the bottom of the chain since the gate was written, and `ci.yml` passes it.
What was missing was every hop above it: `Invoke-WorkflowGates` sat between the two PR scripts and the gate
without carrying it, and `cut-release` calls the gate directly and never declared it. So on a developer's
machine the only route past a gate that dies was `-SkipTests` -- and that is strictly worse than a smaller
run, because it is the switch that says *this run did not measure*. Afterwards a branch pushed past a
memory limit reads exactly like one that skipped its suites for a bad reason.

**`cut-release` is the caller #1443 did not name and the one where it costs most.** The other two open a
PR, and a PR that does not open costs a retry; this one commits and tags on the trunk, where `-SkipTests`
means a release can be cut with a suite red.

Measured on the machine that filed [#1443](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1443)
-- 18 cores, so 16 lanes, same 68 suites, same function: the default passed once at 716s and was then
**killed twice by the harness for running out of memory**, where `-MaxParallel 4` passed in 888s. 24%
slower, and it finishes. Intermittent rather than a ceiling -- 16 lanes fits when the machine is quiet --
which is why this is a knob and not a new default. Worth knowing beside it: a starved run can also go
**false red**, and the killed run's log carried two `[FAIL]` lines in a suite that is 108/108 green run
alone.

**The default lane formula is deliberately untouched.** The reservation reasons about cores; what ran out
was memory, and one machine is not a measurement of a formula. This adds the way past, not a new policy.

**Score:** 3

#### What makes this deploy extra special

Every consumer reaches all three scripts through the plugin mirror, and their machines are the ones this
repo cannot measure -- more cores, more suites, or a laptop already running something else. Until now their
only answer to a gate that would not finish was the escape valve that erases the evidence, on the one run
whose whole job is to produce it. `cut-release` is the sharp end of that for them exactly as it is here.

The flag is documented where a session actually reads it: the `open-pr` skill page carries the numbers and
the *reach for this before `-SkipTests`* rule, and the `ship-pr` and `cut-release` pages an entry each
that forwards to it.

**Score:** 3

#### Pull Request

open-pr, ship-pr and cut-release carry the test gate's lane knob through

Plugins: dkj-policy

