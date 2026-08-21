# `feat/release-page-second-pass` cycle · 20260821-153659

## PLAN

- [x] Read #809, #811, #813 and #816 in full and settle the interactions BEFORE writing anything. #816
      names the one that bites: drop the row's type chip and the note's `**Type:**` separately and the
      newest release ends up with no type anywhere, because `live` displaces the chip.
- [x] Settle where each fix belongs. #816's own reading is the right one -- the note is read in two
      places and the block is redundant in only one, so it is a RENDERING change. That is also the only
      shape that reaches the notes already published, which are records and are not rewritten.

## CREATE

- [x] Template: trailing chevron with no gutter reserved ahead of the text, sticky summary while open,
      responsive `.sheet` margin, the masthead marks block, a deep-link handler that accepts the trimmed
      version spelling, and a close handler that puts the reader back on the row they opened.
- [x] Builder: five pure functions -- `Format-ReleaseMastheadMarks`, `Get-ReleaseDominantType`,
      `Test-ReleaseVersionTrimmable`, `Format-ReleaseVersionLabel`, `Remove-NoteMetadataHeader`.
- [x] The two page-wide answers are derived ONCE from the release list rather than per row, because both
      are properties of the set -- and read off the data rather than a seam, which is what makes them
      right for a consumer whose bump policy differs.
- [x] `Get-ReleasePageMasthead` registered in the script contract (`Adopt = 'decide'`, optional), the
      config blueprint regenerated, and the seam documented in the `release-notes-page` skill.
- [x] `release-lib.ps1`: the audience section heading is `What changed` at both tiers instead of
      `For consumers` at tier 2, with the `cut-release` skill paragraph rewritten to say why that
      finishes #747 rather than undoing it.
- [x] The function block had to move ahead of the note-reading loop: PowerShell runs top to bottom, and
      `Remove-NoteMetadataHeader` is called while the notes are read. Caught by the first real build.

## TEST

- [x] `scripts/tests/release-notes-page.tests.ps1`: 87 -> 134 asserts. Every way the masthead seam can
      be answered wrongly (a URL, a raw svg payload, three marks, an oversized one), the layout claims as
      CSS positions the way the palette-position assert already worked, and a pin on the chip rule that
      the retired variance test would fail.
- [x] `release-lib` and `cut-release-drive` asserts on `## For consumers` rewritten rather than deleted:
      the tier distinction they were protecting has moved from the heading to the audience line, so each
      now asserts what it was actually there for.
- [x] Two count asserts elsewhere follow the new optional seam -- the blueprint's 4 -> 5 and the script
      contract's 6/10/4 -> 7/11/5. Both keep their written history of what each number was and why.
- [x] Three fixture bugs of my own, each written down beside the assert: the `-WithPatchNote` note used
      `2.1.0`, which ends in `.0` like the rest and was therefore off no pattern at all; the fixture notes
      carried no title line, so suppressing one was asserted against a note that never had it; and a
      parallel test runner of mine reported six false failures that all pass individually.
- [x] Lint gate green (0 errors, 22 checks), script contract 0 errors, mirrors in sync.
- [ ] One more full sequential run of all 49 suites: the last green one predates five rounds of changes,
      so it proves the wrong tree.

## DEPLOY

- [~] Not pushed, and this is the one branch on which that is the correct mark. The deliverable is a
      RENDERED PAGE -- the first of the two exceptions in the safety rules, since no gate can prove that
      something looks right. It waits on Dave's eye and his word restarts the chain.

## Where I left off

Five rounds of Dave's own reading of the built page are in, and the order matters because two of them
replaced an answer rather than adding one:

1. **The type chip was still there.** The first rule was "render it where the type varies", which is #811's
   wording and fixes nothing -- that page has two distinct types. Replaced by the dominant-type rule.
2. **A title printed twice** on opening a note. First repaired by suppressing the note's title line; then
   replaced by his own answer, which is better: the title leaves the SUMMARY and stays in the note.
3. **`## For consumers` names its own reader.** Now `What changed` at both tiers.
4. **`v4.17` reads as developer shorthand.** Now `Version 4.17`, with the column widened to hold it.
5. **Closing a note left the reader mid-page.** Now it scrolls back to the row.

Two things that cannot be seen in this repo and are exercised in the suite instead: the **`live` chip**
(`releases/README.md` here carries no `**LIVE**` marker) and the **masthead marks** (this repo answers no
wordmark).

Still open after this: **#815** (nothing deletes a merged branch -- and the report's reason is partly
false, the remote half IS documented, so the real repair is the local half plus saying that the GitHub
setting is the lever), **#810** (the audience heading and the rubric docstring -- note that item 3 above
has now answered part of it from the other direction) and **#817** (the stale `Write` on the two branch
files, which happened again on this branch). And the release that would deliver #801 + #807 to the two
Shopify consumers is still waiting on Dave's word.
