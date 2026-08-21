# `feat/release-page-second-pass` cycle · 20260821-153659

## PLAN

- [x] Read #809, #811, #813 and #816 in full and settle the interactions BEFORE writing anything. #816
      names the one that bites: drop the row's type chip and the note's `**Type:**` separately and the
      newest release ends up with no type anywhere, because `live` displaces the chip.
- [x] Settle where each fix belongs. #816's own reading is the right one -- the note is read in two
      places and the block is redundant in only one, so it is a RENDERING change. That is also the only
      shape that reaches the notes already published, which are records and are not rewritten.

## CREATE

- [x] Template: the masthead swapped (product in the eyebrow, `Release notes` as the heading, both in the
      window title), trailing chevron with no gutter reserved ahead of the text, a hugging version column,
      sticky summary while open, a close handler that returns the reader to the row, no `.sheet` top
      margin, the masthead marks block, and a deep-link handler that accepts the trimmed version.
- [x] Builder: six pure functions -- `Format-ReleaseMastheadMarks`, `Get-ReleaseDominantType`,
      `Get-ReleaseLiveFallbackVersion`, `Test-ReleaseVersionTrimmable`, `Format-ReleaseVersionLabel`,
      `Remove-NoteMetadataHeader`.
- [x] The page-wide answers are derived ONCE from the release list rather than per row, because each is a
      property of the set -- and read off the data rather than a seam, which is what makes them right for
      a consumer whose bump policy differs.
- [x] `Get-ReleasePageMasthead` registered in the script contract (`Adopt = 'decide'`, optional), the
      blueprint regenerated, and the seam documented in the `release-notes-page` skill.
- [x] `Get-ReleasePageTitle` now answers WHOSE rather than what, in all four layers that document it: the
      contract registry, the seam docstring, the skill and the folder README. This repo's own answer
      carried `-- release notes` and printed those words twice.
- [x] `release-lib.ps1`: the audience section heading is `What changed` at both tiers instead of
      `For consumers` at tier 2, with the `cut-release` skill paragraph rewritten to say why that finishes
      #747 rather than undoing it.
- [x] The function block had to move ahead of the note-reading loop: PowerShell runs top to bottom, and
      `Remove-NoteMetadataHeader` is called while the notes are read. Caught by the first real build.

## TEST

- [x] `scripts/tests/release-notes-page.tests.ps1`: 87 -> 143 asserts. Every way the masthead seam can be
      answered wrongly, the `LIVE` marker winning over the derived fallback, the layout claims as CSS
      positions the way the palette-position assert already worked, and a pin on the chip rule that the
      retired variance test would fail.
- [x] `release-lib` and `cut-release-drive` asserts on `## For consumers` rewritten rather than deleted:
      the tier distinction they were protecting moved from the heading to the audience line, so each now
      asserts what it was actually there for.
- [x] Two count asserts elsewhere follow the new optional seam -- the blueprint's 4 -> 5 and the script
      contract's 6/10/4 -> 7/11/5. Both keep their written history of what each number was and why.
- [x] Four mistakes of my own, each written down beside the assert that now covers it: the
      `-WithPatchNote` note used `2.1.0`, which ends in `.0` like the rest and was off no pattern at all;
      the fixture notes carried no title line, so suppressing one was asserted against a note that never
      had it; `-notmatch 'LIVE'` is case-INSENSITIVE and a row's own title contains the word "live"; and a
      hand-rolled parallel test runner reported six false failures that all pass individually.
- [x] Lint gate green (0 errors, 22 checks), script contract 0 errors, blueprint regenerated twice as its
      inputs changed, mirrors in sync.
- [~] A hand-rolled full run of all 49 suites: dropped, not skipped. `open-pr` runs the real gate -- a
      throttled parallel scheduler -- and my sequential loop only existed to have an answer while the
      branch was waiting on Dave's eye.

## DEPLOY

- [x] Dave's word given after eight rounds of reading the built page, so the chain runs: PR, CI, merge,
      fold.

## Where I left off

Eight rounds of Dave's own reading are in, and two of them replaced an answer rather than adding one --
which is the reason this branch is worth reading rather than just merging:

1. **The Minor label was still there.** The first rule was "render the chip where the type varies", which
   is #811's wording and fixes nothing: that page has two distinct types. Replaced by the dominant-type
   rule. 27 chips became 2 here.
2. **A title printed twice** on opening a note. First repaired by suppressing the note's title line; then
   replaced by his own answer, which is better -- the title leaves the SUMMARY and stays in the note.
3. `## For consumers` names its own reader -- now `What changed` at both tiers.
4. `v4.17` is developer shorthand -- now `Version 4.17`.
5. Closing a note left the reader mid-page -- now it scrolls back to the row.
6. `.sheet` margin to 0, then out of the base rule entirely.
7. `class="sv"` hugs its content instead of carrying a guessed width.
8. The masthead swapped, which fixed the window title losing "release notes" in round 4's wake.

**One item was named and deliberately left out of this branch.** The 27 notes already published still
render `## For consumers`, because only new notes get the new heading and a published note is a record. A
render-side rename would fix the page today and needs a second literal in the builder plus a gate holding
it to what `release-lib` generates -- worth doing, worth doing on its own branch.

Two things that cannot be seen in this repo and are exercised in the suite instead: the marked **`LIVE`**
case (`releases/README.md` here marks nothing, so the fallback is what shows) and the **masthead marks**
(this repo answers no wordmark).

Still open after this: **#815** (nothing deletes a merged branch -- and the report's reason is partly
false, the remote half IS documented, so the real repair is the local half plus saying that the GitHub
setting is the lever), **#810** (the audience heading and the rubric docstring -- item 3 above has now
answered part of it from the other direction) and **#817** (the stale `Write` on the two branch files,
which happened again on this branch). And the release that would deliver #801 + #807 to the two Shopify
consumers is still waiting on Dave's word.
