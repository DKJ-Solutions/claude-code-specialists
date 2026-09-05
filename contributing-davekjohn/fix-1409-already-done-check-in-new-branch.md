## fix/1409-already-done-check-in-new-branch

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

Give new-branch.ps1 an optional -Resolves so Get-TargetIssueWarnings runs before the checkout, not only at open-pr time (issue #1409).

### CREATE

- [x] `new-branch.ps1`: add `-Resolves`, dot-source `pr-issues-lib.ps1`, and run the already-done
  check (`Get-TargetIssueWarnings`) before the checkout, warning twice (before + as the last line)
  exactly like the stale-base check, and skipping cleanly when `Get-RepoName` is not configured.
- [x] `new-branch.tests.ps1`: section (x), 15 new asserts against a fake `gh` on PATH -- the skip
  path, the negative control, a closed issue, a rival claiming PR, two issues where only one is
  done, and both gh calls failing independently.
- [x] Two other fixtures that copy `new-branch.ps1` (`entry-scaffold.tests.ps1`,
  `worktree-lane.tests.ps1`) were missing the new mandatory dot-source and failed with a raw
  path-not-found until `pr-issues-lib.ps1` was added to them too.
- [x] `new-branch` skill page: documented `-Resolves` (issue #1409 section), which is also what
  cleared the `[skill-param]` lint finding.
- [x] Plugin mirror re-synced (`scripts/sync/build-shared-scripts.ps1`), which is what cleared the
  `[shared-script]` lint finding.

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors.
- [x] `scripts/sync/check-script-contract.ps1` -- 0 errors (unrelated pre-existing INFO signals only).
- [x] The full test gate, all 68 `scripts/tests/*.tests.ps1` suites -- 68 passed, 0 failed.

### DEPLOY: fix/1409-already-done-check-in-new-branch

`new-branch.ps1` takes an optional `-Resolves "<n[,n...]>"` and runs the same already-done check
`open-pr` already ran (`Get-TargetIssueWarnings`, from #1282) -- but before the checkout, not after.
Issue #1409 measured what the old timing cost: a branch correctly claimed for #1402 was cut, given
two commits, a full development document and two subagent reviews plus 65 test suites, only to learn
from `open-pr`'s own warning that a rival PR had already closed #1402 seven minutes after the claim.
Passed here, the same finding surfaces before any of that is spent. It warns and never refuses -- a
shared number, a reopened issue, or an abandoned rival PR must not wedge a real branch -- and, like
the stale-base warning beside it, is printed twice so the scaffold and the push cannot bury it. `gh`
is asked for only when `-Resolves` is given, so every other run stays exactly as offline-usable as
before.

**Score:** 3 -- a consumer who reaches for `-Resolves` sees a real branch's worth of wasted work
avoided the moment they touch it; every other call is untouched.

#### What makes this deploy extra special

Nothing beyond the deploy itself -- N/A.

**Score:** N/A

#### Pull Request

Warn on an already-done issue before new-branch.ps1 cuts anything

