## fix/1602-step8-report-wording

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

#### Why this is a separate branch and not part of #1602

#1602's work merged as PR #1614. Its own successful ship then printed the defect this branch fixes,
and by then there was nothing left to amend -- so it is a follow-up rather than a fixup.

- [x] Read PR #1614's step-8 output and check the report's wording against what actually happened.

### CREATE

- [x] `Get-CheckWaitReport -PostMerge`: names the check that finished last without claiming it
      governed a merge that has already gone. Everything else on the line is unchanged, because
      everything else is exactly as useful after the merge as before it.
- [x] ship-pr's step 8 passes it; step 3, which runs before the merge, does not.

### TEST

- [x] Both wordings asserted, plus that the switch changes nothing else -- compared by normalising
      the un-switched line and asserting equality, so a switch that quietly dropped the
      not-required label or the excess clause would fail.
- [x] The case PR #1614 happened to hit (the required check finishing last) asserted too, since that
      is why the defect survived its own successful ship.
- [x] Call-site pins for both steps, and the ordering between them.

#### A test-suite trap met on the way, stated precisely

The two call-site asserts were first written above `$shipText`'s own assignment. That failed loudly,
which is how it was found -- and the reason is worth writing down because it cuts both ways:
`$null -like '*x*'` is **false**, so a positive assert placed too early fails; `$null -notlike '*x*'`
is **true**, so a negative one would have passed silently forever.

- [x] Audited the suite for that shape: every `-notlike` in it reads a locally computed value, not a
      source-text variable assigned further down. Nothing to file.

### DEPLOY: fix/1602-step8-report-wording

`ship-pr`'s step 8 no longer reports that a check "governed the merge" after the merge has already
happened. Since #1602 that report is printed after the fold, once the non-required checks have
finally reported -- and on the laps that change is actually about, the check finishing last is the
non-required one, so the line stated the exact opposite of what occurred: the merge went minutes
earlier *because* it no longer waits for that check. The line now names which check finished last and
keeps everything else, including the excess clause that sizes the tail.

**Score:** 2

#### What makes this deploy extra special

N/A -- one sentence of `ship-pr`'s own console output, read by whoever ships a branch.

**Score:** N/A

#### Pull Request

step 8's report no longer says a check governed a merge that already happened
