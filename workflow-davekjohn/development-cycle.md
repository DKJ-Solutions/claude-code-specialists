# Development cycle: `docs/verification-is-a-plan-step-v1` · 20260824-093534

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

Say in DEVELOPMENT-CYCLE-portable.md that judgement work belongs in PLAN and that a branch with no automated test answers with a dropped step and its reason, rather than leaving the phase blank.

Say in DEVELOPMENT-CYCLE-portable.md that judgement work belongs in PLAN and that a branch with no automated test answers with a dropped step and its reason, rather than leaving the phase blank.

## PLAN

- [x] Verify the report still stands, and find the tension it does not name: the page already says
      *"A phase with nothing under it is not a finding"*, so option 3 was not the neutral option --
      it was already the written rule, and option 1 has to nuance that sentence rather than only add
      to it.
- [x] Establish which of the three directions was chosen, since none of them is a repair: option 1,
      the portable page only. Option 2 (also in every branch document) was declined for the reason the
      report itself gives -- it spends the lines #844 had just recovered.
- [x] Decide what NOT to change: the gate. It reads step marks and cannot tell a branch that had no
      plan from one that failed to write it down, which is exactly why this lands as a convention.

## CREATE

- [x] Add both halves after the existing sentence in
      `plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md`, keeping the bare heading
      permitted while naming it as the weaker answer.

## TEST

- [~] No suite, and this branch is its own worked example: nothing executable changed, and the gate
      that reads this document deliberately does not read prose. A test asserting the wording would
      break on every legitimate rewrite of it.

## DEPLOY: `docs/verification-is-a-plan-step-v1`

A branch whose real work is judgement -- verifying a report, choosing between two designs, establishing
that a claim still holds -- produces no artefact until the writing starts, so the phase arc offered it no
home and the path of least resistance was to record only the writing. The portable page now says those
are PLAN steps and shows the shape, and says that where no automated test was added `- [~]` answers with
the reason rather than leaving TEST blank. Both stay conventions: a bare heading is still permitted and
still no finding, because no gate can tell a branch that had nothing to plan from one that never wrote
its plan down. What changes is that the weaker of the two answers is now named as such.

**Score:** 3

### What makes this deploy extra special

Every consumer of this workflow scaffolds the same document, and this reaches them the way all guidance
on that page does -- through a plugin update rather than through a file written once at adoption. It
costs them nothing at scaffold time: the page is the reference, not the template.

**Score:** 2

### Pull Request

Verifying and deciding are PLAN steps, and TEST answers with a reason
