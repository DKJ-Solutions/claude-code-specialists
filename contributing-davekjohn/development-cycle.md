## Development cycle: `fix/new-branch-intent-lands-in-plan-v1` · 20260826-153216

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Issues #908 and #925 (duplicates, both open): `new-branch.ps1 -Intent` wrote its text between the
guidance block and the first phase
heading -- the one region that block declares generic, naming "a note about THIS branch" as its example.
Two candidate repairs were filed: move the output into PLAN, or retire the parameter. Dave handed the
choice to the specialists.

- [x] Verify the report stands: read `Format-DevelopmentCycle`, confirmed the emission site and the
      guidance block that forbids it -- same file, two screens apart.
- [x] Verify the report's REASON, which had expired. It says "no gate reads this region"; the #899 check
      in `scripts/lint/check-branch-entry.ps1` reads exactly that region, was added the same day, and is
      deliberately NOT scoped to this repo. Measured on the real gate: a document generated with
      `-Intent` and its entry filled in exits 1 with `carries branch content above the first '##'`.
- [x] Decision (Sylvester): repair 1. The defect is not tidiness -- `-Intent` made a branch
      un-mergeable through CI the moment the entry was written, i.e. at the PR, in every consumer.
      Retiring the parameter would stop the break by deleting a mechanism the preamble already tells
      you where to put, and it would remove a documented parameter from a shipped plugin (a live
      pass-through in `worktree-lane.ps1`, documented in `DEVELOPMENT-portable.md`).
- [x] Searched the tracker before filing anything of our own, and found #925 -- the SAME defect, filed
      four hours after #908 with the reasoning corrected. It reaches the gate measurement
      independently and asks for exactly the regression scenario built below. Both close with this PR.
- [x] #925 recommends a DIFFERENT repair -- restore a `#### Where I left off` heading under PLAN -- and
      it is declined, with the reason rather than by preference. The preamble says "normally as a
      `####`", and the gate reads only the region ABOVE the first phase heading, so a headingless
      paragraph inside PLAN satisfies it exactly. The heading is not required, and adding it would
      reverse Dave's August 23, 2026 decision to drop it. The shape chosen here keeps both decisions
      intact: inside PLAN as the August 26 rule requires, headingless as the August 23 one settled.
      #925's own options 2 and 3 (exempt the paragraph in the gate; blockquote it) are declined for the
      reasons it gives itself.
- [x] One claim in #925 checked and it does not stand: it says `park-branch` also produces a refused
      document. `park-branch -Intent` writes the intent into the PARK COMMIT MESSAGE
      (`scripts/lib/park-lib.ps1:114`) and never into the document. The two real writers are
      `new-branch -Intent` and `worktree-lane -Intent`, which forwards to it.

### CREATE

- [x] `Format-DevelopmentCycle`: the intent leads the FIRST PHASE as a headingless paragraph, anchored
      on `$phases[0]` rather than the literal `PLAN`, because `StepPhases` is a seam a consumer may
      rename or translate.
- [x] The no-phases branch of the same seam keeps the note directly above the bare step, where that
      step already sits -- nothing invented to work around a shape that predates this change.
- [x] The three documents that still described the old placement: the formatter's own docstring, the
      `.PARAMETER Intent` block and the emission comment in `new-branch.ps1`, and
      `DEVELOPMENT-portable.md` -- which gains a note for anyone holding a branch from an older
      version of the workflow.
- [x] Mirrors regenerated with `scripts/sync/build-shared-scripts.ps1` (2 updated).

### TEST

- [x] `new-branch.tests.ps1` scenario (h) asserts WHERE, not merely THAT. Its two existing asserts are
      what let this ship: they ask only whether the text is in the document somewhere, and it was.
- [x] The first draft of that assert failed, correctly, and its failure is recorded in the test: a
      substring search for `### PLAN` matched the guidance line that QUOTES that heading, which is the
      mention-read-as-a-use shape this repo has paid for repeatedly. Anchored on whole lines instead.
- [x] `branch-entry-gate.tests.ps1` scenario 9: the whole generated document, with `-Intent`, through
      the real gate. Scenario 8 already fed it the generated preamble -- without `-Intent`, which is
      precisely the input that was missing.
- [x] Suites green: `new-branch` 118/118, `branch-entry-gate` 30/30, `entry-scaffold` 495/495.
- [x] Lint gate: 0 errors.

### DEPLOY: `fix/new-branch-intent-lands-in-plan-v1`

`new-branch.ps1 -Intent` now writes its parking note as the opening paragraph of the document's first
phase (`PLAN`) instead of above the phases. The region between the title and the first phase heading is
generic guidance, and `check-branch-entry.ps1` refuses branch content there -- so a branch scaffolded
with `-Intent` was rejected by CI as soon as its entry was written, which is at the PR. The parameter,
its pass-through from `worktree-lane.ps1` and its place in the document are otherwise unchanged; it
still keeps no heading of its own and still never touches the DEPLOY section.

**Score:** 4

#### What makes this deploy extra special

The scaffolder stated a rule and broke it in the same file, and the half that made it expensive was not
the contradiction but the gate: `-Intent` produced a branch a consumer's CI would not let through, and
the failure was invisible until the entry was written. Anyone who has a branch in flight carrying an
intent above the phases can move that paragraph under `PLAN` by hand; nothing else about the document
changes.

**Score:** 4

#### Pull Request

new-branch -Intent writes into PLAN instead of above it

