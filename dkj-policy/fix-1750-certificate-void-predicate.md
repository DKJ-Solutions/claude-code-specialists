## fix/1750-certificate-void-predicate

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### The finding, and what it turned out to be

`ship-pr.ps1`'s step-3b block records `certificate voided, after #1592's fold discount -- 25 of 99
(25.3%)` and states no window, no window end and no population. A re-measurement over the same four
days scored 1.6%, a factor of ~15 apart, and #1750 filed that as *unreconciled* rather than wrong.

The predicate turned out to be recoverable -- it is in #1602's own thread, just never in the block --
which is what makes the rest of this branch arithmetic rather than argument.

### CREATE

- [x] Recover #1602's predicate from its own thread: window `[run.created_at,
      last_check.completed_at]`, n=99 `ci.yml` `pull_request` laps, `2026-09-05 17:58Z ..
      2026-09-08 10:51Z`, refused laps included, discount by the real `Test-IsFoldOnlyCommit`
- [x] Write that predicate into the step-3b block beside the number, with the unreconciled second
      measurement and the bound on the window's share
- [x] Same in `.claude/specialists/lenses/06-25-extension.md`, the only other live carrier of the row
- [x] Regenerate the plugin mirror (`scripts/sync/build-shared-scripts.ps1`)

### TEST

- [x] Measured the trunk's own fold share over the disputed window with the real classifier:
      **114 of 255 first-parent commits (44.7%)**, corroborating `Test-IsFoldOnlyCommit`'s own
      docstring (71 of 169, 42%, over an overlapping window)
- [x] Verified the report's #1715 inference against #1715 itself -- it does NOT hold for the recorded
      rows, so the block answers it rather than repeating it
- [x] `check-plugin-integrity.ps1` + all suites, via `open-pr.ps1`

### DEPLOY: fix/1750-certificate-void-predicate

`ship-pr.ps1`'s step-3b measurement now states the predicate beside the number -- population, window
start, window end, what counts as voided, and which classifier applied the fold discount -- so the
next re-measurement of the certificate-voiding rate is a comparison rather than a fresh argument. The
values were never lost: they are in
[#1602](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1602)'s thread and only the
block was silent, which is the whole defect.

It also records that the `25 of 99 (25.3%)` row is **unreconciled** with a re-measurement scoring
`3 of 193 (1.6%)` over the same four days, and narrows where the disagreement lives. The window is the
obvious suspect, and the table bounds its share at 5 -- tail-only is 5, tail-and-before is 0 -- so
narrowing to the required check's conclusion moves 25.3% to 20.2% and no further. The residual is in
the fold discount: 12 of 37 raw voidings discounted here (32%) against 39 of 42 there (93%), measured
against a trunk that ran **114 folds in 255 first-parent commits (44.7%)** over those same four days
by the real `Test-IsFoldOnlyCommit`. Neither pass is shown wrong and the direction is identical in
both, which is all #1602's decision rested on -- but a decision *sized* off 25.3% is being sized off
the open half, and the block now says which half that is.

One inference in the report is answered rather than transcribed. It read
[#1715](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1715) as having retired the
window these rows describe; read against #1715, it has not. Dropping ship-pr's third local gate run
shortens the stretch between a green certificate and the merge attempt, so it does lower how often
the gate *actually* refuses -- but the rows count commits inside a window bounded by CI's own check
timestamps, and the run #1715 removed happens after the last of them. Repairing on the reported reason
would have put a wrong claim into the block with a citation attached.

**Score:** 2

#### What makes this deploy extra special

N/A -- `ship-pr.ps1` reaches a consumer through the plugin mirror, but the change is entirely inside a
comment block: no behaviour moves, no gate changes its verdict, and nothing a consumer runs reads it.
What travels is the reasoning a maintainer meets when they next open step 3b.

**Score:** N/A

#### Pull Request

Record the certificate-voiding measurement's predicate beside the number

