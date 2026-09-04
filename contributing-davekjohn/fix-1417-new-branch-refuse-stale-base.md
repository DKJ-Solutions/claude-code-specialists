## fix/1417-new-branch-refuse-stale-base

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

Settle the half #1046 and #1405 left open: refuse rather than warn when cutting a NEW branch from a base
behind origin.

#### What the issue asked, and what reading the tree changed

#1417 listed three shapes -- leave it, refuse with a valve, or refuse above a threshold -- and rested the
case for leaving it on two premises. Both were checked against the code before anything was written, and
neither survived:

- **"A refusal lands on the script consumers are told to re-run to RESUME a parked branch."** It cannot.
  The entire base block in `new-branch.ps1` is gated on `-not $resuming`, and the resume probe runs
  *before* it (that ordering is #1139's, for its own reason). A resume never reaches the question.
- **"`worktree-lane.ps1` refuses a stale trunk, so the two scripts give two answers to one hazard."** The
  lane refuses a failed **fetch**, then bases its worktree at `origin/<trunk>` outright -- it has no stale
  base to refuse. Its answer is to remove the choice, not to judge it.

So shape 2 was taken. Shape 3 was declined on the measurement in #1046 itself: the duplicate it recorded
was of a PR merged four minutes earlier, which is a base one commit behind -- a threshold reinstates
exactly the case it would be added to soften.

### CREATE

- [x] `new-branch.ps1`: `-SkipStaleBase` switch, and a refusal where the warning already fired -- same
      condition, same message, `exit 1` before the checkout.
- [x] `worktree-lane.ps1`: pass `-SkipStaleBase` at the step-4 delegation, so the lane's contract is
      unchanged.
- [x] Both skill pages rewritten to state the refusal, the valve and the lane's real position.
- [x] Mirrors regenerated with `build-shared-scripts.ps1`.

### TEST

- [x] `new-branch.tests.ps1` (s) inverted: exit 1, and no branch, no document, and HEAD unmoved -- a
      refusal that left any of the three behind would be worse than the warning it replaced.
- [x] New case (s2) for `-SkipStaleBase`: exit 0, branch created, count still named, warning at both ends.
- [x] The local-resume case now proves the structural claim: its second run is on a trunk two commits
      behind, with no valve, and must still exit 0.
- [x] `Get-Squeezed` added beside `Test-Phrase`, so the counting asserts stop hand-copying its stripping.
- [x] Full gate: `check-plugin-integrity.ps1` + every suite.

### DEPLOY: fix/1417-new-branch-refuse-stale-base

`new-branch.ps1` now **refuses** to cut a branch from a base behind `origin/<trunk>`, where it previously
warned twice and cut anyway. `-SkipStaleBase` cuts from it regardless, and restores the old run exactly --
branch, document, and the warning at both ends.

The refusal costs nothing, which is the argument for it: the check sits before the checkout, so a refused
run leaves no branch, no document, no commit and no push -- nothing to unpick, and one `git pull --ff-only`
resumes the same command. That is the property #1405 named for the fold's own refusal, reached here by a
different route.

It cannot reach a resume. #1046 warned instead of refusing because this file arrives in a consumer by
plugin **update** rather than by choice, landing on the script you are told to re-run to resume a parked
branch. The first half of that stands and is why the escape is one flag; the second does not, because the
base block is gated on *"not resuming"*. The suite now asserts that where it could actually fail -- a
resume on a trunk two commits behind, no valve, exit 0.

`worktree-lane.ps1` passes the valve when it delegates, so lanes behave exactly as before: it fetched and
based the worktree at `origin/<trunk>` seconds earlier, so there is no operator choice to gate, and the
refusal's own remedy (`git pull --ff-only`) is not the remedy for a detached worktree.

Reason: it closes the hazard #1046 measured -- a complete duplicate of already-merged work, branch, commit,
PR and every gate green on both, from a base 17 commits behind. Anyone who cuts a branch this way notices
the day it first refuses.

**Score:** 3

#### What makes this deploy extra special

It settles a question two issues deliberately left open, by reading the code instead of the reports: the
reason `new-branch` held back named a route the refusal provably cannot reach, and the precedent it was
measured against turns out not to refuse the thing it was cited for. Both corrections are written down
where the next reader meets them rather than only in the issue.

**Score:** 2

#### Pull Request

new-branch refuses a stale base, with -SkipStaleBase as the valve

