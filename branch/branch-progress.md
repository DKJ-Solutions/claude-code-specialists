## `fix/untrack-powershell-module-cache` progress

### Steps

- [x] Confirm what is actually tracked: one file, `Microsoft/Windows/PowerShell/ModuleAnalysisCache`,
      added in `65902dd`
- [x] `git rm --cached` it — the file stays on disk, it is PowerShell's to write
- [x] Ignore `/Microsoft/` (the tree, anchored at root) with the reason and the two blocked cuts recorded
      above it
- [x] Verify: `git check-ignore` resolves it, `git status` is clean of it, the file is still on disk
- [x] `open-pr` → gates → merge → fold

### Where I left off

**Done and merged.** This closes the first of the three items that were sitting with Dave.
