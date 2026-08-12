## `fix/release-row-note-root` progress

### Steps

- [x] Undo the local, unpushed `v4.6.0` cut (tag deleted, commit reset, 16 entries restored) — authorised by Dave
- [x] Derive the overview row's Version cell from `Get-ReleaseNoteRoot` instead of a hardcoded `notes/`
- [x] Mirror the fix into `plugins/workflows/workflow-davekjohn/scripts/release/cut-release.ps1`, verified byte-identical
- [x] Pin the Version-cell line in `cut-release-guardrail.tests.ps1`, and explain why the two existing seam asserts could not see it
- [x] Confirm the new asserts go red against the reintroduced bug, then restore the file
- [x] Fill in the changelog entry and this step list
- [x] Lint + test gates, PR, merge, fold
- [~] Fix the tracked `Microsoft/Windows/PowerShell/ModuleAnalysisCache` — dropped from this branch deliberately: it is a separate defect (a machine-local binary cache committed by accident in `65902dd`, which dirties the tree and blocked the first cut), and folding it in here would put an unrelated repo-hygiene change inside a release-blocking fix. Reported to Dave for its own branch.

### Where I left off

Fix merged and folded. The re-cut of `v4.6.0` runs on top of it, as the release commit on `main`.

