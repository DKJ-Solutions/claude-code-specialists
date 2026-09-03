## docs/fold-fixed-filename-cost-stale

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

Repair the one stale reasoning clause #1342 names in `fold-changelog-entry.ps1`'s
`WHICH BRANCH THE ENTRY BELONGS TO` block, plus the one adjacent clause of the same class the
verification turned up. History stays history; only the present-tense framing changes.

#### What was verified before anything was written

The report's claim holds: `Get-BranchFilePaths` builds `contributing-davekjohn/$slug.md`, so the
filename carries the branch again and there is no fixed name left to cost anything. The report's own
spelling of the path (`<branch>.md`) is the one #1339 landed; the intermediate `development-<branch>.md`
from #1255 lived for part of one day. The report is otherwise exact, including that the adjacent
`WHY THE FILENAME IS NOT TRUSTED FOR THIS` paragraph was already brought current by #1340 and needs
nothing.

#### The second clause, found by reading the block rather than the line

Fifteen lines below, the explicit-target arm still said *"the development document is not named after
anything, so it qualifies on being filled."* Same cause, same file, same block -- flatly false since
#1335 -- so it is repaired here rather than filed. What the arm actually tests is unchanged; only the
reason given for it was wrong. `Resolve-BranchFilePath` has already answered which path this branch's
document sits at, and that answer is as often a legacy name as today's, which is the real reason the
name is not what qualifies it.

### CREATE

- [x] Rewrite the framing paragraph: state the live rule first -- the filename is a write convention
      and a read candidate, never the authority -- and demote the fixed-name story to the dated history
      it now is, naming #1335 for the retirement and #1339 for keeping the heading read.
- [x] Correct the explicit-target arm's reason clause.
- [x] Mirror both into `plugins/workflows/contributing-davekjohn/scripts/release/fold-changelog-entry.ps1`,
      which was byte-identical to the source before the change and is again after it.

### TEST

- [x] `check-plugin-integrity.ps1` and every suite, via `open-pr.ps1`'s gate.
- [x] Swept the tree for the same framing elsewhere: `entry-scaffold-lib.ps1:5269`,
      `DEVELOPMENT-portable.md:530` and the two `CHANGELOG.md` hits are all narrating history and are
      correct as they stand. The portable page already carries the *"write convention and a read
      candidate, never the authority"* wording, so the repaired script now agrees with it instead of
      arguing from a cost that no longer exists.

### DEPLOY: docs/fold-fixed-filename-cost-stale

Two present-tense claims in `fold-changelog-entry.ps1` outlived the rename that made them false, and
both are now stated the way the code actually works. The block explaining why the fold reads the branch
from the development document's heading argued from what a *fixed* filename cost -- true from August 23
to September 3, 2026, and retired the moment #1335 gave the document the branch's own name again. It now
leads with the live reason instead: the filename is a write convention and a read candidate, never the
authority, which is the same answer `Resolve-BranchFilePath` gives one level down and buys the same
thing here -- a renamed branch, or a hand-written document under a mismatched name, still folds against
the right PR. The old cost is kept below it as dated history rather than deleted, because it is why the
branch line is in the document at all. Fifteen lines on, the explicit-target arm's claim that the
document "is not named after anything" was corrected the same way.

No behaviour changes: every edit is a comment.

**Score:** 2

#### What makes this deploy extra special

Nothing reaches a consumer's run. The plugin mirror moves with the source, so a maintainer reading the
fold in the plugin cache gets the same corrected reasoning -- which is the whole point of repairing a
comment that a later reader would otherwise take as the current argument and defend.

**Score:** 1

#### Pull Request

Correct the stale fixed-filename framing in the fold's branch-owner block

