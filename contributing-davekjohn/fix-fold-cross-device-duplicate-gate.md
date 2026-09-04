## fix/fold-cross-device-duplicate-gate

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

Fetch and refuse a stale trunk before the fold's duplicate gate reads the changelog, and diagnose a rejected push against the fetched remote instead of reporting a bare exit code (inbound #1405).

### CREATE

- [x] `Get-TrunkGap` and `Get-EntryBlocksForBranch` in `scripts/lib/entry-scaffold-lib.ps1` -- the two
      shared measurements, neither of them defining a rule that already lives somewhere else.
- [x] The trunk-freshness pre-pass in `fold-changelog-entry.ps1`, with `-SkipTrunkCheck` as its valve.
- [x] The push-rejection diagnosis, which is the half the report called the one that matters.
- [x] Plugin mirror rebuilt via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `scripts/tests/fold-changelog.tests.ps1` -- four new cases: a stale trunk refused with its count,
      the valve past it, a repo with no origin left alone, the race diagnosed from its far side, and an
      ordinary divergence NOT reported as a duplicate.
- [x] Full local gate: `check-plugin-integrity.ps1` + every suite.

### DEPLOY: fix/fold-cross-device-duplicate-gate

The fold's duplicate gate now reads a trunk it has actually checked, and a refused push says what
happened instead of handing back git's exit code.

`fold-changelog-entry.ps1`'s `ONE BRANCH, ONE ENTRY` gate reads `CHANGELOG.md` from the **working
copy**, and that was the only trunk state it ever saw. On one machine that is the whole truth. Dave
works one repo from more than one device at the same time, deliberately and permanently, so here it was
a snapshot of whatever that checkout last pulled -- and the other device may already have folded the
same branch.

Three things changed, and the third is the one that matters:

1. **The fold fetches before the gate reads.** A new `Get-TrunkGap` in `entry-scaffold-lib.ps1` freshens
   `refs/remotes/origin/<trunk>` and counts `HEAD..origin/<trunk>`.
2. **A trunk behind its upstream is refused**, with the count in the refusal and `-SkipTrunkCheck` as the
   valve. This is where #1046's follow-up lands: `new-branch.ps1` deliberately only *warns*, because a
   stale base under a branch is recoverable with a pull. The fold's next act is a commit **directly on
   the trunk** under a named exception, so the same argument the duplicate gate already makes applies --
   a fold that does not happen leaves the entry exactly where it was, and one pull resumes it.
3. **A rejected push is diagnosed against the fetched remote.** This is the half a pre-pass structurally
   cannot cover: the measured failure was a **race**, not a stale checkout. The trunk was current when
   the gate read it, and the other device folded the same branch inside the window before the push. The
   step used to report `git push exited 1` plus git's generic "the remote contains work that you do not
   have locally" -- the same sentence a plain divergence gives, at the one moment the two situations need
   **opposite** actions. Separating them took five commands typed by a person: a fetch, a log of
   `HEAD..origin/main`, a grep of the remote changelog, a count, and a diff of the two entry bodies. All
   five are derivable at that point, so all five now run.

The verdict is inverted where it has to be: when every entry the commit carries is already upstream, the
advice is **"Do NOT push this commit by hand"** rather than the old *"Push by hand"*, which in the
measured incident would have produced exactly the two-entries-one-branch state #1082 was closed for. The
**bodies** are compared rather than the blocks, because both devices stamp the heading at their own fold
time and a whole-block comparison would report every genuine duplicate as a difference.

It **diagnoses and stops, repairing nothing**, which is the report's own boundary. The fold commit is on
the trunk by then, and every route off a trunk -- a reset, a rebase, a merge commit -- is a history
operation the consumer's safety rules reserve to the operator. That is the expensive half of the measured
incident: a denied rebase, a denied soft reset, an aborted mid-conflict merge on the trunk, and two
commands finally hand-typed by Dave.

Neither new gate can fire on a question it did not answer: `Get-TrunkGap` reports "could not measure" for
a repo with no `origin/<trunk>` ref, and a caller must never read that as "behind" -- every fixture in
this repo's own suite is such a repo.

Inbound #1405, reported from `BWJ-ecommerce/smartwatchbanden` on September 4, 2026.

**Score:** 3

#### What makes this deploy extra special

This is the one that reaches them. Every consumer runs the mirrored fold, and the reporting repo hit a
state its own constitution forbade every route out of -- the tooling put a correct-looking commit on the
trunk and then left the operator unable to resolve it unaided. A consumer working one repo from two
devices now gets told, at the moment the push is refused, whether the work is already upstream and the
local commit redundant, or whether it is real work that has to be integrated. That answer used to cost
five hand-typed commands and, on the day it was measured, did not get made at all.

**Score:** 4

#### Pull Request

the fold reads the trunk across devices, and a refused push says why
