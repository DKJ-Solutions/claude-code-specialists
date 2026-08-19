## `feat/branch-files-cycle-and-deployment` cycle · 20260819-171114

### PLAN

- [x] Read both hand-edited templates as the spec, and measure what the generator would have to change
- [x] Settle the two questions the artefacts do not answer: rename the files with a dual-read, and move
      the creation stamp to the cycle file (Dave, August 19, 2026)

### CREATE

- [x] `entry-scaffold-lib.ps1`: the two title words, the retired `StepsHeading`/`TemplateMarker`, the
      fourth phase and its guidance, the phases at H3, the stamp moved to the cycle scaffold
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

### TEST

- [x] The generator reproduces both hand-edited templates byte for byte (deployment exactly; the cycle
      with the two prose corrections named in the entry)
- [x] `check-plugin-integrity.ps1` green, including the byte-exact `[branch-template]` check
- [x] All test suites green, with the expectations updated where the shape changed
- [x] New asserts for what is new: the cycle stamp, the merge restamp, the dual-read, and an entry whose
      heading still says `changelog`

### DEPLOY

### Where I left off

Everything is in the working copy and the gates are green. The two judgement calls that need Dave's eye
are named in the entry: the DEPLOY paragraph in the cycle template's guidance (his text said "DEPLOY is
missing on purpose" while the heading is now there), and the fold's closing line, which keeps the PR link
while the merge moment moved to the `Pull Request` heading.
