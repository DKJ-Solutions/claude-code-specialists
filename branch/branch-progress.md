## `fix/consumer-templates` progress

### Steps

- [x] Write `branch/templates/` from `Get-BranchTemplates` in `new-changelog-entry.ps1`
- [x] Refresh a drifted copy rather than only creating a missing one, and stay silent when nothing changed
- [x] Prove it in a fixture that IS a consumer -- shared scripts only, no lint, no hand-written templates
- [x] Pin both paths with tests: created on a fresh repo, rewritten when it has drifted
- [x] Say so in `branch/README.md` and the `new-branch` skill
- [x] Lint + suites, PR, merge, fold

### Where I left off

Built and green locally. This is Marlowe's repair, taken in the order he advised: **fix the regression
before deleting any prose**, because deleting it first would have made the regression bigger.

The first consumer simulation appeared to fail -- it ran the plugin mirror, which had not been rebuilt
yet. That is the simulation doing its job: it tests what a consumer actually receives, not what the source
tree happens to contain.

Still open after this, and deliberately not started: Tessa's proposal to strip the duplicated form
description from the remaining documents. Marlowe's other three objections stand and need answering first
-- "zero exemptions" is not achievable while `CHANGELOG.md` and `releases/` legitimately carry the section
headings, and the proposed guard catches less than what actually drifted.
