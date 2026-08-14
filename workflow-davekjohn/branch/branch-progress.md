## `feat/publish-to-business` progress

### Steps

- [x] Move `publish-to-business.ps1` from the repo root to `scripts/release/` and test it against the script contract, the lint gate and the CONTRIBUTING conventions
- [x] Move the target repo out of the script into `scripts/repo-config.ps1` (`Get-BusinessMarketplaceRepo`, optional function with fallback), keep `-TargetRepo` as override
- [x] Write `scripts/tests/publish-to-business.tests.ps1` against a local bare-repo fixture: integrity check refuses, deletions travel, second run is idempotent
- [x] Check the script for Windows PowerShell 5.1 compatibility (`git init -b`, `Group-Object` with scriptblock) and run the suite under `powershell`
- [x] Document the publication step as a separate, manual decision after the release cut (`RELEASES-portable.md` and/or the `cut-release` skill)
- [x] Write the changelog entry
- [ ] Reviews (code, copy, security) on the diff

### Where I left off

