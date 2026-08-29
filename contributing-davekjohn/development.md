## Development: `fix/prune-merged-gives-the-branch-back-v1` · 20260829-132423

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

Issue #1071: capture is already there ($startBranch); return to it at every exit after the trunk checkout, and say so when the branch was reaped by this same run.

#### The decision the issue left open

The report offered three answers and named none: return to the start branch, say it louder, or leave
both. **Return**, on the ground the report itself supplies — `ship-pr` ends on the trunk because it
closes a *finished* assignment, and this script closes nothing. It is a maintenance command, run
mid-assignment, and the branch it stepped off is still there.

One thing in the report's reasoning does **not** hold, and it changed the shape of the repair: *"the
branch you are standing on cannot be deleted anyway"* stops being true the moment step 2 steps off it.
So a start branch this same run reaps is a real state, and the hand-back has to say so instead of
reporting a branch it cannot find.

### CREATE

- [x] `Restore-StartCheckout` + `Complete-Run` in `scripts/task/prune-merged.ps1`: every path out from
      the step-3 marker onward hands the checkout back, with the closing line saying where it ended.
- [x] The two starts that cannot be returned to — a start branch this run reaped, a detached start —
      say so and name the short sha, read in step 2 before anything moves.
- [x] The contract written at the seam and in the header, since the report asked for the answer to
      live next to the line.
- [x] Mirrored to `plugins/workflows/contributing-davekjohn/scripts/task/prune-merged.ps1`
      (byte-identical, shared-scripts drift lint).
- [x] The `prune-merged` skill page: step 5 in the list, and why the contract is not `ship-pr`'s.

### TEST

- [x] Four behavioural cases in `scripts/tests/prune-merged.tests.ps1`, asserting on **HEAD** rather
      than on the sentence: the hand-back (plus `-DryRun`, which borrows the checkout just as hard), a
      reaped start, a run started on the trunk, a detached start.
- [x] One structural case: no bare `exit` below the step-3 marker, so a path added later cannot forget
      the hand-back — which is the original defect's own failure mode.
- [x] Suite green: 63 pass, 0 fail (45 before).
- [~] No case for a hand-back that *fails*: the return is a checkout of a branch this same tree was
      standing on moments earlier, and a fixture that makes git refuse it would be testing git. The
      path is loud (`Write-Warning`, "switch back by hand BEFORE you commit") rather than untested.

### DEPLOY: `fix/prune-merged-gives-the-branch-back-v1`

`prune-merged` borrows the checkout for its fast-forward and now gives it back. It used to switch to
the trunk in step 2 and stay there — silently, with a clean tree and nothing in `git status` to show
for it, so the next commit of that session landed **directly on `main`**. The information to return was
already in the script: `$startBranch` was captured and spent on one sentence. Two starts cannot be
returned to and each says so while naming the sha it left: a start branch this same run reaped, and a
run that started detached.

**Score:** 4

#### What makes this deploy extra special

The script is plugin payload, so the same silent trunk-switch is in every consumer's `prune-merged`
skill, and the fix reaches them with the next release. The hazard is the one nothing warns about: the
run is a success, the tree is clean, and the mistake happens one command later.

**Score:** 3

#### Pull Request

prune-merged gives the checkout back to the branch it borrowed it from

