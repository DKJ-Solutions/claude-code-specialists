## `feat/the-suites-run-in-parallel` progress

### Steps

- [x] Verify parallelism is safe before building it: no suite writes into the repo tree, no two suites share a fixture path
- [x] Rewrite `Invoke-TestSuiteGate` as a throttled parallel scheduler, output buffered per child so a block stays attributable
- [x] Give it `-MaxParallel` as the way back to one-at-a-time, for debugging a suite that only fails under contention
- [x] Point `ci.yml` at the same shared gate instead of its own inline loop over `scripts/tests`
- [x] Mirror the lib into `plugins/specialists/scripts/lib/` via `build-shared-scripts.ps1`
- [x] New suite `test-suite-gate.tests.ps1`: the empty contracts, atomic blocks, the exit code, the timing, the working directory
- [x] Assert in `cut-release-guardrail.tests.ps1` that CI is the third *caller* and not a third copy
- [x] Measure before and after on one machine in one session: 510s sequential against 128-263s parallel over six runs (median 159s), all 27 suites green every time
- [x] Record the two measured `Start-Process` traps in Sylvester's portable manual, and the gate's numbers + remaining critical path in his lens
- [x] Correct Derek's lens, which priced a duplicate gate run at "roughly 13 minutes each"
- [~] Repair the other half of #512 (`check-plugin-integrity.tests`, 154s) — investigated and measured (86 lint runs over one shared fixture, mutated in sequence), but its repair is a redesign of that suite's fixture handling, not a change to the gate. Reported, left to its own branch.

### Where I left off

Done. The gate is parallel, measured, tested, mirrored and documented; the lint, the script contract and
all 27 suites are green.

One thing to carry into the follow-up branch for #512's second half: the gate can no longer go below its
slowest single suite, so `check-plugin-integrity.tests.ps1` at ~154s *is* the gate time now. Its 86
`Invoke-Integrity` calls each pay a fresh `powershell` start (~0.18s) plus a full lint over the fixture
(~1.6s). They cannot be parallelised as-is: all 86 scenarios mutate one fixture directory in sequence, so
the work is to give scenarios their own fixtures first.
