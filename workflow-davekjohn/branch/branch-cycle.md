# `feat/branch-files-cycle-and-deployment` cycle · 20260819-171114

## PLAN

- [x] Read both hand-edited templates as the spec, and measure what the generator would have to change
- [x] Settle the two questions the artefacts do not answer: rename the files with a dual-read, and move
      the creation stamp to the cycle file (Dave, August 19, 2026)

## CREATE

- [x] `entry-scaffold-lib.ps1`: the two title words, the retired `StepsHeading`/`TemplateMarker`, the
      fourth phase and its guidance, the phases as the file's own sections, the stamp moved to the cycle
      scaffold
- [x] `Get-BranchFilePaths` renamed, `Resolve-BranchFilePath` added as the one place the dual-read lives
- [x] The merge stamp on the `Pull Request` heading: `Get-EntrySectionHeadingTail` for the six readers,
      `Set-EntryMergeStamp` for the fold
- [x] The callers: new-branch, open-pr, ship-pr, fold, cut-release, adopt-workflow-folder, the lint,
      `pr-body-lib` (a fifth recognised placeholder) and both PR templates
- [x] The docs: `BRANCH-portable.md`, `CONTRIBUTING-portable.md`, four skill pages, the branch README,
      `CLAUDE.md`, `INSTALL.md`, the three lenses
- [x] Rename this repo's own pair and regenerate the templates from the generator
- [~] A migration for consumers that renames their existing pair -- dropped: the readers recognise both
      names, so nothing is stranded, and a script that renames files in somebody else's tree is a bigger
      promise than the problem needs
- [x] The cycle file becomes a document in its own right (Dave, by hand in the template): its own two
      heading levels, `Get-BranchCycleHeadingLevel` / `Get-BranchCycleSectionLevel`, the two writers
      repointed, the live pair promoted, and `BRANCH-portable.md` corrected where it claimed both files
      switch level
- [x] The lint's section reader gets the same tolerant tail the lib's six got -- the seventh, and the one
      left out, which would have raised `[entry-heading]` on the first fold and blocked every PR after it
- [x] The fold puts the landing date on the closing line where there is no `Pull Request` heading to
      stamp -- the pre-dossier shape, which otherwise loses it silently

## TEST

- [x] The generator reproduces both hand-edited templates byte for byte (deployment exactly; the cycle
      with the two prose corrections named in the entry)
- [x] `check-plugin-integrity.ps1` green, including the byte-exact `[branch-template]` check
- [x] All test suites green, with the expectations updated where the shape changed
- [x] New asserts for what is new: the cycle stamp, the merge restamp, the dual-read, and an entry whose
      heading still says `changelog`
- [x] The cycle-shape asserts read the level instead of typing it, so a promotion is not reported as a
      defect; plus the relation itself (title one level above its sections, both above the entry's)
- [x] A lint scenario on the fold's own output: a stamped `Pull Request` heading passes, and the same
      heading MISSPELLED is still refused -- the tolerance is the stamp, not the name
- [x] The footer fallback and the silent no-op it exists for, asserted as a pair

## DEPLOY

## Where I left off

Done, and on its way out. PR [#762](https://github.com/DaveKJohn/claude-code-specialists/pull/762) is open
and green; this second round added the two review findings and Dave's own promotion of this file's headings.
Lint 0 errors, all 43 suites green (4,313 asserts).

The one thing worth carrying forward, if anything here is ever revisited: the review found the lint's
section reader was the **seventh** of a set of six that had been repaired together, and the failure would
have landed on `main` rather than on this branch -- the fold is the one write that skips every PR gate, so
its output is the one shape no gate had seen. Both new asserts are built from the fold's real output for
that reason.
