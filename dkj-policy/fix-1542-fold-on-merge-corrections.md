## fix/1542-fold-on-merge-corrections

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

Four inbound issues on the fold-on-merge mechanism, all measured in a BWJ consumer on 2026-09-07 and
all verified against this tree on pickup (symptom, reason, subject, proposed repair):

- **#1542** -- `Format-EntryMergeStamp` renders the merge stamp with `.ToLocalTime()`. Since #1280 that
  stamp is `Get-EntryInsertOffset`'s sort key, so a repo folding from both a UTC runner and a
  maintainer's laptop writes stamps offset by the UTC offset and orders TIER 0 wrong.
- **#1543** -- `fold-on-merge.yml`'s checkout takes the pushed SHA; a fold `ship-pr` already pushed on
  top then reads as unfolded and the trunk-gap guard (#1405) refuses -- a false red on every `ship-pr`
  merge in a queueless consumer.
- **#1544** -- the concurrency group is keyed on `${{ github.sha }}`, its own group every run, so two
  trunk pushes race for the trunk -- and this job pushes.
- **#1539** -- the red-run triage note names two causes; an absent/under-scoped `FOLD_PUSH_TOKEN`
  actually fails `actions/checkout`, a third cause that leaves every later step `skipped`.

#### Approach (Dave, this session): the reporter's recommended repair for each

UTC stamp, `ref: <trunk>` on the fold checkout, constant `${{ github.ref }}` group, three-line doc
correction. The optional preflight step #1539 floats is left out -- no evidence it is needed. Applied
to both this repo's own two workflows and the `adopt-merge-queue.ps1` twins.

### CREATE

- [x] **#1542** -- `Format-EntryMergeStamp` (`scripts/lib/entry-scaffold-lib.ps1`) renders
      `.ToUniversalTime()`; docstring rewritten to lead with the sort-key reason (the stale
      "subtract from the creation stamp" clause, removed by #1335, dropped). `FallbackNow` in
      `scripts/release/fold-changelog-entry.ps1` is a UTC stamp too. Plugin mirrors synced.
- [x] **#1543** -- the first `actions/checkout` in `.github/workflows/fold-on-merge.yml` pins
      `ref: main`; the `adopt-merge-queue.ps1` template pins `ref: <trunk>` from `Get-BranchTrunkName`.
      `verify-resolved` keeps the event SHA (it resolves that push's PRs, no trunk-gap guard).
- [x] **#1544** -- concurrency group on `${{ github.ref }}` in `fold-on-merge.yml`,
      `verify-resolved.yml` and both `adopt-merge-queue.ps1` twins; `cancel-in-progress: false` kept.
- [x] **#1539** -- three-cause triage note in `fold-on-merge.yml`'s header, `verify-resolved.yml`'s
      header, `adopt-dkj-policy/SKILL.md` Part 3, and `adopt-merge-queue.ps1`'s console note; the
      fine-grained-PAT selection trap named. `CLAUDE.md` and the system-administration lens follow
      ("two red runs" -> "the three ways ... goes red").

### TEST

- [x] `entry-scaffold.tests.ps1` -- the `Format-EntryMergeStamp` asserts tightened from an
      adjacent-day tolerance to exact UTC (`20260805-091400`), plus an offset-timestamp case.
- [x] `adopt-merge-queue.tests.ps1` -- new block for the `github.ref` group (both twins), the
      `ref: <trunk>` checkout, and the three-cause console note; section 6 checks the ref follows a
      non-`main` trunk.
- [x] `workflow-concurrency.tests.ps1` -- `fold-on-merge.yml` / `verify-resolved.yml` pinned as a
      third arrangement (shared group, `cancel-in-progress: false`) and the `ref: main` checkout.
- [x] `merge-queue-prereq.tests.ps1` -- the checkout-token regex updated to allow `ref: main` between
      `with:` and `token:`; the "two causes" comment -> "three".
- [x] `check-plugin-integrity.ps1` + all suites green (run by `open-pr.ps1`).

### DEPLOY: fix/1542-fold-on-merge-corrections

`fold-on-merge.yml` and `verify-resolved.yml` -- and the `adopt-merge-queue.ps1` copies a consumer
gets -- had four defects measured in a BWJ store on 2026-09-07. The merge stamp is now rendered in UTC,
so a repo that folds from both a CI runner and a laptop no longer orders its changelog by the
maintainer's timezone (it became a sort key in #1280). The fold runner checks out the trunk tip
instead of the pushed commit, so a fold `ship-pr` already did is not re-attempted into a false red. The
concurrency group is constant per trunk, so two trunk pushes queue instead of racing for a trunk this
job pushes to. And the red-run triage note names the third cause -- an unusable `FOLD_PUSH_TOKEN` fails
the checkout, not the push -- and says to rule that one out first because it leaves no fold step to
read. Stamps written before this change stay local; the insert walk stops at the first older stamp, so
the skew is bounded to entries adjacent across that boundary until they age out at the next cut.

**Score:** 3

#### What makes this deploy extra special

N/A -- internal workflow mechanics. No subscriber of any service notices; the visible effect is that a
consumer adopting the merge-queue floor stops meeting a false red on their first `ship-pr` merge and a
maintainer outside UTC stops seeing changelog entries land out of order.

**Score:** N/A

#### Pull Request

Correct fold-on-merge's merge stamp, checkout ref, concurrency key and failure-mode docs

