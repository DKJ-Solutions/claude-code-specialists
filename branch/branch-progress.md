## `feat/test-gate-commands` progress

### Steps

- [x] Verify inbound #644 still stands (the gate's glob, both call sites, the guardrail list omission)
- [x] `Invoke-TestSuiteGate`: read the optional `Get-TestCommands` inside the gate, run each command as a child with the exit code propagated
- [x] Empty-input contract kept: neither suites nor commands is still a quiet pass; commands-only runs a real gate
- [x] Contract record for `Get-TestCommands` (`Adopt = 'decide'`), blueprint artefact regenerated
- [x] `cut-release.ps1` seam list grows to eight; `open-pr.ps1` gate comment names the seam
- [x] `releases/README.md`: guardrail list carries the test gate and `-SkipTests`; the seam described beside the lint gate's
- [x] Tests: three new gate cases (passing command, native exit-code propagation, commands-only); count asserts updated
- [x] Mirrors updated byte-for-byte (native-capture-lib, script-contract-lib, cut-release, open-pr)
- [x] Affected suites green (test-suite-gate, script-contract, config-blueprint, cut-release-guardrail, shared-scripts)
- [x] Changelog entry written and scored

### Where I left off

After the merge: close inbound #644 with the evidence. Then inbound #646 (RELEASES-portable.md) is the
last open issue — its checklist builds on #643's repairs to the same page.
