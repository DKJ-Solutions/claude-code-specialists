## `feat/publish-to-business` progress

### Steps

- [x] Move `publish-to-business.ps1` from the repo root to `scripts/release/` and test it against the script contract, the lint gate and the CONTRIBUTING conventions
- [x] Move the target repo out of the script into `scripts/repo-config.ps1` (`Get-BusinessMarketplaceRepo`, optional function with fallback), keep `-TargetRepo` as override
- [x] Write `scripts/tests/publish-to-business.tests.ps1` against a local bare-repo fixture: integrity check refuses, deletions travel, second run is idempotent
- [x] Check the script for Windows PowerShell 5.1 compatibility (`git init -b`, `Group-Object` with scriptblock) and run the suite under `powershell`
- [x] Document the publication step as a separate, manual decision after the release cut (`RELEASES-portable.md` and/or the `cut-release` skill)
- [x] Write the changelog entry
- [x] Reviews (code, copy, security) on the diff — run in the main loop under each specialist's name after the review subagents were cut off by the org spend limit. Victor found the StrictMode/5.1 property defect (repaired, plus 6 asserts); Edith found two stale figures in the entry (repaired); Sebastian found no secrets or PII, and named the `-TargetRepo` git-option surface as an accepted risk rather than a repair

### Where I left off

After the merge: report to Dave the three items his prompt asked for an opinion on rather than a
change — the `extraKnownMarketplaces` name collision once the org marketplace arrives under the same
key, the `INSTALL.md`/`README.md` lines pointing colleagues at the private source repo, and
PowerShell's absence on Cowork's Linux runners. None of them is built on this branch, deliberately.

