## docs/1653-1654-entry-gate-and-plan-string

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

Two issues, one seam: #1653 (the entry gate from #1632 is documented nowhere) and #1654 (the guidance
block quotes the heading it is a rule about, which is what makes that gate necessary).

#### What the pickup check found, because it changed the work

Both issues describe a **shape gate**, `Get-DevelopmentShapeFindings`, as an existing shared function.
It does not exist anywhere in the tree, and **#1650 -- the issue that would build it -- is still open**.
Both issues state as fact that #1650's repair is merged. It is not.

Two smaller mis-measurements, both in #1653: it lists `dkj-policy/CONTRIBUTING.md` as having six `3.2.x`
sub-sections ending at *3.2.5 shape, 3.2.6 CI* (it had five, ending at *3.2.5 the CI gate*), and it quotes
`CONTRIBUTING-portable.md` as saying "**Five** further gates" naming shape (it said "**Four**", and named
neither shape nor the entry gate).

The **core finding of each issue survives intact** and was re-verified against the tree after a
`git pull --ff-only` moved the trunk ten commits mid-pickup. Nothing here depends on the shape gate.

#### The decision #1654 asked for

#1654 is a decision, not a defect: three shapes for the guidance line, none free. **Option 3 was taken** --
stop naming the heading literally -- in the refined form *"the first of those four headings"* rather than
the issue's *"the first phase heading"*. The bullet directly above names PLAN, CREATE, TEST and DEPLOY in
order, so the antecedent is one line up and the "it gets vaguer" cost the issue priced in does not land.
Option 2 (splitting the string) was declined: it stops reading as the heading a reader will type, and a
translated guidance block has to reproduce the split.

The deciding argument is one the issue itself raised against its own cost column: `StepPhases` is a seam,
so the literal was already **wrong** for a consumer who renamed their first phase. Option 3 is a
correctness fix that happens to close the collision, not only a collision fix.

### CREATE

- [x] #1654: `StepsGuidance` in `scripts/lib/entry-scaffold-lib.ps1` names the first phase by position
- [x] #1654: the three places carrying the now-dated diagnosis updated to stay true on both sides of the
      change -- `Test-DevelopmentEntryMissing`'s header, `open-pr.ps1`'s refusal, and the comment in
      `new-branch.tests.ps1` whose whole-line match the collision used to justify
- [x] #1653: `dkj-policy/CONTRIBUTING.md` gains `#### 3.2.1. the entry gate`, and 3.2.2-3.2.7 renumber
- [x] #1653: every cross-reference to a renumbered section repointed, each read in context first
- [x] #1653: `plugins/dkj-policy/skills/open-pr/SKILL.md` gains `## The entry gate`, and the numbered
      step list under `## What the skill does` names it
- [x] #1653 (second half): `CONTRIBUTING-portable.md`'s gate list gains the entry gate and stops claiming
      completeness -- it named four of the eleven gates `open-pr` and `ship-pr` actually run
- [x] Mirrors rebuilt via `scripts/sync/build-shared-scripts.ps1`
- [x] Merged `origin/main` mid-branch, which had gained `#### 3.2.5. the shape gate` from #1650 -- both
      sides added a gate section, so the union is seven: the shape gate lands at 3.2.6 and the CI gate at
      3.2.7, and every cross-reference to either was repointed after reading it in context
- [x] The gate COUNTS in `CONTRIBUTING.md` went the way the portable half had already taken them --
      *five gates read it on the way* and *the five above are local* are now count-free. Both were
      already wrong on **both** sides of this merge (each side had six), and `CLAUDE.md` states the
      count is deliberately not given there, because a wrong number reads as authority

### TEST

- [x] New assert block in `entry-scaffold.tests.ps1`: the region above the first phase heading quotes no
      phase heading, derived from `StepPhases` and measured on the **rendered document** rather than on
      the wording array, so a consumer overriding the seam is held to the same rule
- [x] Negative-controlled: the matcher catches the old wording and passes the new, so the assert can go red
- [x] `Test-DevelopmentEntryMissing`'s #1632 block split in two -- its precondition assert was passing for
      a different reason than its label claimed once the collision closed, and the pre-#1654 shape (#1644's
      own document) is now pinned rather than derived, so the regression test for the two measured
      incidents does not quietly retire
- [x] Full lint + test gate green via `open-pr.ps1`

### DEPLOY: docs/1653-1654-entry-gate-and-plan-string

The entry gate that #1632 built is now documented in both places a reader looks for a gate -- a numbered
section in the workflow's contributing page and a full section on the `open-pr` skill page -- including the
part only the code explained: it is a separate gate because the scaffold gate **passes by absence** on a
document with no entry text, `Get-DevelopmentEntryText`'s whole-text fallback being load-bearing for a
legacy entry-only file. That it honours `-Force` was findable nowhere and now is.

And the string that made the gate necessary is gone from the guidance. `new-branch` wrote the exact heading
`### PLAN` into every branch document twice -- once as the heading, once in the blockquote above it -- so any
edit anchoring on that heading as a plain string found the wrong one; two documents shipped through that door
(#1632, #1644). The guidance names the first phase by position now. That is also the more correct wording,
because `StepPhases` is a seam and the literal was already wrong for any repo that renamed its first phase.
The gate is unchanged and keeps naming the literal in its refusal: every branch open across this change still
carries both copies.

**Score:** 3

#### What makes this deploy extra special

Consumers get both halves through the plugin: the guidance block in every branch document written from now
on, and the two pages that describe the gates. A consumer meeting the entry gate's refusal previously had
nothing to read behind it -- the message named the cause, but the reason it is a separate gate, and the fact
that `-Force` gets you past it, existed only in this repo's source.

**Score:** 3

#### Pull Request

Document the entry gate, and stop the guidance quoting the heading it is a rule about
