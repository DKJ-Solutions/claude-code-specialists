# Development cycle: `docs/test-phase-is-the-verification-v1` · 20260824-102544

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

State that a branch reaches DEPLOY only once it has verified itself in TEST, and that verification is a check Claude can run -- a suite, a gate, a build, a rendered result -- so the dropped mark stops reading as no verification at all.

State that a branch reaches DEPLOY only once it has verified itself in TEST, and that verification is a check Claude can run -- a suite, a gate, a build, a rendered result -- so the dropped mark stops reading as no verification at all.

## PLAN

- [x] Read what the page says about TEST today, because a branch merged hours ago had just changed it:
      `- [~]` means *no suite, and here is why*. That is compatible with the request, but only once the
      two sentences are separated -- "no suite" and "no verification" are not the same claim.
- [x] Establish the tension this has to resolve rather than paper over: the page permits a bare TEST
      heading and calls it no finding, while the request says a branch is deployment-ready only once it
      has verified itself. Both survive if the dropped mark keeps naming the check that WAS run.
- [x] Decide where it goes: expanding the existing TEST paragraph rather than adding a competing section,
      so the page has one answer about TEST instead of two next to each other.

## CREATE

- [x] Four paragraphs after the existing TEST guidance in
      `plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md`: what the phase is for, why
      `- [~]` never means "no verification", the two honest non-suite shapes and the one dishonest one,
      and what an evaluator can see of it.

## TEST

- [x] The lint gate on this branch: `check-plugin-integrity.ps1`, 0 errors -- the check that matters
      here, since the change is prose and what could break is a dead anchor. The `#rules` cross-reference
      this text adds resolves.
- [~] No suite: nothing executable changed, and a test asserting the wording of guidance would break on
      every legitimate rewrite of it. Named rather than left blank, which is the rule this branch writes.

## DEPLOY: `docs/test-phase-is-the-verification-v1`

The page said what TEST *may* leave out; it did not say what the phase is *for*. It does now: TEST is where
a branch verifies itself, and a branch reaches DEPLOY once it has -- with the check named and its outcome
recorded, because a check with no place in the arc gets run when somebody remembers to. The sharpening that
does the work is separating two sentences that were reading as one: `- [~]` means **no suite**, never **no
verification**. A dropped step still names what was run and what came back, so a TEST phase whose whole
content is *"nothing to test"* is recognisable as an assertion rather than a verification. Two shapes are
honest and neither is a suite -- running the gates and reporting the outcome, and a check the phase cannot
automate as long as it records that it ran. One is not: a step ticked because the change looks correct,
which is the failure rule 3 already names from the other side.

**Score:** 4

### What makes this deploy extra special

This is the difference between a session somebody watches and one they can walk away from, and it reaches
every consumer of the workflow through a plugin update. It adds no gate and forbids nothing that was
allowed: a bare TEST heading is still permitted and still no finding. What changes is that the phase now
states its own purpose, so the weaker answer is recognisable as the weaker answer.

**Score:** 3

### Pull Request

The TEST phase is where the branch is verified, and it names the check that was run
