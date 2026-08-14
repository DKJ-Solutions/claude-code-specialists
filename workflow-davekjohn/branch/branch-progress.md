## `feat/workflow-folder` progress

### Steps

- [x] Move the two path constants (`Get-BranchFilePaths`, `$script:BranchTemplateDir`) to `workflow-davekjohn/branch/...` and record the decision in the docstring
- [x] Repoint the three hardcoded sites: `Get-MojibakePaths` (now covers `workflow-davekjohn/` whole) and the two test fixtures (`check-plugin-integrity.tests.ps1`, `new-branch.tests.ps1`)
- [x] Update the coverage prose that quotes `Get-MojibakePaths` (lint check 14) and the contract record's `AdoptWhy`
- [x] PR-template placeholder names the new path; add it as the fourth recognised string in `pr-body-lib.ps1` (recognise four, write one) and update both template files
- [x] `git mv branch workflow-davekjohn/branch` and repoint the moved `README.md`'s relative links one level deeper
- [x] Update the live docs: CLAUDE.md, CONTRIBUTING.md, scripts/README.md, the portable pages, the six workflow skills, the two lenses, plugins/INSTALL.md — dated records stay as written
- [x] Rebuild the generated layers: shared-scripts mirror + config blueprint
- [x] Gates green: full lint + all test suites on the moved tree (check-20 fixture followed the seam; one archived-note link repointed)

### Where I left off

Phase 2 (separate branch): the scaffold skill that places `workflow-davekjohn/` at a consumer
(README.md, CLAUDE.md, CONTRIBUTING.md, releases/README.md + audience/), the contract marker that
reports the folder missing, and the two path-depth fixes the relocated releases root needs at a
consumer (`cut-release.ps1` history-row relpath, `release-lib.ps1` `../../../` depth).
