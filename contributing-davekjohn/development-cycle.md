## Development cycle: `fix/audience-paragraph-drops-whole-v1` · 20260826-164249

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

Issue #928: `Format-DevelopmentCycle`'s no-tier fallback filters only the line carrying the `{0}` audience
seam, leaving its two continuation lines behind -- so every consumer without a `Get-ReleaseAudienceTier`
gets a branch document whose paragraph begins mid-sentence and refers to "that reader" after the clause
naming that reader has been dropped.

- [x] Verified the report still stands before building on it. `scripts/lib/entry-scaffold-lib.ps1` still
      carried `Where-Object { [string]$_ -notmatch '\{0\}' }` at the fallback, and `StepsGuidance` still
      holds the sentence across three lines. Both halves of #928 were true as filed.
- [x] Chose between the two repairs the issue names -- marking the paragraph in the wording, or finding it
      by shape. Shape wins, and not on taste: `StepsGuidance` is a translation seam, so a marker in the
      wording puts the burden on whoever translates the block and fails silently when they drop it. The
      gate this workflow already ships makes the same choice for the same reason -- `check-branch-entry.ps1`
      reads the preamble by shape precisely so it survives translation.
- [x] Confirmed this repo cannot reach the defect itself: `scripts/repo-config.ps1` states tier 2, so the
      fallback never runs here. That is why nothing in this tree caught it, and why the assert has to drive
      the no-tier path deliberately.

### CREATE

- [x] `Remove-EntryAudienceGuidance` in `scripts/lib/entry-scaffold-lib.ps1`, beside its
      `Format-EntryAudienceGuidance` sibling. It expands the seam line to its own paragraph -- a separator
      being a line that is empty once a leading `>` is stripped -- and removes that paragraph plus ONE
      fencing separator, preferring the one above so the paragraph below keeps its blank line. A block
      carrying no seam comes back untouched, which is the property that makes it safe over a consumer
      override.
- [x] The call site in `Format-DevelopmentCycle` now calls it, and the comment above it no longer promises
      that "the line" is removed.
- [x] Rebuilt the plugin mirror with `scripts/sync/build-shared-scripts.ps1` -- a consumer runs
      `plugins/workflows/contributing-davekjohn/scripts/lib/entry-scaffold-lib.ps1`, and this fix exists
      for consumers only.

### TEST

- [x] A block at the end of `scripts/tests/entry-scaffold.tests.ps1`. It derives the paragraph from
      `StepsGuidance` rather than pinning its prose, so it follows the wording wherever it goes: a pinned
      quote would go red on every legitimate edit and be raised rather than read.
- [x] Asserted the whole path, not just the function: the paragraph goes, the paragraphs fencing it stay,
      exactly one separator goes with it, no doubled separator is left, a block with no seam is returned as
      it came, an empty block is not an error -- and the rendered no-tier document carries none of it while
      a tier-stating repo still gets the sentence AND the lines finishing it.
- [x] Proved the asserts can fail. Restored the old one-line filter and re-ran: 2 failed, 511 passed, and
      the two failures are exactly the orphaned continuation lines #928 reported. A test that cannot go red
      would have been the same defect in a second place.
- [x] Lint gate green (0 errors, including `[shared-script]` on the rebuilt mirror) and the suites green.

### DEPLOY: `fix/audience-paragraph-drops-whole-v1`

A repo that states no audience tier now has the whole audience paragraph dropped from its branch
document's guidance, instead of only the line carrying the `{0}` seam. The fallback in
`Format-DevelopmentCycle` removed one line of a three-line sentence, so the two that finished it stayed
behind: every such document opened a paragraph mid-sentence and referred to "that reader" after the
clause naming that reader had been dropped. `Remove-EntryAudienceGuidance` now finds the paragraph by
shape -- a separator being a line that is empty once a leading `>` is stripped -- and takes one fencing
separator with it, so nothing doubles up where it stood.

**Score:** 2

#### What makes this deploy extra special

This repo could not reach the defect and never will: `scripts/repo-config.ps1` states tier 2, so the
fallback does not run here. It was a consumer-only failure in the one document a consumer meets on every
single branch, which is why nothing in this tree caught it and why the assert has to drive the no-tier
path deliberately.

The repair is found by SHAPE rather than marked in the wording, and that choice is the durable half.
`StepsGuidance` is a translation seam: a marker in the text would put the burden on whoever translates
the block and would fail silently the moment they dropped it. Reading the shape instead survives
translation -- the same reasoning `check-branch-entry.ps1` already applies to the preamble check. A
consumer who replaced the wording with their own prose still gets exactly their own prose back, because a
block carrying no seam is returned untouched.

**Score:** 3

#### Pull Request

fix: the no-tier fallback drops the whole audience paragraph, not one line of it
