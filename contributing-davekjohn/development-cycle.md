## Development cycle: `fix/intent-under-the-first-phase-v1` · 20260826-154729

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

#### The decision this implements, and why it needed one

[#925](https://github.com/DaveKJohn/claude-code-specialists/issues/925) is a collision between two
deliberate decisions rather than an oversight, which is why it was filed for a ruling instead of patched:
the intent's placement (a paragraph at the top, heading dropped -- Dave, August 23, 2026) against the
preamble rule (nothing branch-specific above the first phase -- Dave, August 26, 2026), taken three days
apart with neither in view of the other. Dave chose option 1 on August 26: give it a heading again, under
the first phase.

That is also what the document's own guidance block already said, two lines above the paragraph it was
refusing: *"a note about THIS branch belongs under one of the four, normally as a `####` in PLAN."* So the
scaffolder was contradicting itself within one output.

**And a comment in the tree had already been written as if the fix existed.** The `NotesHeading` block in
`scripts/lib/entry-scaffold-lib.ps1` says the intent goes *"where a reader of a parked branch actually looks
-- see Format-DevelopmentCycle, which writes it under the phase the first step lives in"*. It did not; it
wrote above the phases. The code now matches that description, and the description now names the phase it
actually uses.

- [x] Confirm nothing reads the intent back positionally -- `park-lib.ps1` uses it only for the park commit
      message, and no gate or skill parses the region above the first phase
- [x] Establish where the heading text belongs: a new key in `$script:BranchFileDefaults`, which the
      existing `Get-BranchFileWordingOverrides` seam already covers, so a consumer can translate it and
      **no new script-contract entry is needed**. That is the argument `Get-BranchFileWording` already makes
      for being one getter returning a map

### CREATE

- [x] `IntentHeading = 'Where I left off'` in the branch-file wording defaults
- [x] `Format-DevelopmentCycle` builds the intent as a `####` block and hands it to the **first** phase,
      after any step that phase owns -- after, because a `####` claims everything below it, so a step
      written under it would read as a step of the intent rather than of the phase
- [x] The first phase and not `FirstStepPhase`: an intent is direction rather than a step, and PLAN is what
      the guidance block names. With the default arc they are different phases anyway
- [x] The no-phases shape (a consumer who switched the arc off) keeps the heading too, and its own
      pre-existing preamble problem is named in the comment rather than quietly relied on: the DEPLOY
      heading is the first section-level heading there, so the bare step above it is itself read as
      preamble content. That predates this issue and nobody here runs that shape
- [x] Three stale statements corrected: the `-Intent` half of `Format-DevelopmentCycle`'s docstring, the
      `.PARAMETER Intent` block in `new-branch.ps1`, and the `NotesHeading` comment that already described
      the behaviour this branch builds
- [x] Two shipped pages follow the behaviour: `DEVELOPMENT-portable.md` and the `new-branch` skill page,
      both of which stated "the top of the document, above the phases"
- [x] All three mirrors held byte-identical: `entry-scaffold-lib.ps1`, `new-branch.ps1`

### TEST

- [x] `entry-scaffold.tests.ps1`: the intent's position asserted **relative to** the first phase heading and
      its own heading, not by presence. "The intent is somewhere in the file" was true of the defect too,
      and is exactly the assert that let it ship
- [x] And the mirror-image case: without `-Intent` the heading does not appear at all, so the section the
      August 23 decision retired does not come back for every branch
- [x] `branch-entry-gate.tests.ps1` scenario 10: the gate is fed a document scaffolded **with** `-Intent`.
      Scenario 8 already feeds it the formatter's own output and passes -- it just never passed that one
      argument, which was the whole failure. The fixture check reads the document rather than the gate's
      output, because a green run prints nothing from the file
- [x] Both new asserts confirmed **red** against the reintroduced defect before being trusted
- [x] `check-plugin-integrity.ps1` green, and 500 asserts in the scaffold suite

### DEPLOY: `fix/intent-under-the-first-phase-v1`

`-Intent` is written **inside the first phase** now, as a `####` section with a heading of its own, instead
of as a bare paragraph above the phases
([#925](https://github.com/DaveKJohn/claude-code-specialists/issues/925)). That paragraph sat in the one
region `check-branch-entry.ps1` refuses, so `new-branch -Intent`, `park-branch` and `worktree-lane -Intent`
each produced a document the branch-entry gate rejected -- and the only way through was to move by hand what
the script had just written. Measured on a fully-written document: the finding named the intent line, and
removing it made the same document pass.

**It was two deliberate decisions colliding, not an oversight**, which is why it went to Dave rather than
straight to a patch: the placement (August 23, heading dropped because an unticked box already says where you
left off) against the preamble rule (August 26, nothing branch-specific above the first phase), three days
apart with neither in view of the other. Dave chose the guidance block's own answer -- *a note about this
branch belongs under one of the four, normally as a `####` in PLAN* -- which the scaffolder was printing two
lines above the paragraph it was being refused for.

**The retired section is not coming back.** `Where I left off` was removed because it asked every branch to
restate its step list; this heading appears only when `-Intent` is given, and holds the one thing the marks
cannot carry: what you decided and have not written down anywhere yet. Its text is a new key in the
branch-file wording map, so it travels through the seam a consumer already has -- no new contract entry.

Three stale statements went with it, one of which had been describing this fix before it existed: the
`NotesHeading` comment said the intent goes *"under the phase the first step lives in"*, and it did not.

**The guard is a position, not a presence.** *The intent is somewhere in the document* was true of the defect
as well, so the suite now asserts the intent's heading sits under the first phase heading and its text under
that -- and the gate suite is fed a document scaffolded with `-Intent`, which scenario 8 had never done. Both
asserts confirmed red against the reintroduced defect first.

**Score:** 3

#### What makes this deploy extra special

This is a consumer-facing break being repaired, not a refinement. `new-branch -Intent` and `park-branch` are
the documented way to hand a branch to another machine, and in a consuming repo the gate that refused the
result runs in **CI** -- so a consumer parking a branch got a red check on a document the plugin's own script
had just written, with the fix being to edit that file by hand and no page telling them so. Both shipped
pages said the paragraph belonged where it was. Anyone who has already moved one by hand can stop; anyone who
had not yet used `-Intent` will never meet it.

**Score:** 4

#### Pull Request

The intent is written inside the first phase, with a heading

