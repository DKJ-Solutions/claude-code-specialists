## Development: `feat/asana-mirror-prio-labels-v1` · 20260902-090706

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

A: adopt-bwj-asana creates the four prio labels. B: a new reconcile pass walks this repo's OPEN issues, resolves each to its Asana task with the existing 3-matcher resolver, reads the Prio-Score custom field by name, and sets the one matching label while removing the other three. Reconcile only -- a close/reopen event says nothing about priority. Needs issues: write.

### CREATE

- [x] Five functions in `templates/asana-mirror.ps1`: `Get-PrioLabelForScore` and
      `Get-PrioScoreFromTask` (both pure), `Get-OpenIssues`, `Set-IssuePrioLabel` and the
      `Invoke-LabelSweep` pass that drives them
- [x] `Get-AsanaTaskState` gained an `-OptFields` parameter defaulting to its current behaviour, so
      the sweep asks for the custom fields through the existing reader instead of a near-duplicate
- [x] `$script:PrioLabels` is the single source for the four names -- the mapper returns them and the
      enforcer removes them, and a test asserts the two cannot drift
- [x] `-PrioFieldName` (default `Prio-Score`) reads the field by NAME, not GID: the GID differs per
      workspace, so a name needs no repo variable of its own
- [x] `templates/asana-mirror.yml`: `issues: write`, the only write this workflow makes outside Asana
- [x] `adopt-bwj-asana` step 4 creates all four labels -- `gh issue edit` fails on a missing label, so
      that step and the sweep had to ship together
- [x] `WORKFLOW-portable.md`: a new step 5 for the direction, the old step 5 renumbered to 6 and its
      one broken back-reference repaired; `README.md`'s rule paragraph names the new direction
- [x] The four labels in both store repos re-described to the skill's English wording, so the
      prescription and the reality carry one text

### TEST

- [x] 22 asserts added to `scripts/tests/bwj-codex.tests.ps1`; the suite is green at 92, up from 70.
      Every bucket boundary is asserted from both sides (1.99/2.00, 2.99/3.00, 3.99/4.00), plus both
      absences, the mapper/enforcer agreement, and the no-op path that keeps a re-run quiet.
- [x] Culture-invariance measured rather than assumed: this machine runs nl-NL, where the decimal
      separator is a comma. `[double]'3.5'` reads as 3.5 and not as 35, and `ConvertFrom-Json` hands
      back a `Decimal` that casts cleanly. One assert pins it.
- [x] Lint gate + all suites via `open-pr.ps1`, exactly as CI runs them

### DEPLOY: `feat/asana-mirror-prio-labels-v1`

The Asana board's prio score now reaches the issue list. The BWJ team scores a task on the
`Prio-Score` number field, 1.00 to 5.00, and the daily reconcile run puts exactly one of four labels
on the matching GitHub issue: `very high` (4.00-5.00), `high` (3.00-3.99), `low` (2.00-2.99),
`very low` (1.00-1.99). Four buckets and deliberately no `medium`.

**Exactly one of them sits on an issue at a time.** The sweep removes the other three as it sets one,
so a ticket rescored from 2.5 to 4.2 loses `low` as it gains `very high` instead of claiming two
priorities at once. An issue that already reads correctly is not written to, so the daily re-run is
quiet rather than chatty.

**It walks GitHub, not the Asana project**, and that is the design decision worth knowing. Two things
follow. It reaches a ticket imported FROM Asana, whose task carries no GitHub back-link for a project
walk to follow -- the same gap the header-row matcher was added for. And it needs no
`ASANA_PROJECT_GID`, so the placeholder project GID both store repos still carry does not block it;
this was going to wait on that repointing and now does not.

**No score means no label, and that is the common case rather than the edge.** Measured on the board
the day this was written: 28 of 96 open tasks carry no `Prio-Score` at all, nothing sits below 2.00,
and 42 of the 68 scored tasks land in `high`. A task with no score, or one outside 1.00-5.00, is left
alone rather than given a guessed label.

**What it does not claim.** Only an issue that resolves to a task gets a label, and in
`smartwatchbanden` roughly 15 of 55 issues carry an Asana link at all -- so the immediate effect is
small and grows as tickets get cross-linked. The direction is also the one exception to this
workflow's "GitHub first" rule, and deliberately not a contradiction of it: priority is the business's
judgement, made on the board and consumed at the workbench. Nothing in this step writes to Asana, and
the guarantee that automation never ticks a ticket off is untouched.

**Score:** 3

#### What makes this deploy extra special

A consumer's issue list starts carrying the business's own priority, which is the first time anything
from the Asana side reaches it. Two things are needed on their end and neither is automatic: re-copy
the two `templates/` files into `.github/` (the workflow now needs `issues: write`), and have the four
labels present -- `adopt-bwj-asana` creates them, and `gh issue edit` fails outright on a label the
repo has not got. Both BWJ store repos already have the labels.

**Score:** 4

#### Pull Request

the mirror carries the Asana prio score across as a GitHub label
