## `feat/the-consumer-document-is-written-for-its-reader` progress

### Steps

- [x] Measure the candidate gates over the eleven consumer documents before building any: link-into-another-tier (2 findings, 2 true), score leak (4, 0 true), branch name (3, 0 true)
- [x] Build lint check 25 on the surviving rule -- link TARGETS only, so a tier named in prose or link text is not accused
- [x] Remove the two real findings (`4.0.0`, `3.5.0`) so the gate is not born red behind an exemption list
- [x] Write the seven-test norm into the portable `cut-release` skill, each test carried by what a named changelog in the field does
- [x] Eight asserts on check 25 in `check-plugin-integrity.tests.ps1`, including all three deliberate narrowings and the tier-off case
- [x] Record the decision and the three-rule measurement in `CLAUDE.md`
- [x] Lint + all suites green -- 0 errors, 11 consumer documents scanned with 0 findings, 30/30 suites, 202 asserts in the lint's own suite

### Where I left off

Done.
