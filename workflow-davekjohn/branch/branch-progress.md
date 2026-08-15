## `docs/always-on-token-calibration` progress

### Steps

#### PLAN

- [x] Calibrate chars/token against 10 API-counted skill pages: median 3.12, mean 3.07, range 2.95-3.23
- [x] Re-measure the always-on layer at the corrected factor, plugin listings included: ~41,800 tokens
- [x] Establish the loaded persona is the marketplace copy (11,051 B), not the repo source (12,294 B)
- [x] Break `CLAUDE.md` down by section to locate the cost: one sub-item is 41,168 B

#### CREATE

- [x] Nolan's portable manual gains the calibration rule -- the portable half of the lesson
- [x] Nolan's lens: the corrected numbers, the section breakdown, and which copy is measured
- [x] The two stale conversions in the lens are marked at the factor they were computed with, not rewritten

#### TEST

- [x] `check-plugin-integrity.ps1` green
- [x] Test suites green
- [x] `check-script-contract.ps1` + `check-roster-sync.ps1` green

### Where I left off

Finished. The measurement this branch records is the standing evidence for the follow-up branch that
acts on it -- moving the release craft off the always-on path into Rendall's on-demand lens.
