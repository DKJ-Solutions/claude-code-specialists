# Development cycle: `fix/deploy-is-written-once-test-is-green-v1` · 20260824-134559

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

## PLAN

- [x] Verify the finding still stands before routing it. It does, and the shape is precise: the arc section
      already says *"a branch reaches DEPLOY once it has verified itself here"*
      (`DEVELOPMENT-CYCLE-portable.md`), but the **Rules** list carries only one timing statement about
      DEPLOY — rule 6, *"Fill in every tier the DEPLOY section carries **before the PR**"*. The sequencing
      exists as prose and not as a rule, and the rule that should carry it names only the upper bound.
- [x] Establish why no gate catches it, rather than assume one failed: the step gate splits the document at
      the DEPLOY heading and counts only **above** it, which it has to — an entry legitimately describes
      work in checkbox shape. So an early DEPLOY is invisible to every gate **by construction**. This is a
      writing convention, and a check would be the wrong instrument.
- [x] The measured instance is the branch that ran immediately before this one,
      `feat/filing-a-finding-needs-no-permission-v1` (PR #868): PLAN 6/6 and CREATE 4/4 ticked, **TEST three
      steps open** — and written as results (*"0 errors"*, *"All 52 suites green"*) rather than as checks —
      while DEPLOY stood complete with both tiers scored.
- [x] **Verify the proposed repair against the tree, which corrected it.** "Write DEPLOY last" would
      contradict the tooling on day one: `scripts/task/new-branch.ps1:264` sets `$description = $Title`, so
      `-Title` writes **into** the DEPLOY section, in `### Pull Request`, at creation — and `open-pr`
      composes the PR title from it rather than taking one on the command line, so it is typed once and
      cannot disagree with itself. The rule therefore names the **entry prose and the tier scores**, and
      excepts that one field explicitly.
- [x] Check that nothing already in the tree will disagree with the new rule: `new-branch -Park`
      deliberately does not touch DEPLOY (*"an intent is a status"*); the `/goal` outcome table already
      reads **Met → continue into DEPLOY**; and `skills/new-branch/SKILL.md` carries no competing timing
      statement. All three point the same way, which is why this is a gap rather than a conflict.
- [x] Establish the layer, per the source-is-the-default rule: **portable**. The Rules and the arc ship in
      `plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md`, and the writer-facing sentence
      lives in `StepsGuidance`, mirrored byte-for-byte in `scripts/lib/entry-scaffold-lib.ps1` and the
      plugin copy. No repo lens is involved.
- [x] Measure the blast radius before touching a seam: exactly one assert pins `StepsGuidance`
      (`scripts/tests/entry-scaffold.tests.ps1:1701`, on the string `FROM THE REPO ROOT`), so adding lines
      to the block is safe. Four files carry the sentence: the portable page, both lib copies, and whatever
      branch document happens to be live.

## CREATE

- [x] **Rule 6** in `DEVELOPMENT-CYCLE-portable.md`: the timing clause gains its lower bound — *after TEST
      resolves, and before the PR* — with the measurement and the `-Title` exception under it. No rule 8 and
      no renumbering: the rule that carried the gap is the one that answers it.
- [x] **The arc section** of the same page: make the difference between *reaching* DEPLOY and *writing* it
      explicit, since only one of the two survives a failing suite.
- [x] **`StepsGuidance`** in both `entry-scaffold-lib.ps1` copies: extend the existing *"DEPLOY takes no
      steps of its own"* line, the only text that reaches a writer at the moment of writing. The block's own
      comment sets the bar for what may stand there — rules with a **silent** failure mode — which this is.

## TEST

- [x] `check-plugin-integrity.ps1`: **0 errors**, with `[shared-script] checked 42` — the check that holds
      the two lib copies byte-identical after a seam edit — and `[script-ascii] checked 158`, which matters
      here because the new seam lines are prose inside a `.ps1`.
- [x] **All 52 suites green**, 1,739 assertions, 219s. `entry-scaffold.tests.ps1`, the suite that reads this
      seam, passed 24/24.
- [x] Rendered a throwaway document straight from the edited seam (`Format-DevelopmentCycle -Branch
      fix/throwaway-render-check`) and read it back: the new sentence appears in the block a branch actually
      gets. One difference is mine and not the change's — the audience line was absent because the bare
      dot-source has no `repo-config.ps1` to answer `Get-EntryAudienceTier`; the real scaffold earlier today
      wrote it.

## DEPLOY: `fix/deploy-is-written-once-test-is-green-v1`

The development cycle's own **Rules** said one thing about when the DEPLOY section is written: *"Fill in
every tier the DEPLOY section carries **before the PR**."* That is an upper bound with no lower one, so the
whole entry could legitimately be composed on day one — and an entry written while steps above it are still
open states an **intention**, not a result. Nothing holds it against what landed: the step gate splits the
document at that heading and counts only above it, so what folds into `CHANGELOG.md` is whatever was
written before the work was finished, however the work then turned out.

Rule 6 gains its lower bound — *once TEST is resolved, and before the PR* — and the arc section gains the
reason, beside the sentence that already said a branch *reaches* DEPLOY once it has verified itself. Those
two words are the whole confusion: reaching that phase and writing its section are not the same act, and
only the second one survives a suite that turns something up. The measured instance is the branch that
merged an hour before this one (PR #868): PLAN 6/6 and CREATE 4/4 ticked, **TEST three steps open** — and
those three written as results rather than as checks — with DEPLOY complete and both tiers scored.

**One field is deliberately excepted, and checking that saved the rule from being wrong.** `-Title` writes
into the DEPLOY section at creation (`scripts/task/new-branch.ps1`, `$description = $Title`), because
`open-pr` composes the PR title from it rather than taking one on the command line — typed once, so it
cannot disagree with itself. A blanket *"write DEPLOY last"* would have contradicted the tooling on the
day it shipped. What waits for TEST is the entry's prose and its tier scores, which are claims about what
the change *did*.

**And no gate enforces it, on purpose.** The gates run once, at the push, and at that moment a finished
branch legitimately has a full DEPLOY and a resolved TEST — "too early" is an ordering in time, visible
only in the commit history. So this lands where the failure is: rule 6, the arc, and the guidance
blockquote every branch document carries, which is the one text that reaches a writer at the moment of
writing.

**Score:** 3

### What makes this deploy extra special

The guidance block is scaffolded into **every** development cycle document the workflow creates, so a
consuming repo does not have to read the portable page to meet the rule — it arrives in the file they are
already writing in, the first time they open a branch after the update. And this branch is its own first
test: TEST was resolved and only then was this section written.

**Score:** 3

### Pull Request

DEPLOY is written once TEST is resolved, not before
