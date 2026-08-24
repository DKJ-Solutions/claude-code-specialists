# Development cycle: `docs/plan-phase-explore-then-goal-v1` · 20260824-102324

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

Document that exploration happens in plan mode before the plan is written, and that the branch is driven by a /goal condition whose proof lands in the transcript -- with both ways a goal ends and what each means for the branch.

Document that exploration happens in plan mode before the plan is written, and that the branch is driven by a /goal condition whose proof lands in the transcript -- with both ways a goal ends and what each means for the branch.

## PLAN

- [x] Verify that `/goal` exists and that the report's premises hold before documenting it: read the
      command's own page. It does, and "if Claude stalls, Claude Code eventually stops the run with the
      goal still set" is exactly right.
- [x] Find what the report does NOT say and would have made the guidance wrong: the evaluator **runs no
      commands and reads no files** -- it judges only what Claude surfaced in the conversation. So a
      condition must be provable from Claude's own output, which decides how it is written.
- [x] Separate the two ways a goal ends badly, because the report treats "blocked" as one thing: the
      **Impossible** verdict clears the goal, a **stall** leaves it set and hands control back. Parking a
      branch on a stall would throw away work over a quiet loop.
- [x] Verify plan mode against its own page, and find the ordering trap: edits stay blocked until the
      plan is approved, and `new-branch` WRITES a file -- so step one would stall on its own scaffold if
      the sequence were not stated.
- [x] Decide the scope: both issues are the PLAN phase, so they are one change to one section rather than
      two entries saying half of it each.

## CREATE

- [x] Two new sections in `plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md`: the
      explore-then-plan sequence with its four ordered steps, and the goal condition with a worked
      condition, the three endings as a table, and the environment endings that belong to neither.

## TEST

- [~] No suite: nothing executable changed. The claims about `/goal` and plan mode are about the harness
      rather than about this repo's code, so they are verified against the documentation they cite -- both
      read this session -- and a test here could only assert the wording.

## DEPLOY: `docs/plan-phase-explore-then-goal-v1`

The PLAN phase now says how it is entered and how the cycle is driven to its end. Exploration happens in
**plan mode**, where Claude reads and proposes but cannot edit, and the sequence is spelled out because
getting it wrong stalls step one on its own scaffold: `new-branch` writes a file, so the plan has to be
approved before the branch exists. Then the cycle is driven by a `/goal` condition rather than by prompting
it forward turn by turn -- written so this document's own gates prove it, because the evaluator runs no
commands and reads no files. The three endings are separated on purpose: **Met** continues into DEPLOY,
**Impossible** parks the branch and turns the blocker into its own issue, and a **stall** means nothing
about the work at all -- the goal is still set and the harness is waiting for a prompt. Reading a stall as
a blocker would park a branch over a loop that simply went quiet. The phases hold unchanged without any of
it: `/goal` is part of the hooks system and is unavailable in an untrusted folder.

**Score:** 4

### What makes this deploy extra special

Every consumer of this workflow gets a documented answer to "how do I actually run a cycle", which the page
did not carry: it described the form and left the driving to whoever was at the keyboard. It reaches them
through a plugin update, and it deliberately adds no requirement -- a repo without hooks available runs the
same cycle it ran yesterday.

**Score:** 3

### Pull Request

The PLAN phase explores before it plans, and a goal condition drives the cycle
