# `fix/audience-section-names-its-reader` cycle · 20260821-185755

## PLAN

- [x] Verify inbound #810 still stands: both seam spots read exactly as reported.
- [x] Check the repair the report proposes. It says the guidance "survives in the entry until the author
      replaces it"; it does not -- `-WithGuidance` has been off for the working file since August 7, 2026,
      so the block renders into `branch/templates/branch_template_deployment.md` beside it. Same layer,
      neighbouring file, so the proposal holds with its mechanism corrected.
- [x] Decide against touching the heading, which the report also declines: retexted three days ago for a
      reason that still stands.

## CREATE

- [x] `scripts/lib/entry-scaffold-lib.ps1`: the `TierOptional` guidance block now says who the section is
      about, and that N/A plus one or two lines is a complete and common answer.
- [x] Same file: `Get-EntrySignificanceRubric`'s docstring states the property a reworded band has to
      keep -- it stays a test about the reader.
- [x] Mirror to `plugins/workflows/workflow-davekjohn/scripts/lib/entry-scaffold-lib.ps1`, byte-identical.
- [x] Regenerate `workflow-davekjohn/branch/templates/branch_template_deployment.md` -- generated, not
      maintained, so `new-branch.ps1` refreshes it rather than a hand edit.
- [~] A contract check flagging a reader-less override: not built. The reporter's own reasoning -- it is a
      heuristic, and "cosmetic" is a reader-relative band with no pronoun in it.

## TEST

- [x] Lint gate + all suites, via `open-pr.ps1`.

## DEPLOY

## Where I left off
