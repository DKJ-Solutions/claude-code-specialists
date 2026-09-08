## fix/1616-go-ahead-trunk-claim

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

#### What the defect is, so the repair is not read as a wording preference

Issue #1616. `ship-pr.ps1`'s step-3 preamble printed the trunk clause of its go-ahead line as a
literal, with no condition on it and no reference to what step 2b decided. Step 2b has three
outcomes and only one of them moves `HEAD`, so on the other two the go-ahead asserted the opposite
of a line printed four rows above it. Verified in the source before touching anything: the
`Write-Host` was unconditional, and `Get-TrunkReturnDecision` already carries every declining arm.

The report's two candidate shapes were gating the clause and dropping it. **Gating won**: the true
case carries what #1073 was built to say, and the false case carries something the reader can act
on -- take the lane, not a second terminal in this checkout. Dropping it would have made the line
silent about the one thing the reader is deciding.

### CREATE

- [x] `scripts/lib/worktree-lib.ps1`: `Get-TrunkReturnGoAheadLine`, beside the decision it
      describes -- both arms, and the branch name optional so the line is always printable
- [x] `scripts/release/ship-pr.ps1`: `$treeOnTrunk` recorded where the answer is actually known
      (step 2b's successful checkout), read at step 3 instead of the literal
- [x] `plugins/dkj-policy/scripts/`: mirrors rebuilt with `scripts/sync/build-shared-scripts.ps1`
- [x] `plugins/dkj-policy/skills/ship-pr/SKILL.md`: the go-ahead paragraph says the line reads that
      decision rather than asserting an outcome

### TEST

- [x] `scripts/tests/worktree-lib.tests.ps1`: section 7 -- the no arm never claims the trunk
      (the one assert the old literal could not pass), both arms keep the two true clauses, and a
      missing branch name still words a printable line. 57 asserts pass.

### DEPLOY: fix/1616-go-ahead-trunk-claim

`ship-pr`'s go-ahead line now says what step 2b actually did with the working tree instead of
asserting that it went home. The trunk clause was a literal, so on every run where step 2b
declined to move the tree -- a dirty tree, a lane, a trunk another worktree holds -- the line a
reader is told to act on contradicted the line four rows above it. It is
`Get-TrunkReturnGoAheadLine` in `worktree-lib.ps1` now, asserted in that lib's suite: the yes arm is
word for word what it was, and the no arm names the branch the checkout is standing on and sends the
reader to a lane, which is detached at `origin/<trunk>` and therefore unaffected either way. Both
arms keep the two clauses that are true regardless -- step 1 is over, the tree is free -- because
withdrawing those with the trunk clause would cancel the invitation the line exists to make.

**Score:** 3

#### What makes this deploy extra special

A consumer runs this same script from the plugin mirror, and the go-ahead is what tells them it is
safe to open a second terminal and carry on. Until now it told them their primary checkout was on
the trunk on runs where it was standing on the shipping branch -- the exact state #1073 exists to
prevent, reported as already handled.

**Score:** 3

#### Pull Request

State what step 2b actually decided in ship-pr's go-ahead line
