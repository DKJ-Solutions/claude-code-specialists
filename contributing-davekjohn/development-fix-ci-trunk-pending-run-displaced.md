## Development: `fix/ci-trunk-pending-run-displaced` · 20260903-133935

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

Fix issue #1294: half the trunk's merge commits are never gated because a shared concurrency group
drops a superseded PENDING run, which `cancel-in-progress` does not govern. Key the group per-commit
for pushes; leave the PR side untouched.

#### What the verification found, beyond the report

The report's symptom and mechanism both hold, and one thing it did not claim turned out to be true as
well: **it was never only folds displacing merges.** Reading every push run on `main`, not only the
`merge:` ones, shows chains -- `0ab47d2d`, `2c54de74`, `e0175372` and their neighbours all displaced in
sequence -- so on a busy trunk only the **last push of each ~15-minute window** ran at all. That widens
the subject from "the fold cancels the merge" to "a shared group loses everything but its newest
arrival", and it is why the repair keys the group rather than adjusting the field.

### CREATE

- [x] Verify #1294 against the tree before repairing it: reproduce the 14/28 count, and check the
      inferred mechanism. Confirmed -- run `33742497546` (merge `371af75b`) had **zero jobs allocated**,
      so it was dropped from the queue rather than killed mid-run, which no reading of
      `cancel-in-progress` covers.
- [x] `.github/workflows/ci.yml`: key the concurrency group on `github.sha` for pushes and keep
      `github.ref` for pull requests. Rewrite the comment above it -- the old one named the right
      hazard and the wrong mechanism, which is what made the wrong guard look considered.
- [x] `.github/workflows/unfolded-entry.yml`: update the comment that explained ci.yml's opposite
      choice, and say that its own `cancel-in-progress: true` is now the only one doing that work.
- [x] `scripts/lib/entry-scaffold-lib.ps1`: the `Get-UnfoldedTrunkEntry` docstring credited "the CI
      workflow's cancel-in-progress" for swallowing the ship window. Name the workflow that actually
      does it. Mirror regenerated with `build-shared-scripts.ps1`.
- [x] `plugins/teams/team-alpha/manuals/05-15-manual.md`: the portable half as a hard rule -- a
      `concurrency` group's guarantee is not what `cancel-in-progress` says. Goes in the shared source,
      not the lens, per CLAUDE.md's source-is-the-default rule.
- [x] `.claude/specialists/lenses/05-15-extension.md`: the repo-specific half on the `ci.yml` bullet --
      this repo's trunk rhythm is what made the general fact bite, plus the measurement and the cost.
- [~] Reduce the runner-minute cost by skipping `ci.yml` on the fold commit. Dropped from this branch
      and filed as [#1300](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1300): it is
      a coverage *reduction* with its own trade-offs, and bundling one into a correctness repair against
      a guard that already had its mechanism wrong once is the move to avoid.

### TEST

- [x] `scripts/tests/workflow-concurrency.tests.ps1`, new -- 12 asserts pinning the grouping **key**
      in both workflows and in both directions. The key is the subject, not the field: an assert on
      `cancel-in-progress` alone would have been green throughout the whole defect.
- [x] Mutation-checked, because a test that cannot fail is worth nothing here. Reverting the key to
      `github.ref` turns exactly the two load-bearing asserts red and exits 1; restored afterwards.
- [x] Lint gate: `0 error(s)` (30 checks, including `[script-ascii]` over the new suite).
- [x] Full suite gate: **all 62 suites passed in 89s** -- 61 before this branch.
- [~] Not a branch step: `lint-en-tests` on the PR runs only once the branch is pushed, and `ship-pr`
      waits on it before merging. Listed here would have held the push open forever.

#### What cannot be tested here, and is a real gap

**No assert can prove the runs stop being displaced** -- that property is only observable in GitHub's
run history, after the fact, on a trunk moving fast enough to produce the collision. The suite pins the
input (the key) and not the outcome. So the confirmation is a reading rather than a check: after the
next few ships, a push-event run listing for `main` should show a conclusion for **every** push, with no
`cancelled` rows. Flagged rather than papered over.

### DEPLOY: `fix/ci-trunk-pending-run-displaced`

`.github/workflows/ci.yml` now keys each push to `main` on its own commit (`github.sha`), so no trunk
commit's CI run shares a concurrency group with any other push. Pull requests are untouched -- still
keyed on `github.ref`, still cancelling superseded runs, so the ~7m40s reruns PR #933 measured stay
saved.

**What was wrong.** The block keyed one group on the ref, i.e. one group for the whole trunk, and relied
on a conditional `cancel-in-progress` to stop the fold commit cancelling the merge commit's run. That
field governs only the **in-progress** run. A concurrency group also drops a **pending** one when a third
arrival queues into it, and that path does not consult the field at all -- so the guard could not cover
the way the cancellation actually happened. Measured over the 28 most recent `merge:` commits on the
trunk: **14 `success`, 14 `cancelled`**. Half the trunk's merge commits had never been gated. The
cancelled runs had **zero jobs allocated**, which is the proof they never left the queue: run
`33742497546` (merge `371af75b`, PR #1268) was created `10:06:15Z` and cancelled `10:06:23Z`.

**And it was never only folds displacing merges**, which is what the reading beyond #1294's report added:
`0ab47d2d`, `2c54de74` and `e0175372` went down in one chain, so on a busy day only the **last push of
each ~15-minute window** ran. The tip was always gated; nothing between it and the previous tip ever was
-- which is why that day's two `failure` runs on `main` named no commit.

`.github/workflows/unfolded-entry.yml` keeps the opposite arrangement on purpose (a shared trunk group,
`cancel-in-progress: true`): it is required by nothing and superseding its run is how the ~6s ship window
stops reading as a stale red. Its comment, and the `Get-UnfoldedTrunkEntry` docstring in
`entry-scaffold-lib.ps1`, both credited *ci.yml's* field for that swallowing; both now name the workflow
that actually does it.

New suite `scripts/tests/workflow-concurrency.tests.ps1` pins the grouping key in both workflows and in
both directions -- 12 asserts, mutation-checked. The subject is deliberately the **key** and not the
field: an assert on `cancel-in-progress` would have been green for the entire life of the defect.

**The cost is deliberate.** Every push to `main` now runs, where roughly half were dropped: 27 runs where
13 ran, on September 3. Whether the fold commit needs a full run of its own is left open as
[#1300](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1300).

The lesson is split per CLAUDE.md's source-is-the-default rule: the portable fact (`cancel-in-progress`
governs the in-progress run only) is a hard rule in Sylvester's manual, the repo-specific half (this
trunk's rhythm is what made it bite) is on the `ci.yml` bullet of his lens.

**Score:** 4

#### What makes this deploy extra special

N/A -- CI plumbing for this repo's own trunk. No subscriber of any service reaches it. The portable half
does travel to consumers, as a hard rule in the system-administration manual, but it is a rule for
whoever maintains a workflow rather than anything a subscriber sees.

**Score:** N/A

#### Pull Request

Trunk pushes each get their own CI concurrency group, so no merge commit's run is displaced while pending
