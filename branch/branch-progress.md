## `feat/consumer-facing-document-named-for-its-reader` progress

### Steps

- [x] Move `releases/highlights/` to `releases/consumer/` (11 files, `git mv`, renames detected)
- [x] Repoint the path references in code: `cut-release.ps1`, `release-lib.ps1`, `new-internal-note.ps1`, `script-contract-lib.ps1`
- [x] Rename the seam `Get-ReleaseHighlightsBumps` to `Get-ReleaseConsumerBumps`, reading BOTH names via a `[string[]]$Name` `Get-SeamValue` (recognise both, write one) so an overriding consumer does not fall back to the tier being OFF in silence
- [x] Rename the internal `Build-HighlightsNotes` to `Build-ConsumerNotes` plus its callers
- [x] Regenerate `config-blueprint.json` via `scripts/sync/build-config-blueprint.ps1`, and re-mirror the shared scripts via `scripts/sync/build-shared-scripts.ps1`
- [x] Repoint the links in the archived `releases/development/*.md` notes -- links only (5), prose untouched as a published record
- [x] Update the prose: `CLAUDE.md` (incl. the decision + the five-changelog measurement), `releases/README.md`, `CONTRIBUTING.md`, `CONTRIBUTING-portable.md`, the `cut-release` + `fold-changelog` skills, Rendall's lens, `repo-config.ps1`
- [x] Update the suites, and ADD three asserts on the double read: both names in the code view, the current one first, and `Get-SeamValue` accepting a list
- [~] Rename the word in the already-folded `CHANGELOG.md` entries -- dropped: those describe what the document was called on the day they were written, the same published-record rule as the archived notes, and editing another branch's folded entry invites a needless conflict
- [x] Lint 0 errors, 30/30 suites green, `check-script-contract` clean

### Where I left off

Done. The follow-up is a separate branch: the writing norm for the tier-2 document, from the same
five-changelog measurement.
