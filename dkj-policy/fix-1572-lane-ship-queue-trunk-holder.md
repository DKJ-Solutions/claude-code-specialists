## fix/1572-lane-ship-queue-trunk-holder

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

Issue #1572, verified in `scripts/release/ship-pr.ps1`:

- Step 0a (`~line 387`) reads `Get-WorktreeHoldingBranch ... -Branch 'main'` and, on a hit, refuses
  immediately with `Write-Error` -- stated ground: *"so step 5 could not fold after the merge"*.
- The queue verdict (`$queueVerdict = Get-MergeQueueVerdict ...`, `~line 483`) is computed a hundred
  lines later. Under a queue, `ship-pr` opens, waits, enqueues and exits -- it never touches the trunk,
  and `fold-on-merge.yml` folds off the queue's own push (#1493).
- So the step 0a refusal is a precondition for a step the run then decides not to perform. The
  precedent is the comment right after the queue verdict (#1506), making exactly this argument for the
  fold-push verdict: *"under a queue the fold-push verdict is not this run's question."* The
  trunk-holder guard is the one fold precondition that never got that treatment.
- It blocks the lane workflow `ship-pr` itself recommends ("open that second terminal in a lane"):
  step 2b (#1073) deliberately leaves the primary on the trunk, and the lane's ship is then refused.

### CREATE

- [x] In `ship-pr.ps1` step 0a, keep the `git worktree list` read and the `$trunkHolder` assignment,
  but move the refusal itself to *after* the queue verdict, gated `if ($trunkHolder -and -not
  $queueActive)`. Where a queue is read, print a DarkGray note instead of refusing. Where no queue is
  read (`$queueActive` false), the guard fires exactly as before -- unreadable keeps meaning "assume
  the session folds". Free local read still runs before the network ruleset read.
- [x] Ran `build-shared-scripts.ps1` to sync the `dkj-policy` plugin mirror.

### TEST

- [x] Added source-text ordering asserts to `scripts/tests/pr-issues.tests.ps1` (ship-pr's only
  caller; the script is integration-only): the worktree read precedes the queue read, the queue verdict
  precedes the trunk-holder refusal, the refusal is gated on `-not $queueActive`, and under a queue the
  held trunk is noted rather than refused. These fail on the unpatched script (the gated `if` string
  does not exist, and the refusal sat above the verdict).
- [x] `pr-issues.tests.ps1` green; running the full suite via `open-pr`.

### DEPLOY: fix/1572-lane-ship-queue-trunk-holder

`ship-pr.ps1` refused a lane ship whenever another worktree (the primary checkout) held `main`, on the
ground that "step 5 could not fold after the merge" -- but under a merge queue step 5 folds nothing:
the queue's own push to `main` runs `fold-on-merge.yml`. The refusal therefore blocked the exact
lane workflow `ship-pr` itself recommends, since step 2b (#1073) leaves the primary on the trunk on
purpose. The refusal now runs *after* the queue verdict and is gated on `-not $queueActive`, the same
shape #1506 established for the fold-push verdict; under a queue the held trunk is noted, not refused.
Where no queue is read the guard is unchanged.

**Score:** 4

The lane ship path -- the one `ship-pr` prints while waiting on CI -- was simply broken on a queued
trunk. Each occurrence was worked around by hand (moving the primary off the trunk, against the
orchestrator's "end on the trunk" rule for the duration of the ship).

#### What makes this deploy extra special

A consumer running `dkj-policy` *with a merge queue on their trunk* hits the same refusal if they
follow `ship-pr`'s own advice to ship from a lane. Bounded audience -- GitHub only offers merge queue
on private repos under Enterprise/Team -- but for those repos the lane ship was unusable.

**Score:** 3

#### Pull Request

ship-pr no longer refuses a lane ship on a queued trunk where it folds nothing

