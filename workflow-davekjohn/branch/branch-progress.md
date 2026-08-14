## `feat/adoption-is-its-own-page` progress

### Steps

- [x] Find the real seam: two of the five steering lines sit INSIDE the adoption section, so the split
      runs between Step 1 and Step 2 rather than at a section boundary
- [x] Write `plugins/ADOPTION.md`: the three adoption steps, renumbered, with every back-reference to
      what stayed behind repaired
- [x] `INSTALL.md` keeps the plumbing and points at the new page
- [x] `git mv` both plumbing pages to the repo root, so the folder boundary keeps them out of the
      business publish set -- no exclusion list
- [x] Repoint every link: 8 files by hand-checked rule, 5 more the link scan found, plus the release
      records (links only -- their prose stays as written)
- [x] `Get-ReservedRootMd` gains both files, or the next release reads them as unfolded entries
- [x] `$consumerDocs` gains `plugins/ADOPTION.md` -- the document that now carries the samples checks
      15 and 16 exist for, exactly as that list's own comment predicted
- [x] Repair `cut-release-guardrail.tests.ps1`, which asserted about the fallback literal instead of
      the seam this repo actually answers
- [x] Repoint the lint-suite fixture and its 14 assert patterns
- [x] Regenerate the config blueprint
- [x] Lint gate green
- [x] All 35 test suites green

### Where I left off

#664 is done. Next in the yolo run: #669 §E -- build Chris as a skill, which is the recommendation in
the decision note and closes B1 -- then C3, #657 and #655. #660 stays parked on Dave's word.

