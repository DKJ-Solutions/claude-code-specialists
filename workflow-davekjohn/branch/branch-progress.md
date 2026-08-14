## `feat/workflow-folder-scaffold` progress

### Steps

- [x] Build `scripts/task/adopt-workflow-folder.ps1`: dry-run default, `-Apply`, additive-only, refuses a plugin-publishing repo, branch files from the shared formatters
- [x] Register it in `shared-scripts-lib.ps1` and write the `adopt-workflow-folder` SKILL.md (params documented, `${CLAUDE_PLUGIN_ROOT}` command form)
- [x] Add the workflow-folder existence marker to `check-script-contract.ps1` ([ERROR], existence only, after the bootstrap early-exit)
- [x] Repair the history-table row: `Get-RelativeLinkPath` in `release-lib.ps1`, anchored on the history file's directory; guardrail asserts repinned on the derivation
- [x] Repair the note's link prefix: derived from the note path's own depth in `cut-release.ps1`
- [x] Tests: new `adopt-workflow-folder.tests.ps1` (4 scenarios), the missing-folder scenario + fixture folder + three [OK]-count pins in `script-contract.tests.ps1`, five `Get-RelativeLinkPath` cases in `release-lib.tests.ps1`
- [x] Plugin README skills table gains the row; mirror + blueprint rebuilt
- [ ] Gates green: full lint + all test suites

### Where I left off

The project this belongs to is complete after this branch unless Dave extends it: phase 1 (the
branch dossier moved into the folder) merged as #654. A consumer adopting the folder answers two
`decide` seams (`Get-ReleaseNoteRoot`, `Get-ReleaseHistoryPath`) — the scaffold's closing block and
the skill page both say so.
