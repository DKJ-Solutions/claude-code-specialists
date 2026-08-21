# `feat/release-page-second-pass` cycle · 20260821-153659

## PLAN

- [x] Read #809, #811, #813 and #816 in full and settle the interactions BEFORE writing anything. #816
      names the one that bites: drop the row's type chip and the note's `**Type:**` separately and the
      newest release ends up with no type anywhere, because `live` displaces the chip.
- [x] Settle where each fix belongs. #816's own reading is the right one -- the note is read in two
      places and the block is redundant in only one, so this is a RENDERING change. That is also the
      only shape that reaches the forty notes already published, which are records and are not
      rewritten.
- [x] Two asks were judgements rather than requests, and both are stated in the entry rather than made
      silently: the three-row layout is the narrow query only (desktop keeps one line), and the collapse
      affordance is pure CSS (a sticky summary) so the page keeps reading with JavaScript off.

## CREATE

- [x] Template: trailing chevron with no gutter reserved ahead of the text, sticky summary while open,
      responsive `.sheet` margin, three-row narrow layout, the masthead marks block, and a deep-link
      handler that accepts the trimmed version spelling.
- [x] Builder: five pure functions -- `Format-ReleaseMastheadMarks`, `Test-ReleaseTypeVaries`,
      `Test-ReleaseVersionTrimmable`, `Format-ReleaseVersionLabel`, `Remove-NoteMetadataHeader`.
- [x] The two page-wide answers are derived ONCE from the release list rather than per row, because both
      are properties of the set -- and read off the data rather than a seam, which is what makes them
      right for a consumer whose bump policy differs.
- [x] `Get-ReleasePageMasthead` registered in the script contract (`Adopt = 'decide'`, optional), the
      config blueprint regenerated, and the seam documented in the `release-notes-page` skill.
- [x] The function block had to move ahead of the note-reading loop: PowerShell runs top to bottom, and
      `Remove-NoteMetadataHeader` is called while the notes are read. Caught by the first real build.

## TEST

- [x] `scripts/tests/release-notes-page.tests.ps1`: 87 -> 127 asserts. Every way the masthead seam can
      be answered wrongly (a URL, a raw svg payload, three marks, an oversized one) plus the layout
      claims as CSS positions, the way the palette-position assert already worked.
- [x] Five existing asserts in the index group were held against the OLD markup and were updated rather
      than deleted: the chip is now two spans with one shown, so the count moved from one to two while
      the rule it was written for -- never a type and a live marker on one row -- gained an assert of
      its own.
- [x] One new assert was wrong rather than the code: the `-WithPatchNote` fixture gave `2.1.0` a note,
      and `2.1.0` ends in `.0` like the rest, so nothing was off the pattern. It is `2.1.1` now, with
      the reason written beside it.
- [x] Built against this repo's own 27 notes and read the output: labels trimmed to `v4.17` with the ids
      still `v4.17.0`, the type chip kept because this page really does vary (1 Major, 26 Minor), and no
      body opening with its own heading any more.
- [x] Lint gate green (0 errors, 22 checks), script contract 0 errors with the expected `[INFO]` for the
      new optional seam, both mirrors in sync.

## DEPLOY

- [~] Not pushed, and this is the one branch on which that is the correct mark. The deliverable is a
      RENDERED PAGE, which is the first of the two exceptions in the safety rules: no gate can prove
      that something looks right. It waits for Dave's eye on
      `workflow-davekjohn/releases/page/release-notes.html`, and his word restarts the chain.

## Where I left off

The page is built and committed on this branch, ready to open in a browser. What to look at, in the order
the asks came in:

- the row on a **narrow** window (under 38rem): three lines, chip hard right, chevron trailing;
- **open a long note and scroll** -- the summary should stay put as the way back out;
- the version column reading `v4.17` while the link target is still `#v4.17.0`;
- an opened note starting on its own text rather than on `# Release notes v4.17.0`.

Two things that cannot be seen in this repo and are worth knowing: the **`live` chip** never appears here
because `releases/README.md` carries no `**LIVE**` marker, and the **masthead marks** are absent because
this repo answers no wordmark -- both are exercised in the suite instead.

Still open after this: **#815** (nothing deletes a merged branch -- and the report's reason is partly
false, the remote half IS documented, so the real repair is the local half plus saying that the GitHub
setting is the lever), **#810** (the audience heading and the rubric docstring) and **#817** (the stale
`Write` on the two branch files -- which happened twice on this branch, as it happens). And the release
that would actually deliver #801 + #807 to the two Shopify consumers is still waiting on Dave's word.
