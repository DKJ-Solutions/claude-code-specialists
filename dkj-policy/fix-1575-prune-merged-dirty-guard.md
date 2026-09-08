## fix/1575-prune-merged-dirty-guard

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

Issue #1575: `prune-merged.ps1` refused a dirty working tree unconditionally, on the stated ground of
stepping off the branch you are standing on -- a step (4c) that is unreachable when HEAD is the trunk,
when HEAD is detached, or under `-DryRun`. Verified in the source before repairing: the guard sits at
step 1 and never consults the HEAD it read earlier in that same pre-flight block, and the candidate
list is `refs/heads` minus the trunk, so 4c can only ever match a non-trunk branch.

#### One correction to the report

Its closing line -- *"the suite currently has the dirty case only from a branch"* -- is inverted.
`New-MergedBranch` ends with `checkout main`, so case (d) ran from the **trunk**: the one assert in the
suite for this guard was pinning the state the guard should never have refused. That changed the test
work, not the repair.

### CREATE

- [x] Narrow the guard to 4c's own reachability: not `-DryRun`, and HEAD on a branch that is neither
      the trunk nor detached. `$startBranch` moves above the guard so it can read the HEAD already in hand.
- [x] Report a dirty tree the run proceeds through, naming which of the three reasons made it harmless
      -- so an absent refusal is never read as an absent guard.
- [x] Name the branch in the refusal, and offer `-DryRun` as the read-only way out beside commit, park
      and stash.
- [x] Update the header: step 1's description, the new `THE GUARD IS ABOUT THE STEP-OFF` block, and the
      `-DryRun` parameter note.
- [x] Mirror into the plugin (`build-shared-scripts.ps1`).
- [x] The doc half: the orchestrator's lens is the sentence the issue's "why it matters" is about, so it
      now names `-DryRun` as the route on a dirty branch -- the one state that still refuses.
- [x] And the consumer-facing page for this very script: `plugins/dkj-policy/skills/prune-merged/SKILL.md`
      described the old unconditional refusal. Found by the code review, not by my own doc sweep, which
      had required the script name and the refusal wording on the SAME line.

### TEST

- [x] Re-point case (d) at a **branch**, which is the case the guard genuinely protects, and assert the
      refusal names that branch.
- [x] New case (d2): dirty on the trunk proceeds, reports, and does its actual work -- the #1575 case.
- [x] New case (d3): dirty under `-DryRun` proceeds on a branch, where the same run without the switch
      refuses.
- [x] Full suite green, then the whole gate via open-pr.
- [x] Verified live against this checkout's own unrelated uncommitted `.claude/settings.json`: on the
      branch it refuses and names the branch; with `-DryRun` it proceeds and produces the parked-branch
      report the lens sends a session here for. The trunk arm is fixture-only on purpose -- checking out
      `main` restores the pre-fix script, which is what reproduced the defect at the trunk's HEAD.

### DEPLOY: fix/1575-prune-merged-dirty-guard

`prune-merged.ps1` no longer refuses a dirty working tree on runs that could never move it. The
refusal's own ground is step 4c -- stepping off the branch you are standing on in order to reap it --
and that step is unreachable when HEAD is the trunk (never a reap candidate), when HEAD is detached,
and under `-DryRun` (which deletes nothing). The guard now asks exactly that reachability question, so
those runs proceed; a dirty tree they pass through is reported with the reason it was harmless, rather
than passed over in silence.

This is the command the orchestrator's lens tells a session to run mid-assignment in place of
classifying `git ls-remote` output by hand -- and mid-assignment is exactly when a checkout has
uncommitted work in it, so the guard was blocking the report in the state the advice was written for.
The two ways out it offered are the wrong price for a read: parking commits to a branch, and stashing
touches a file the session was told to leave alone.

Nothing the guard protected is given up. A dirty checkout standing on a non-trunk branch refuses
exactly as before, because that branch can be squash-merged while the work is uncommitted, and that is
the case where the step-off drags it onto the trunk. The refusal now names the branch that makes it
reachable, and offers `-DryRun` beside commit, park and stash.

That last case is why the doc half moved too. The orchestrator's lens and the consumer-facing skill page
for this script now name `-DryRun` as the route for a session standing on a branch with uncommitted
work, which is the ordinary mid-assignment shape: it deletes nothing, so it never has to step off, and
the classification it prints -- the paste-ready delete command for a merged leftover,
`Kept ... -- live work` for everything else -- is identical to the full run's. The skill page had gone
further than stale; it still described the refusal as unconditional, which is what a consumer would have
read.

The suite's own dirty case ran from the trunk, so it had been pinning the defect; it is re-pointed at a
branch, and two cases are added for the arms that now proceed.

**Score:** 3

#### What makes this deploy extra special

N/A -- this is a maintenance script in the development workflow. No subscriber of a service reaches it,
and nothing about a published artifact changes.

**Score:** N/A

#### Pull Request

prune-merged only refuses a dirty tree where the run could actually step off it

