## fix/1536-boardless-stage-floor

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

Verified all six inbound checks on #1536. Found the missing seam: Test-GithubStatusMap refuses an empty FieldName, so no repo can declare 'we have no board'. The fallback fires on that repo-level declaration, never on a per-issue empty status -- so a repo that HAS a board is byte-identical to today.

#### What the six inbound checks read

All six stood, which is why this is a repair and not a closure. Symptom: `Get-StageFloorForIssue`
returns `Get-StageForProjectStatus`, which answers `$null` for an empty status -- so with no board the
floor is `$null` for every issue. Reason: the `ReadyToTest` promotion in `Resolve-TargetStage` is gated
on `[int]$floor -eq [int]$Map.InReview`, so a `$null` floor also disables it. Repair: the mechanisms it
proposes exist -- `PullRequests` is already on `Get-IssueLinkState`'s object, and `State`/`StateReason`
are already parameters. Size: four writable stages of five are lost (only `NeedsInfo` survives, being
label-driven), so "four rather than three" is right. Subject: the template exists at 4.31.0 as cited.
Repo: the defect is in this tree, which ships it.

#### One thing the report did not see, and it changed the repair

There was **no way for a repo to say it has no board**: `Test-GithubStatusMap` refuses an empty
`FieldName`, so `Resolve-GithubStatusMap` handed such a repo the built-in map naming three columns it
does not have. That matters because `$null` carried **two** facts -- *this repo has no board* and *this
issue is not on the board* -- and only the first may derive a stage. Deriving from the second would
stage every issue a board deliberately leaves off its pipeline, which is the failure
`Select-ProjectStatus` refuses by design. So the fallback fires on the **repo-level declaration**, not
on a per-issue empty status, and the declaration is the empty `FieldName` the validator now accepts.

#### The report's open question, answered as far as this checkout can

Exactly two consumers run `dkj-policy-bwj`: `smartwatchbanden` and `xoxowildhearts`
(`connectors/*.json`). Whether the second uses a board is **not readable from here** -- it is private
and this token carries no `read:project`. So the population is two, and the second is unmeasured rather
than clear.

### CREATE

- [x] `Test-GithubStatusMap`: accept an empty `FieldName` as "this repo has no board", and refuse it
      beside a `Statuses` table that still names columns -- a half-finished edit must not read as either.
- [x] `Get-StageFloorForIssue`: on that declaration only, derive the floor from the issue -- closed ->
      `InReview`, open with a linked pull request -> `InDevelopment`, open without -> `Filed`, no state ->
      `$null`. The `not_planned` guard is checked first, so it outranks the fallback too.
- [x] Thread `-HasLinkedPullRequest` through `Resolve-TargetStage` into the floor, and give the log a
      `Why` that says the stage came off the issue, so a move stays attributable.
- [x] Both call sites (event mode and sweep (d)) pass it from `@($link.PullRequests).Count -gt 0`.
- [x] `Invoke-StageSweep`: one loud line when **every** carded issue derived no stage, naming the three
      reasons it can be. This is the report's alternative proposal, kept alongside the fallback because it
      covers a case the fallback does not -- an unreadable project field, or unmapped columns.
- [x] The docs that were wrong rather than merely thin: the template header (which advised a token where
      there is no board to read), `WORKFLOW-portable.md`, the plugin `README.md`, and
      `adopt-dkj-policy-bwj/SKILL.md` -- whose "three cases to name" is now four, because reporting a
      board-less repo as "the default fits" is exactly the reading that made this silent.

### TEST

- [x] Baseline before the change: 197 asserts green.
- [x] 20 asserts added in `scripts/tests/dkj-policy-bwj.tests.ps1`, 217 green. They cover the four
      board-less derivations, the `not_planned` precedence, the remapped stage map (so the fallback cannot
      be literals), the loud refusal of saying both, and the headline: a closed issue in a board-less repo
      **is** handed back to the submitter.
- [x] Containment asserted explicitly, which is the assert that matters most: where a repo names a
      `FieldName`, `-HasLinkedPullRequest` derives nothing and the column still outranks the issue. The
      September 2, 2026 rule is unweakened.
- [x] Lint gate green: 0 errors, including `[script-ascii]` over 211 scripts.

### DEPLOY: fix/1536-boardless-stage-floor

A repo that runs the Asana mirror without a GitHub Projects board can now say so, and its cards move
again. Giving `Get-GithubStatusMap` an empty `FieldName` and no `Statuses` is that declaration; the
stage floor then comes off the issue itself -- closed means *in review*, an open issue with a linked
pull request means *in development*, an open one without means *filed* -- and no `GH_PROJECT_TOKEN` is
needed, there being no board to read.

**What it repairs is not the three stages it looks like.** With no board the floor was nothing for every
issue, which also switched off the one promotion no column names: *ready to test* is reached from a floor
already at *in review*, so closing an issue stopped handing the card back to the submitter. The close
update still went out -- so the person was told the work was ready while their card never moved, and no
run failed. That is the worst shape of the failure, and it is the fourth stage nobody had written down as
depending on a board.

**A repo that has a board is unchanged, to the line.** The fallback fires on the repo's own declaration
rather than on a missing status, because those were two different facts arriving as one: *no board here*
and *this issue is off the board*. The two-writers race that made the project status the source is
GitHub's own project workflow being the other writer, so a derivation firing only where there is no board
has nothing to race with.

**And the sweep no longer goes quiet.** Where every carded issue derives no stage, one line says so and
names the three reasons it can be -- an unreadable project field, unmapped columns, or a board-less repo
that has not said so. `N card(s) moved` used to read the same on a quiet day as on a run that could not
answer for a single ticket.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo is the source of the plugin, not a store repo that runs the mirror, so no subscriber of
a service notices. The two consumers that do run it are `smartwatchbanden` and `xoxowildhearts`, and the
change reaches them at the next release.

**Score:** N/A

#### Pull Request

Derive the stage floor from the issue where a repo has no project board

