## fix/1584-ship-pr-conflicting-early-exit

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

Inbound #1584. `Wait-CheckRegistration` in `ship-pr.ps1` polled for the full 180s on a CONFLICTING
PR before ever reaching #1247's conflict branch, and the pre-180s path then handed #1234's
close/reopen remedy -- which cannot resolve a conflict. Read the mergeable state ahead of the wait,
refuse a definitive CONFLICTING at once (reusing the existing note builder), and where the conflict
is a folded-entry delete/modify say the branch is spent instead of offering a rebase.

### CREATE

- [x] `ship-pr.ps1`: lift the #1234 / #1247 note-building block into `Get-MissingCheckSuiteRefusalNote`, shared by the early exit and the timeout
- [x] `ship-pr.ps1`: read `gh pr view --json mergeable` before the poll loop; refuse immediately on a definitive `CONFLICTING`, fall through on `MERGEABLE` / `UNKNOWN`
- [x] `ship-pr.ps1`: `Test-BranchEntryAlreadyFolded` -- augment the refusal when `main` carries a commit that deleted the branch's own `dkj-policy/<slug>.md`
- [x] mirror both into `plugins/dkj-policy/scripts/release/ship-pr.ps1`, LF-identical (shared-script drift lint)

### TEST

- [x] `pr-issues.tests.ps1`: `#1584` block -- early-exit call site, shared builder called twice, mergeable read before the loop, folded-entry augmentation
- [x] `check-plugin-integrity.ps1` green (parse + shared-script drift)
- [x] full test-suite gate green (exit 0)

### DEPLOY: fix/1584-ship-pr-conflicting-early-exit

`ship-pr` now refuses a CONFLICTING pull request the instant it starts waiting for CI, instead of
after the full 180s check-registration timeout. A conflicting PR has no `refs/pull/<n>/merge` for a
`pull_request` workflow to run against, so no check suite can ever register for it -- a state GitHub
reports the moment the PR exists, which made the wait pure cost. The refusal reuses the existing
#1247 diagnosis (resolve the conflict; a close/reopen was measured doing nothing), and where the
conflict is a branch whose changelog entry has already folded on `main`, it says the branch is spent
and the follow-up belongs on a fresh branch off the trunk -- rather than a rebase that just re-adds a
folded entry.

**Score:** 3

#### What makes this deploy extra special

N/A -- internal shipping-workflow tooling; no subscriber of a service is affected.

**Score:** N/A

#### Pull Request

Refuse a CONFLICTING PR up front instead of after the 180s check-registration wait

