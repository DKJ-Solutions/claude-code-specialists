## docs/changelog-merge-queue-settled

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

Fix [#1360](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1360): pending entries in
`CHANGELOG.md` still describe the merge-queue decision for `main` as open, after
[#1355](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1355) settled it on
September 3, 2026 as **no queue**. These entries sit under `## [Unreleased]`, so they are copy for the
next release note rather than history -- published as-is they tell a consumer a settled decision is
pending and point at the closed #1325 instead of #1355.

#### The bar, from the issue

Reword rather than delete. *"It could land while the decision was open"* is still the reason #1351's CI
restructure needed no ruleset edit, and that reasoning is worth keeping. No mechanism changes.

#### One of the issue's exclusions did not hold

The issue's *"What is NOT stale"* section put `CHANGELOG.md:418`'s *"and is Dave's call"* down to
`strict_required_status_checks_policy`. Read in context it attaches to *"the
keep-`strict`-or-adopt-a-merge-queue **decision**"*, which is exactly what #1355 answered -- so it is
stale and is repaired here. The genuinely-still-Dave's `strict` sentence the exclusion meant is a
different one -- `fix/ship-pr-stale-base-check`'s *"it is a repo-settings change and therefore
Dave's"*, about enabling `strict_required_status_checks_policy` -- and it is left untouched.

### CREATE

Addressed by entry rather than by line number, because every fold moves the lines.

- [x] #1351's CI-sharding entry -- past-tense the open decision and name #1355 as what settled it,
      keeping the no-ruleset-edit reasoning and both throughput figures.
- [x] `docs/record-strict-ci-gate`, closing paragraph -- replace *"stays open on #1325"* with the
      answer, and say it was a no on price rather than feasibility.
- [x] `feat/merge-queue-prerequisites`, opening paragraph -- the switch is still Dave's, but he answered
      it; say so, and say the two prerequisites stay in the tree deliberately.
- [x] `docs/record-strict-ci-gate`, mechanism paragraph -- the mis-excluded line above, repaired.
- [~] `feat/merge-queue-prerequisites`, score reason (*"the queue decision on #1325 stops being blocked
      on work nobody had scoped"*) -- left as written. It states what that change unblocked at the time
      and asserts nothing about the decision being open, so it reads correctly as history.

### TEST

- [x] Verified the symptom before repairing it: both lines the issue names still read exactly as filed,
      and #1325 and #1355 are both `CLOSED`.
- [x] Swept `CHANGELOG.md` for every `#1325` / `merge queue` / `stays open` mention rather than trusting
      the issue's inventory -- which is how the fourth line and the bad exclusion were found.
- [x] Lint + test gates via `open-pr.ps1`.

### DEPLOY: docs/changelog-merge-queue-settled

Four pending entries under `## [Unreleased]` said the merge-queue decision for `main` was still open, and
pointed at the closed [#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325)
rather than at [#1355](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1355), where Dave
answered it on September 3, 2026: **no queue** on `main`, on price rather than feasibility. All four now
carry the answer. Each was reworded rather than cut -- *"it could land while the decision was open"* is
still the reason #1351's CI restructure needed no ruleset edit, and the two prerequisites in the tree are
still there on purpose, so a future yes inherits them.

[#1360](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1360) named two of the four and
excluded a third on the reading that its *"and is Dave's call"* was about
`strict_required_status_checks_policy`. It is not -- in context it attaches to the merge-queue decision
itself -- which is why the repair swept the file instead of applying the two line numbers it was handed.
The `strict` sentence that exclusion meant is a different one and is untouched, because that setting
really is unflipped and really is Dave's.

**Score:** 3

#### What makes this deploy extra special

An entry under `## [Unreleased]` is not history yet -- it is **copy**, and the release cut publishes it
verbatim. So a claim that was accurate the day it was written has a second correctness deadline the tree
does not: the day the release goes out. Nothing gates that. #1355's own chain repaired both stale claims
it made *in the tree* and left four in the file whose whole purpose is to be published, because the
entries were already folded and the trunk copy is writable only under the bounded fold exception.

The generalisable half: **a decision that closes an issue makes every pending entry citing that issue
stale, and the branch that takes the decision is the one holding the list.** Grepping the changelog for
the issue number it just closed is a step the deciding branch can run in seconds; a later reader has to
reconstruct which claims were true when. And an issue reporting this class is an inventory rather than a
specification -- three of the four here differed from what it named, one of them because it had reasoned
past the right sentence.

**Score:** 1

Nothing a subscriber runs changes. What they get is a next release note that does not tell them a
settled decision is pending -- and it prevents a failure that had not happened yet only because the cut
had not happened yet.

#### Pull Request

Reword the four pending entries that still call the merge-queue decision open
