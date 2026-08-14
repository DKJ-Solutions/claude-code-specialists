## `fix/session-status-open-issues` progress

### Steps

- [x] Verify the reported defect against the tree: line 167 of `scripts/task/session-status.ps1`, the
      mirror, the registry entry, and the recorded remedy in `pr-issues-lib.ps1`
- [x] Measure the old and new parse forms at three, one and zero records before editing anything
- [x] Fix the flattening in `scripts/task/session-status.ps1` (assign first, wrap second)
- [x] Check `$LASTEXITCODE` so an unanswerable `gh` states its degrade line instead of reporting `none`
- [x] Rebuild the plugin mirror via `scripts/sync/build-shared-scripts.ps1`
- [x] Add the four test cases through a child process against a fake `gh` on `PATH`, with a `Get-Block`
      helper so asserts are anchored to one section
- [x] Prove the new asserts fail against the pre-fix script (8 of them do) and restore the fix
- [x] Record the lesson in Sylvester's lens: the trap as a class, plus the `2>$null` and script-scope
      `return` findings
- [x] Run the full gates: plugin integrity 0 errors, script contract 0 errors, all 32 suites green

### Where I left off

Done -- fix, mirror, tests and lens all in, gates green locally. Ready for the PR.
