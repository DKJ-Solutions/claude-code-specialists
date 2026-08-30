## Development: `fix/gate-tree-moved-under-run-v1` · 20260830-142054

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

Issue #1145: a suite went red inside a backgrounded ship's test gate and green standalone on the same
commit seconds later, while `prune-merged.ps1` borrowed the trunk in the same checkout. The report filed
the measurement and named three candidate remedies without choosing one.

#### Which of the three, and why

- **Refuse when `HEAD` has moved** -- taken, as a REPORT rather than a refusal. A red still blocks the
  push; what changes is that the reader is told the red is untrustworthy.
- **A checkout lock for the duration** -- dropped. It needs a protocol across six tree-moving scripts plus
  stale-lock handling, to prevent a collision the workflow itself invites (`prune-merged` is what Chris's
  lens tells a session to run mid-assignment). Detection costs two git reads.
- **Say it where the ship is documented** -- taken as well, because the two documented instructions
  genuinely collide and neither page said so.

#### What the fingerprint alone could not do

`Get-GateFingerprint` already exists and is taken before the gates. Compared again afterwards it would have
seen NOTHING in the measured case: a borrow hands the checkout back, so HEAD, the branch and every tracked
file are identical at both ends. The reflog depth is where the two moves are recorded, so the check reads
both.

### CREATE

- [x] `gate-lib.ps1`: `Get-GateHeadMoveCount` (HEAD's reflog depth, per-worktree) and
      `Get-GateTreeMovedNote` (fingerprint + depth -> the sentence, or `$null`)
- [x] `open-pr.ps1`: read the depth once beside the fingerprint; ask on both gates and both verdicts --
      a red warns, a green warns AND is not recorded as gate evidence
- [x] `ship-pr.ps1`: step 1 states that it is the only step reading the working tree, and therefore the
      one window in which this checkout is single-occupancy
- [x] `contributing-davekjohn/CONTRIBUTING.md`: the collision named where backgrounding is documented
- [x] mirrors rebuilt (`build-shared-scripts.ps1`)

### TEST

- [x] `gate-lib.tests.ps1` case 12: the borrow is caught, the fingerprint provably is not enough on its
      own, both verdicts word themselves differently, an unmeasurable reading claims nothing, and open-pr
      asks on all four paths with the save in the `else`
- [x] full suite green, lint green

### DEPLOY: `fix/gate-tree-moved-under-run-v1`

A gate whose tree moved while it ran now says so. `open-pr`'s lint and test gates read the working tree for
a minute or more, and that checkout is not private to them: a backgrounded `ship-pr` hands the session its
prompt back, and the session is told by name to run `prune-merged.ps1`, which borrows the trunk and hands it
straight back. Measured on PR #1144 -- one suite of 55 red inside the gate, green standalone on the same
commit seconds later. A false red is the expensive half, because this repo's own rules tell a session that a
suite red under the gate is reporting a real defect until proven otherwise.

Each gate is now asked afterwards whether the tree held still: a **red** says it is not trustworthy and
names the usual cause, and a **green** is reported and NOT recorded as gate evidence, so the next run gates
for real instead of skipping on a pass nothing judged. Neither is a refusal -- a red still blocks the push,
and the remedy is to re-run. The check reads two signals because one is blind: a borrowed checkout comes
back, leaving the fingerprint identical, so `HEAD`'s reflog depth is read beside it.

**Score:** 3

#### What makes this deploy extra special

A consumer running `open-pr` gets the same sentence, and the workflow page now states plainly that the
primary checkout is single-occupancy while a gate is running -- the one thing neither `ship-pr`'s page nor
the lens that recommends `prune-merged` had said.

**Score:** 2

#### Pull Request

a gate whose tree moved under it says so, and its pass is not recorded

