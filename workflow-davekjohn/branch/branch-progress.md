## `fix/a-republished-copy-must-not-be-installed-from` progress

### Steps

- [x] Verify #664 against the tree: line counts, the publish script, all five steering lines -- every
      figure holds exactly
- [x] Check the proposed repair before building it: `$PublishedPaths` names `plugins` wholesale, so
      the "one entry" it describes does not exist
- [x] Check the proposed split: two steering lines sit INSIDE the adoption section, so the seam is not
      a line boundary and the split is a rewrite
- [x] Separate the live harm from the restructuring, and ship the harm: a guard note at the top of
      INSTALL.md, UNINSTALL.md and the README paragraph
- [x] Lint gate green
- [x] All test suites green
- [~] `plugins/ADOPTION.md` and the publish-set change -- dropped from THIS branch, not from the work:
      both need a decision about the resulting shape, and the notes shipped here hold under any shape
      that decision takes.

### Where I left off

The live half of #664 is closed. What remains is a project rather than a branch, and it has a shape
question in it for Dave: the adoption half of both pages wants to become its own published page, and
the plumbing wants to stop travelling to the business marketplace -- by moving both pages out of
`plugins/` (the `connectors/` precedent, no new mechanism) or by adding an exclusion list to
`publish-to-business.ps1`.

Also open and waiting on Dave: the decision note on #669 §E (artifact published August 14, 2026), which
B1, C3 and C4's second half all depend on. Parked on his word: #660, the Projects board. Untouched:
#657 and #655.

