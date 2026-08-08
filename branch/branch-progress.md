## `feat/config-blueprint` progress

### Steps

- [x] Classify all 22 seam functions on the new axis (safe to copy vs. this repo's to decide), with a reason per record
- [x] Extract the contract registry into `scripts/lib/script-contract-lib.ps1` -- three readers now, one source
- [x] `build-config-blueprint.ps1`: derive the artefact from this repo's own libs, never hand-written
- [x] `adopt-config.ps1`: place the copyable answers, propose the rest, never overwrite
- [x] Lint check 21: hold the shipped artefact against a fresh generation
- [x] Test suite `config-blueprint.tests.ps1`, including a regression assert per extraction bug found
- [x] Skill page + shared-scripts registration + mirror
- [x] README: the blueprint and the two markers, for the consumer who reads that page
- [~] Step 4 of the issue (create the missing `releases/` tiers) -- dropped: measured that `cut-release.ps1` and `new-internal-note.ps1` already create their own note directories, so there was nothing left to build
- [~] Step 5 of the issue (migrate a sectioned `CHANGELOG.md` to flat) -- dropped from THIS branch: it migrates a document rather than the config, and the issue's title is the config adoption. It gets its own branch, named in the close-out
- [x] Lint + all 28 suites green, then PR + merge + fold

### Where I left off

