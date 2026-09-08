## fix/1641-autopark-runspace

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

`cycle-autopark` runs park-cycle through `Invoke-CheckScript` instead of a second interpreter, and
`Invoke-GitPark`'s push gains the shared network bound.

#### The branch name says "runspace" and the change no longer is -- read this first

A runspace was built, measured, tested green, and then thrown away mid-branch. The name is left alone
because renaming a branch mid-flight costs a PR and a document rename for no reader's benefit; what
follows is why the design changed, since that is the part a later reader needs.

#### What #1641 got right, and what had expired when it was picked up

The symptom stands: the Stop hook spawned a whole `powershell.exe` to run one script, on every turn.
Its **reasoning** did not -- at pickup. The report is built on `Invoke-CheckScript` in
`scripts/lib/hook-check-lib.ps1` "deliberately not merging stderr", and at that moment neither the
function nor the file existed: #1625 was still open, having filed the SessionStart family and
prescribed nothing.

**Then it stopped being expired, mid-branch.** #1625's repair merged as #1644 while this branch was in
CI, and ship-pr's staleness gate refused the merge -- correctly -- because `main` had moved. Bringing
the branch forward brought the lib with it, and #1641's points 1 and 2 became answerable exactly as
written. That is the whole reason the design below is not the one this branch started with.

#### Why the runspace went, and the premise that turned out to be false

The runspace existed for one reason: `park-cycle.ps1` calls `exit` at fourteen top-level places, and
`exit` inside a dot-sourced script terminates its caller. That is true -- of **dot-sourcing**, and of a
script **block** invoked with `&`. It is **not** true of a .ps1 **file** invoked with `&`, which gets
its own scope, ends at its own `exit`, and hands back `$LASTEXITCODE`. #1644's lib header states this
and says it was verified rather than assumed; it was verified again here before acting on it, in both
directions. So the cheap route was open all along, and the runspace was ~45 ms of the ~102 ms it saved.

#### Point 2 answered: the switch goes in the lib

`Invoke-CheckScript` merges Write-Host and the pipeline (`6>&1`); this hook needs every stream
(`*>&1`), which is #1641's open question of whether the lib grows a switch or the hook gets its own
call. **The lib grows the switch.** The default's stated reason is a filter -- a merged error line
would sit in front of the session checks' `[ERROR]` filter as if the check had reported it -- and
cycle-autopark has no filter at all: it relays park-cycle verbatim. Everything else is shared (the
hashtable splat, the newline split, the `$LASTEXITCODE` reset, the return shape), and all three of the
lib's documented traps fail **silently**, so a second copy is the drift the lib exists to prevent.

#### One thing in-process took away, and how it was kept

A child process had already **printed** its early lines before it died. In-process, a check that throws
leaves no return value, so an assignment loses them -- measured at 0 lines recovered against 2 from a
list appended to inside the pipeline. Losing them is right for the six session checks and wrong for the
one caller that relays, so `-OutputTo` hands such a caller a list filled as the lines stream past. The
exception still propagates, because those six report a crashed check as skipped.

#### Where the unbounded network call actually was

One layer below where #1641 looks. `Invoke-GitPark`'s `git push` (`scripts/lib/park-lib.ps1`) was the
only call in this family reaching the network unbounded, while native-capture-lib's own header names
the three that are not, and park-cycle's failure-path fetch passes the same number a few lines on.
Bounding the hook's child would have been the blunt version of this; bounding the push is the precise
one.

#### The size, re-measured here rather than taken from the report

#1641 reports 219 ms and reads it as the saving; that is the spawn's own cost. Measured on this machine
(Windows PowerShell 5.1, 7 runs each, median), against the **real** park-cycle:

| the turn being measured | spawn | in-process | back |
|---|---|---|---|
| nothing to push -- the ordinary turn | 867 ms | 674 ms | ~193 ms |
| a document to commit and push | 1207 ms | 1084 ms | ~123 ms |

The first row is the one that matters, because most turns do not touch the branch document. The saving
exceeds the ~102 ms a bare interpreter start costs, because park-cycle dot-sources several libs and
does that inside an engine the hook process has already warmed.

### CREATE

- [x] `hook-check-lib.ps1`: `-MergeAllStreams` (`*>&1`) and `-OutputTo`, both additive; the capture appends inside the pipeline instead of assigning from it, so partial output survives a throw
- [x] `cycle-autopark.ps1`: dot-sources the lib and calls `Invoke-CheckScript` with both, replacing the child spawn, the hand-rolled `2>&1`, the `ToString()` and the newline handling
- [x] `park-lib.ps1`: `Invoke-GitPark`'s push bounded by `$NativeCaptureNetworkTimeoutSeconds`
- [x] All four mirrors held byte-identical (two of `hook-check-lib`, one of `park-lib`)

### TEST

- [x] `hook-check-lib.tests.ps1` -- a NEW suite, 18 asserts: the lib shipped in #1644 with none, and this branch rewrote the capture path all seven callers use
- [x] `cycle-autopark.tests.ps1` extended from 11 asserts to 20: in-process process id, named binding, the wider merge, `exit` containment, throw parity
- [x] The new hook asserts run against the OLD hook to prove they discriminate -- the process-id one fails there; the rest pass both ways and are labelled regression guards rather than claimed as proof
- [x] Smoke-tested against the real park-cycle on this branch, both paths: silent with nothing to push, commit + bounded push when there is
- [x] Lint gate clean; every suite green

### DEPLOY: fix/1641-autopark-runspace

The `cycle-autopark` Stop hook no longer starts a second PowerShell interpreter to run `park-cycle.ps1`.
It runs it through the same `Invoke-CheckScript` the six SessionStart hooks have used since #1625, which
gives ~193 ms back on **every turn** (867 ms -> 674 ms median on a turn with nothing to push, 7 runs
each). This hook fires far more often than that family, so it was paying the same avoidable start-up the
most times.

Two additions to the shared lib made that possible, and both are opt-in with nothing changed for its
existing callers. `-MergeAllStreams` captures every stream rather than Write-Host and the pipeline
alone: the session checks must not merge stderr, because a stray line would sit in front of their
`[ERROR]` filter, while this hook has no filter and relays park-cycle verbatim -- which is what #1600
built its `2>&1` for. `-OutputTo` keeps what a check managed to write before throwing; in-process there
is otherwise no return value to read, and for a relaying caller those lines are the diagnosis.

Separately, `Invoke-GitPark`'s `git push` was the last call in this family reaching the network
unbounded; it now passes the same shared network timeout its three siblings do. That matters most
exactly here, where the caller is a hook firing every turn with nobody watching a prompt to interrupt.

Coverage grows with it. `hook-check-lib.ps1` arrived in #1644 with no suite of its own, and this branch
rewrote the capture path all seven of its callers run through, so it gets one: 18 asserts over the three
silent traps its header names, plus the two new parameters. The hook's own suite goes from 11 asserts to
20, one of which pins the saving itself -- park-cycle reports the hook's own process id -- because every
stream assert passes whether or not there is a child process, so nothing else would notice a silent
return to spawning.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo's readers are its own maintainers, and the change is invisible from outside a session's
turn timing.

**Score:** N/A

#### Pull Request

cycle-autopark runs park-cycle in-process instead of a second interpreter
