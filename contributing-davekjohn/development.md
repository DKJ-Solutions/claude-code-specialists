## Development: `fix/cut-release-tier-comment-v1` · 20260830-135206

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

Fix #1140: the comment introducing the tier guardrail in `scripts/release/cut-release.ps1` summarises the
rules of the function it is about to call, and both halves of that summary were reversed by Dave on
August 7, 2026 -- a tier-0-only release cuts as a **patch**, and **tier 1 or higher** earns a minor. The
comment still said a tier-1 entry is the minimum for any release and that a minor needs tier 2.

#### The reason was verified against the function, not taken from the report

Read rather than assumed: `Test-ReleaseBumpEarned`'s docstring (`scripts/lib/release-lib.ps1:194-209`)
states both loosenings and dates them, and the code computes `$notable` as `tier -ge 1` at lines 262-263
-- there is no tier-2 test anywhere in the function. The comment at `cut-release.ps1:643-645` said the
opposite. Both halves of the report still stood.

#### The sweep the report deliberately left open

The report said it had **not** checked whether other prose in the tree restates the old ladder, and scoped
that out. Swept here, because a repair that leaves siblings standing is only a third of a repair:
`plugins/workflows/contributing-davekjohn/RELEASES-portable.md:111` states the current rule and names
August 7 as the day it changed, and `scripts/lib/release-lib.ps1:1553` says a bump that writes the tier-1
document needs a tier-1 entry, which is correct under `tier 1 or higher -> minor`. Nothing else. The
report's scope was exactly right, and the plugin mirror -- the only second copy -- is generated.

### CREATE

- [x] `scripts/release/cut-release.ps1`: the three lines now point at `Test-ReleaseBumpEarned`'s docstring
      as the statement of the rules and give only the outline -- the bump follows the highest tier
      pending, and a major additionally needs enough minors behind it.
- [x] And they say **why they do not restate**, with the drift itself as the argument: the old ladder is
      quoted beside what replaced it, and beside that the fact that `release-lib`'s own `$notable` counter
      went stale the same way and was cleaned up on August 12, 2026. That copy sat INSIDE the function and
      still drifted, so a copy two files away at the call site was never going to hold.
- [x] Plugin mirror regenerated via `scripts/sync/build-shared-scripts.ps1` -- the drift lint holds the two
      byte-identical, so a consumer reading their cached copy meets the same text.

### TEST

- [x] Lint gate and all suites green -- the change is comment-only, so what they prove is that nothing
      else moved.
- [~] No new regression test. **Named as a test gap rather than papered over:** the defect is prose drift
      in a free-text comment, and the repair is to stop restating rather than to pin the restatement. A
      gate holding a comment to a docstring would have to compare two pieces of English and would fire on
      every rewording of either -- the shape this repo has scar tissue from, and the reason the
      declined-check reasoning sits above the checks in `check-plugin-integrity.ps1`. The durable guard
      here is the pointer itself: there is nothing left at the call site that can go stale.

### DEPLOY: `fix/cut-release-tier-comment-v1`

The comment introducing `cut-release.ps1`'s tier guardrail now **points at `Test-ReleaseBumpEarned`
instead of restating it**. It existed so a reader would not have to open the function -- and then carried
the pre-August-7 ladder for three weeks after Dave loosened both of its halves: it claimed any release
needs a tier-1 entry at minimum (a tier-0-only release cuts as a **patch**, because publishing to no
audience is what a patch is for) and that a minor needs a tier-2 one (**tier 1 or higher** earns a minor,
because the version speaks to all stakeholders rather than to consumers alone). A reader who trusted it
walked away with a stricter model than the gate enforces, in both directions, and one already had.

The replacement gives the outline, sends the reader one dot-source away for the rules, and states the
drift as the reason it does not restate them -- with the precedent beside it: `release-lib`'s own
`$notable` counter went stale for the same reason and was cleaned up on August 12, 2026. That copy sat
*inside* the function and still drifted, which is the argument that a copy at the call site never could
have held. No behaviour changes: the gate has been doing the right thing throughout and no release was
mis-cut.

**Score:** 2

#### What makes this deploy extra special

N/A -- `cut-release.ps1` does reach a consumer's plugin cache, but this is an internal comment at a call
site. Nothing they run, read in a skill page, or see in output changes.

**Score:** N/A

#### Pull Request

cut-release's tier guardrail comment points at the function instead of restating it
