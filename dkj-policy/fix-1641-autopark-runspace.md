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

Runspace replaces the child spawn; `Invoke-GitPark`'s push gains the shared network bound.

#### What #1641 got right, and the half of it that had expired

The symptom stands: the Stop hook spawned a whole `powershell.exe` to run one script, on every turn.
Its **reasoning** did not. The report is built on `Invoke-CheckScript` in `scripts/lib/hook-check-lib.ps1`
"deliberately not merging stderr" -- neither that function nor that file exists in this tree, because
**#1625 is still OPEN**: it filed the SessionStart family and prescribed nothing, listing three options it
explicitly left unchosen. So "#1625's fix does not transfer as written" describes a fix that was never
written, and its points 1 and 2 (where the line goes in-process, whether that lib grows a switch) had no
subject to be about. Point 3 -- the network reach -- is the half that stood, and it is what this branch
acted on.

#### The size, re-measured here rather than taken from the report

#1641 reports 219 ms and reads it as the saving. It is the spawn's own cost, and a runspace is not free:
cold, in a fresh hook process, opening one costs ~45 ms. Measured on this machine (Windows PowerShell 5.1,
7 runs each, median):

| what was timed | spawn | runspace | back |
|---|---|---|---|
| the full hook against a do-nothing stub | 220 ms | 150 ms | ~70 ms |
| the full hook against the REAL park-cycle | 867 ms | 695 ms | ~172 ms |

The real figure is the larger one, and the reason is worth keeping: park-cycle dot-sources several libs,
and in a runspace it does that inside an engine the hook process has already warmed.

#### Why a runspace and not the dot-source #1625 reaches for first

`park-cycle.ps1` calls `exit` at **fourteen** top-level places, and `exit` inside a dot-sourced script
terminates its caller -- the hook, mid-relay. A runspace makes all fourteen harmless: `exit` ends that
runspace's pipeline, not this process. Pinned as case (i).

#### Where the unbounded network call actually was

One layer below where #1641 looks. `Invoke-GitPark`'s `git push` (`scripts/lib/park-lib.ps1`) was the only
call in this family reaching the network unbounded, while native-capture-lib's own header names the three
that are not, and park-cycle's failure-path fetch passes the same number a few lines on. Bounding the
hook's child would have been the blunt version of this; bounding the push is the precise one.

### CREATE

- [x] `cycle-autopark.ps1`: a runspace instead of the child spawn, `*>&1` instead of `2>&1`, and ExecutionPolicy Bypass for parity with the flag the child carried
- [x] The relay reads a `PSDataCollection` filled as output is produced, so a park-cycle that throws cannot swallow the lines it already wrote
- [x] Arguments splatted as a **hashtable** -- an array splats positionally, which bound the string `-Quiet` to `-RepoRoot`
- [x] `park-lib.ps1`: `Invoke-GitPark`'s push bounded by `$NativeCaptureNetworkTimeoutSeconds`, with the plugin mirror held byte-identical

### TEST

- [x] `cycle-autopark.tests.ps1` extended from 11 asserts to 20: the in-process process id, named binding, the wider merge, `exit` containment, throw parity
- [x] The new asserts run against the OLD hook to prove they discriminate -- (f) fails there; the other four pass both ways and are labelled regression guards rather than claimed as proof
- [x] Smoke-tested against the real park-cycle on this branch: silent with nothing to push, commit + bounded push when there is
- [x] Lint gate clean; all 79 suites green

### DEPLOY: fix/1641-autopark-runspace

The `cycle-autopark` Stop hook no longer starts a second PowerShell interpreter to run `park-cycle.ps1`.
It runs it in an in-process runspace instead, which gives ~172 ms back on **every turn** (867 ms -> 695 ms
median against the real script, 7 runs each). A runspace rather than a dot-source, because
`park-cycle.ps1` calls `exit` at fourteen top-level places and `exit` inside a dot-sourced script would
terminate the hook along with it.

Two things improve beside it. The capture widens from `2>&1` to `*>&1`, so the safety net #1600 built for
stderr now covers **every** stream park-cycle can write to, in one ordered sequence -- and the relay
collects output as it is produced, so a park-cycle that throws still delivers what it wrote before it fell
over. Separately, `Invoke-GitPark`'s `git push` was the last call in this family reaching the network
unbounded; it now passes the same shared network timeout its three siblings do, which matters most exactly
here, where the caller is a hook firing every turn with nobody watching a prompt to interrupt.

The hook's suite goes from 11 asserts to 20. One of them pins the saving itself -- park-cycle reports the
hook's own process id -- because every stream assert passes whether or not there is a child process, so
nothing else would notice a silent return to spawning.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo's readers are its own maintainers, and the change is invisible from outside a session's
turn timing.

**Score:** N/A

#### Pull Request

cycle-autopark runs park-cycle in a runspace instead of a second interpreter
