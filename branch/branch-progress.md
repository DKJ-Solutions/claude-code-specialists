## `docs/score-1-names-what-it-prevents` progress

### Steps

- [x] Reword band 1 in `Get-EntrySignificanceRubricDefaults` so it asks for the prevented failure
- [x] The places that quote the band verbatim: `CONTRIBUTING.md`, the `new-branch` skill, the contract's default summary
- [x] Record WHY a `tier0 < tier1` gate was rejected, where the next person would go looking for it
- [x] Mirrors, lint, suites

### Where I left off

Lint 0 findings, all 26 suites green, script contract 0 errors.

Worth carrying forward: **no suite asserts the band texts**, deliberately left that way. A test pinning the
wording would fail on every deliberate retune and prove nothing about behaviour -- the rubric is prose the
gates print, not a value they branch on. What IS worth guarding is the shape (five bands, 1 to 5), and
`Get-EntrySignificanceRange` already has that covered.

Next in the queue: #507 (parking: one goal, two mechanisms -- note the rename is consumer-visible), then
#508, #512, #456.
