## `fix/tier-reason-below-score` progress

### Steps

- [x] Verify inbound #596 still stands against the tree, and check the mechanism it names
- [x] `Read-EntryTierSections`: keep the lines below `**Score:**` instead of discarding them
- [x] One shared helper for the filtering, so a guidance comment below the score is not read as a reason
- [x] The scaffold gate names the misplacement instead of reporting a missing reason
- [x] The release gate (`Get-EntryImpactFindings`) gets the same distinction -- same row, same misdiagnosis
- [x] `open-pr.ps1`'s explanatory paragraph offers the third reading
- [x] Regression tests, including the false-finding guard and the legacy table fallback
- [x] Mirror into the plugin (`build-shared-scripts.ps1`)
- [x] Lint + full suites green

### Where I left off

Done. The scaffold-shape consideration the report raised -- moving the blank space above `**Score:**` so the
mistake is harder to make -- was deliberately NOT built: it changes what every consumer's scaffolder writes,
and the report itself files it as a consideration rather than a proposal. Reported to Dave at close-out.
