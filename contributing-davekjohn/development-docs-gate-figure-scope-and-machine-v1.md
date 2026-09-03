## Development: `docs/gate-figure-scope-and-machine-v1` · 20260903-154734

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

[#1314](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1314): a gate wall-clock figure
gets written down with no statement of **what** was measured (a lint gate and a test gate summed, or one
alone) or **where** (a 16-lane developer box, or the four-core CI runner), and is then re-quoted as a
constant. The three figures the issue names die at the fold, so the durable half is a convention, not a
repair to that branch's document. The issue's own comment sets the second question: whether a DEPLOY
section -- which *does* fold into the trunk -- may quote a local figure at all.

#### Where each half goes

Per the source-is-the-default rule in `CLAUDE.md`, both halves are portable and neither belongs in a
lens: a consumer running these gates meets this on day one. The lens gets the measurement that makes
them worth following.

### CREATE

- [x] The portable measurement rule, in Nolan's manual
      (`plugins/teams/team-alpha/manuals/06-25-manual.md`): *"A gate figure names what it included and
      which machine produced it"*, placed as the last of the measurement-discipline rules. Named by its
      **axis** rather than an ordinal -- the four above it fail on the unit, the sample, the factor and
      the copy, this one on the scope and the machine -- because "the fifth sibling" was written first
      and does not survive a count: the third of them already calls itself *"the third sibling ... of the
      three"*, so an ordinal here would have been the mis-sized-finding pattern this repo keeps
      measuring.
- [x] The DEPLOY-section half, as rule 8 in
      `plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md`: a figure quoted there names its
      scope and its machine, and where the claim is about the gate that *blocks the merge*, that job's
      own figure is the one to quote -- it is a population where a local reading is a single draw. It
      answers the issue comment's second question with "yes, with both facts named", not with a ban.
- [x] The evidence, in Nolan's lens (`.claude/specialists/lenses/06-25-extension.md`): the three figures
      with what each one's own wording covered, this repo's CI re-measured per step over n=12, and the
      pointer to where the two rules now live.

### TEST

- [x] The CI figures are this session's own measurement, not the report's: the twelve most recent
      successful `lint-en-tests` runs on the trunk, per step from
      `/actions/runs/<id>/jobs` -- lint 20/30/35s and suites 656/906/949s (min/median/max), 676/936/983s
      together. The report's single run (27s + 825s = 852s) sits inside every one of those bands, which
      is what makes it a draw rather than a contradiction.
- [x] Two of the report's own claims were checked and corrected rather than carried: the suite count is
      **62** today, not the 61 the branch measured, so no figure here is anchored to a suite count; and
      run `33758987818` ran on `docs/traps-count-closing-line-v1`, not on the reporting branch's base as
      the report has it -- so its figures are cited as a CI reading of the trunk-derived tree, and the
      n=12 median carries the argument instead.
- [x] The local parts (75s lint, 401s suites at sixteen lanes) are attributed to the report throughout
      rather than re-run. Re-running them proves nothing `open-pr`'s own gate will not, and pre-running a gate
      is the waiting rule's own named waste.
- [x] And the run that dropped step produced the sharpest instance the rule has: `open-pr`
      measured **all 62 suites in 89s** at sixteen lanes -- same machine and same day as the
      report's 401s, a **4.5x** spread with no code between them, larger than the local-vs-CI
      factor this branch leads with. Added to the lens' evidence section; DEPLOY is left
      untouched, because the PR published it and the DEPLOY lock reads that section at the merge.
      The tooling half -- `Invoke-TestSuiteGate` prints the lane count only on its opening line,
      never on the summary line a session actually quotes, which is the shape #1314's three
      figures have verbatim -- is filed as
      [#1318](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1318) rather than
      fixed here: script change, wants a test, and this branch is documentation.
- [~] Dropped: "lint + the full suite set green" is not a step by rule 5 of
      `DEVELOPMENT-portable.md` -- `open-pr` runs both gates as part of the push, so at the moment
      the step gate reads this list the step cannot be done, and ticking it would report a result
      that does not exist yet. It is what the run reports, not what the branch plans.

### DEPLOY: `docs/gate-figure-scope-and-machine-v1`

A wall-clock figure for a gate reads as though it describes the gate. It does not: it describes one run,
and two facts that the number never implies decide what it is worth to anybody else -- **what ran inside
it**, and **which machine ran it**. One branch made the case by writing three *"full gate"* figures for
one test set (608s, 471s, 360s), of which the first bundled the lint gate with the suites and the other
two, by their own wording, did not; all three were then quoted as answering the same question.

Two rules now say so, both portable. Nolan's manual carries the measurement discipline -- name the
components and give them separately as well as summed, name the machine and its lane count, and never let
a local reading stand in for the gate that blocks the merge, whose own history is queryable.
`DEVELOPMENT-portable.md` rule 8 carries it for the DEPLOY section specifically, because a figure written
there folds into `CHANGELOG.md` and onward into a release document, outliving the branch that measured
it.

The measurement behind them is in Nolan's lens, and its second half is the one that changes how a
disagreement gets read: this repo's CI, measured per step over the twelve most recent trunk runs, costs
**936s** median (lint 30s, suites 906s) on four cores against ~476s locally at sixteen -- about 2x -- but
its own band is **676-983s**. That 1.45x spread inside one environment is *wider* than the 360-608s
spread the three branch figures were being reconciled across. So the disagreement they looked like was
never large enough to be a finding, and scope and machine have to be settled before a gap between two
figures counts as one.

Closes [#1314](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1314).

**Score:** 3

#### What makes this deploy extra special

Both rules travel by plugin update, and the discipline is one a consumer needs the first time it writes a
gate timing into a changelog entry -- which is the first branch it ships. It changes no script and no
gate, so nothing refuses on it; what it changes is whether a number written on day one is still readable
on day ninety. The figures quoted are the source repo's own and are labelled as such, so a consumer on a
different box has the shape without inheriting the seconds.

**Score:** 2

#### Pull Request

A gate wall-clock figure names what it included and which machine produced it
