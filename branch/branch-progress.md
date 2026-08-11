## `fix/refreshbody-keeps-template-sections` progress

### Steps

- [x] Verify inbound #598 still stands, and establish whether this repo can feel it
- [x] `Update-PrBodySection` gains `-StopAtHeading` -- narrowing only, so no existing caller changes
- [x] `open-pr.ps1` reads ALL the template's headings, fence-aware, and passes the later ones as the boundary
- [x] The legacy-heading fallback path gets the same boundary
- [x] `Get-LostBodyHeadings` + a warning naming any section that disappeared from the body
- [x] Regression tests, including the defect itself kept executable and the narrowing-only guarantee
- [x] Re-point the existing text assert that was keyed on the enumeration style rather than the rule
- [x] Mirror into the plugin, lint + full suites green

### Where I left off

Done. Worth knowing for whoever reads this next: this repo's own template has a single H1 section, so nothing
here could reproduce the loss -- the fixture in `pr-body.tests.ps1` is the only place the two-section shape
exists in this tree, and it is deliberately kept there.
