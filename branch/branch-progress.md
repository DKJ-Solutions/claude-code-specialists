## `docs/v4-6-0-timing-total` progress

### Steps

- [x] Measure the five remaining legs from timestamps (document, gates, CI, merge, publish)
- [x] Add the end-to-end total of 64m 52s and the tail share, with the note that 29% vs two thirds is not an improvement
- [x] Recount the gate runs and correct the first pass: ten runs, five local and five in CI, four timed at 26m 58s
- [x] Correct the same claim in the pending `CHANGELOG.md` entry for #634, and say where it was wrong
- [x] Record the release CI figure the first pass could only see as still-running (5m 08s, ran behind)
- [x] Gates, PR, merge, fold

### Where I left off

`v4.6.0` is complete: tagged, pushed, published with both attachments, and its note now carries the total.
Two follow-ups sit with Dave rather than on a branch — untracking
`Microsoft/Windows/PowerShell/ModuleAnalysisCache`, and deciding whether `ship-pr` should skip the gate run
`open-pr` already passed on the same commit.

