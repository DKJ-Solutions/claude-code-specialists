## fix/1650-shape-gate-local

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

#### What issue 1650 asked for, and what was verified before building it

The report's three verified claims all still stood when this branch opened: the shape rule is inline in
`scripts/lint/check-branch-entry.ps1` (`$preambleStrays`, ~line 377) rather than in a lib, `open-pr.ps1`
never calls that script, and `main-ci-gate`'s only required context is `lint-en-tests`. So the two shape
rules -- **#898** the phase arc and **#899** the generic preamble -- ran in exactly one place: a CI gate
that reports rather than refuses. The narrow repair the issue named is the one built here: promote the rule
to a shared function and call it from `open-pr`'s local gate run. Nothing about CI's advisory shape and
nothing about the ruleset changes.

#### Two things found while verifying, and what happened to each

`$cycleHalves` and `$headText` in that script were assigned and never read -- dead since the shape check
was written, because the scan walks the whole text. They are gone with the move rather than carried into
the lib.

The prose counts around the gate set were already stale before this branch: `CLAUDE.md` said the CI half
*"re-uses three of their functions"* while `Test-DevelopmentEntryMissing` (#1632) had made it four;
*"four gates"* appeared as a label in five documents while the entry gate had already made it five; and the
`check-branch-entry` skill page and the plugin README each said *"the same two"*, which #1632 had also
already outgrown. All of them are repaired here, by **removing** the count rather than by re-counting -- a
number that goes stale on every added gate reads as authority. What is **not** repaired is the entry gate's
missing documentation: it has no section in `dkj-policy/CONTRIBUTING.md` and none on the `open-pr` skill
page, which is a doc gap of its own and filed as such.

#### The one cost this change accepts rather than repairs

`Test-IsWorkflowSourceRepo` is now evaluated on every run of both callers, where the inline code reached it
only behind `$strayHeadings.Count -gt 0 -and ...` and so only on the rare malformed-document path. It parses
`.claude-plugin/marketplace.json`, once per run. It is accepted because the alternatives are worse: the
switch cannot be made lazy (PowerShell evaluates an argument before the call, and the caller cannot know
whether there are strays without calling), and moving the decision out to the callers would put the message
composition -- which quotes the phase names and the level it read -- in two places, which is the drift the
lib exists to prevent.

### CREATE

- [x] `Get-DevelopmentShapeFindings` in `scripts/lib/entry-scaffold-lib.ps1` -- both rules, verbatim from
      the CI script, with the source-repo half behind `-EnforcePhaseArc` because the caller has the repo
      root and the lib has a text. Returns the finding lines plus what it actually read (`PhaseCount`,
      `PhaseMark`, `SubMark`), so a caller reporting coverage quotes the level that judged the document.
- [x] `check-branch-entry.ps1` calls it and keeps no parser of its own -- 125 lines of inline scan
      replaced by the call, the two dead assignments dropped, and the message and the `[OK]` line
      unchanged.
- [x] The shape gate in `open-pr.ps1`, after the scaffold gate and before the step-list gate, refusing
      before the push with `-Force` honoured like both siblings. That is CI's own order -- is there an
      entry, has it been written, does the document around it hold its form. One read of the document now
      serves all three gates, and one `$entryRel` serves all three refusals where there were two names for
      it.
- [~] The fourth `$entryRel` (the title gate, `open-pr.ps1:1199`) left as it is -- Victor's finding, and
      declined with a reason. That block is **not** inside the `Test-Path $entryPath` guard the other three
      sit in, so under `Set-StrictMode -Version Latest` a run reaching it with no entry file would throw on
      an unset variable. The recomputation is defensive rather than redundant.
- [x] `Get-DisplayRef` on every document fragment a finding quotes -- Sebastian's finding. Same single
      definition (#1623) this repo already applies to a commit subject from another session, and stripped
      before truncated, since a cut at 72 characters can halve an escape sequence.
- [x] Mirrors synced (`scripts/sync/build-shared-scripts.ps1`) -- three of them.
- [x] The phase names come from the wording seam with #927's fail-safe under them, rather than the third
      typed `@('PLAN','CREATE','TEST')` literal the inline copy carried.

### TEST

- [x] 24 asserts in `scripts/tests/entry-scaffold.tests.ps1`, beside the #1632 block they belong with:
      PR #1644's document reproduced from the real writer and refused, the level read off the document,
      the scoping asymmetry both ways, fence-awareness, empty text silent, and both call sites -- open-pr
      asserted to **refuse** rather than warn, since an advisory red was the whole defect.
- [x] `branch-entry-gate.tests.ps1` green unchanged, all 41 asserts -- which is the proof the move
      preserved CI's behaviour, since every #898/#899/#915/#924/#908 scenario runs against the lib now.
- [x] `entry-scaffold.tests.ps1` green: 784 asserts.
- [x] The lint gate green: 0 errors, 344 links and 230 scripts.
- [x] Full suite via `open-pr.ps1`'s own test gate.

### DEPLOY: fix/1650-shape-gate-local

The branch document's **shape** rules -- four `###` headings and never a fifth, and nothing
branch-specific above the first phase -- are one shared function now
(`Get-DevelopmentShapeFindings`), and `open-pr` refuses on them before the push. They lived only in
`check-branch-entry.ps1`, which runs in CI and only advisorily, so nothing stopped a malformed document:
PR #1644 shipped through push, the required check, the merge and the fold with its `### PLAN` heading and
most of its guidance block gone, every other gate correctly green -- and the fold then deleted the very
file the one red check named, so the evidence was destroyed by the thing whose success it was warning
about. CI still reports rather than refuses, from the same code, and `branch-entry` is still not a
required check.

**Score:** 4

#### What makes this deploy extra special

A consumer gets the same refusal, before the push, on the half of the rule that applies to them: branch
content in the generic guidance block. The heading-count half stays the source repo's own, so a document
where they keep a heading of their own is still not refused. Documented as its own gate on the `open-pr`
skill page and in the portable contributing page, both of which travel with the plugin.

**Score:** 3

#### Pull Request

The branch-document shape rule becomes a shared function and refuses before the push
