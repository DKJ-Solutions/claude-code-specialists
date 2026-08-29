## Development: `docs/test-examples-cite-gates-as-coverage-v1` · 20260829-104731

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

- [x] Verify [#1063](https://github.com/DaveKJohn/claude-code-specialists/issues/1063) still stands
      against the tree: both quoted passages were present verbatim in `DEVELOPMENT-portable.md`, and
      `CONTRIBUTING.md` 2.2 does state that the repo's standing gates are not written as TEST steps.
- [x] Grep the whole portable page for sibling claims before touching the reported lines (the
      paired-claims rule): the only other mention of a green gate is the goal-condition example, which
      reads `open-pr reports the lint and test gates green` — that is the gate's own run reported after
      it fired, not a step ticked before it, so it stays as written.
- [x] Check whether `CONTRIBUTING-portable.md` carries the same claim and would need reconciling too:
      it is silent on the subject, so there is no second portable surface and nothing to file.

### CREATE

- [x] Reword the `- [~]` example so it cites the gates as coverage instead of asserting `all green`,
      and drop the stale suite count with it — the invariant is what a later reader can use.
- [x] Add the paragraph that says why a standing gate is cited as coverage, carrying the #1060
      measurement, because a consumer of this workflow never sees the source repo's `CONTRIBUTING.md`.
- [x] Recut "Two shapes are honest" so neither shape invites the hand-run: one reports a result the
      session actually saw, the other names the gate that has not run yet.

### TEST

- [x] Read the repaired section line by line against `CONTRIBUTING.md` 2.2: no sentence left in it
      claims a gate result before the push, and the point the issue asked to keep — `- [~]` means
      "no suite", never "no verification" — is still the paragraph's opening claim.
- [~] no suite: the change is prose in a portable document; the lint gate's link and marker checks
      cover the new reference, and `open-pr` runs them before the push.

### DEPLOY: `docs/test-examples-cite-gates-as-coverage-v1`

`DEVELOPMENT-portable.md` no longer tells you to report the standing gates as an outcome in TEST. Its
`- [~]` example asserted *"all green"* and its "two honest shapes" paragraph opened with *"running the
gates and reporting the outcome"* — both of which can only be answered before the push by hand-running
the very suites the push is about to run, which is the waste
[#1060](https://github.com/DaveKJohn/claude-code-specialists/issues/1060) measured and
[#1062](https://github.com/DaveKJohn/claude-code-specialists/pull/1062) wrote out of `CONTRIBUTING.md`
2.2. The example now cites the gates as **coverage** — true at the moment the step is written — a new
paragraph explains why the outcome form is the weaker answer, and the two honest shapes are recut as
*a result the session has seen* and *a gate named without one*. The point the paragraph existed to make
is unchanged: `- [~]` means "no suite", never "no verification".

**Score:** 2

#### What makes this deploy extra special

The page a consumer reads to learn this workflow's TEST convention stops prescribing a step that their
own `open-pr` would then refuse to push past until they had run their gates by hand. Nothing breaks
without it; it is a minute of gate time per branch and one contradiction fewer between the portable page
and the source repo's own guide.

**Score:** 2

#### Pull Request

TEST examples cite the standing gates as coverage instead of as an outcome
