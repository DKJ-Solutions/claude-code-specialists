## fix/stale-heading-facts-in-scripts

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

Repair the six sites named in #1341 plus any further instance the sweep turns up; leave the deliberate history narration alone.

#### The rule the sweep was run by

A site is repaired when it makes a claim a reader takes as being about TODAY and that claim is false.
A site is LEFT when the block it sits in dates itself and ends with the current answer -- the layered
`(Dave, August 19, 2026)` paragraph followed by `SHIFTED ONE LEVEL DOWN ON AUGUST 26` is history read
top to bottom, not a defect. Where the level was never the point, the digit is removed rather than
updated (`the entries are the blocks at that level below it`), because that sentence then survives the
next shift.

### CREATE

- [x] Verify all six sites named in #1341 still stand, against the seams at runtime
      (`Get-EntryHeadingLevel` 3, `Get-EntrySectionLevel` 4, `Get-EntryWrittenSectionKeys` 2)
- [x] Repair them, plus the same-class sites the sweep turned up in the rest of `scripts/**`
- [x] Sweep the test layer too -- including the two claims a suite PRINTS at runtime
- [x] Mirror the seven shared libs to `plugins/workflows/contributing-davekjohn/` via
      `build-shared-scripts.ps1`
- [x] File what the sweep found that is behaviour rather than prose: #1344
- [x] Report the one `.md` site in the same class on #1338, which owns that layer and is somebody else's

### TEST

- [x] `check-plugin-integrity.ps1` -- 0 errors
- [x] `check-plugin-integrity-entries.tests.ps1` -- 78/78, run because this branch changes an assert in it
- [x] The restored assert proved to BITE rather than merely pass: the old `'^## #123 '` pattern matches
      nothing (`False`), the composed one rewrites the heading
- [~] The full suite is not run here: `open-pr` runs it as its own gate, and a copy set going ahead of
      that gate proves nothing the gate would not catch

### DEPLOY: fix/stale-heading-facts-in-scripts

The August 26, 2026 level shift moved an entry to `###` and its sections to `####`, and left the prose
in `scripts/**` describing the shape before it. The sweep that produced #1338 stayed in the `.md`
layer, so these were left: **check 13's own header told a maintainer the gate enforces something
the gate does not** -- *"an entry is an H2 with three named H3 sections"*, where the check derives H3,
two, and H4 from the seams -- and `fold-changelog-entry.ps1`'s header contradicted its own body 500
lines further down.

Repaired at the six sites #1341 names and at every same-class site the sweep turned up beside them:
sixty passages across sixteen files under `scripts/**` -- the lint gate, the fold,
`entry-scaffold-lib`, `release-lib`, `pr-body-lib`, `script-contract-lib`, `repo-config`,
`check-branch-entry`, `new-branch` and seven test suites, two of the claims being ones a suite **prints
at runtime**. Seven of the nine non-test files are shared libs and were mirrored to the plugin with
`build-shared-scripts.ps1`, so a consumer reads the same corrected text.

Where the level was never the point it is now stated as a relation rather than a digit -- *"an entry
carries named sections one level under its own heading"* -- which is what stops the next shift from
recreating this entry. Deliberate history is left standing, including the layered blocks that name an
old pair and then say it moved.

**One change here is not prose.** The same shift had silently killed an assert: a fixture in
`check-plugin-integrity-entries.tests.ps1` was rewritten by a typed `'^## #123 '` pattern that has
matched nothing since the entry became an H3, so the manual-merge scenario re-tested the untouched good
fixture and passed by asserting the assert two blocks above it. The pattern is composed from the seam
now, and the restored assert was proved to bite before it was believed. **What the sweep found that is
behaviour rather than prose is filed, not folded in**: #1344, where two copies of
`Test-IsChangelogEntryFile` still range one level the wrong way.

**Score:** 3

#### What makes this deploy extra special

A consumer reads these comments to find out what the workflow's gates enforce, and seven of the nine
repaired non-test files ship to them in the plugin mirror -- including the fold's own description of
what it does to an entry as it lands, which had contradicted its own body since the shift. Nothing
about their branches changes; what changes is that the files explaining the format agree with it.

**Score:** 2

#### Pull Request

Correct the stale heading facts left in script comments and docstrings

