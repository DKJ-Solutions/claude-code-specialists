## `fix/test-fixtures-survive-a-concurrent-run` progress

### Steps

- [x] Reproduce the collision rather than infer it: two concurrent `connectors.tests.ps1` runs
- [x] Measure the real subject: 14 fixed temp paths across 11 files, against 38 already correct
- [x] Verify the two `$tag` cases are GUID-based (false positives in the first crude scan)
- [x] Confirm no name is referenced outside its own suite before renaming anything
- [x] Add `$PID` to all 14, matching the convention the other 38 already use
- [x] A guard in `test-suite-gate.tests.ps1`, the suite that owns concurrency since #512
- [x] Prove the guard fires: sabotage one file, confirm it goes red and names `file:line`
- [x] Prove the fix: the same concurrent runs, now green twice over
- [x] `scripts/README.md` states the rule where a new suite's author will meet it
- [x] Lint + full suites green

### Where I left off

Done. Two things a later reader might otherwise re-derive: the `.measure.ps1` files are in the guard's scan
too (same temp directory, same concern), and `$Label` deliberately does not satisfy it -- it varies within a
run and repeats across them, which is exactly what was wrong at `bootstrap-drift.tests.ps1:318`.
