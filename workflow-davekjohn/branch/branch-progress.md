## `docs/release-craft-off-always-on` progress

### Steps

#### PLAN

- [x] Read all 474 lines of the release-commit sub-item and classify each block operative vs evidence
- [x] Rule applied: if a specialist could act wrongly without the sentence it stays, otherwise it moves
- [x] Split presented to Dave before cutting, because it came out 87% rather than the implied "some"
- [x] Confirm the six inbound anchors point at the section heading, which does not move

#### CREATE

- [x] Move ~429 lines into Rendall's lens under one dated, provenanced `###` section
- [x] Sub-headings inserted at boundaries the content already had -- no structure invented
- [x] Relative links repointed for the new depth; prose otherwise verbatim, per the published-record rule
- [x] `CLAUDE.md` keeps the exception, its bound, the major's two commits, and the branch+PR rule for the notes
- [x] Pointer from the operative half into the evidence, so the trail is one click
- [x] Sylvester's lens records the PowerShell round-trip encoding trap that bit twice this session
- [~] Sub-structuring the moved block further -- dropped: the bold leads already carry it, and inventing
      headings risks mis-grouping prose that was moved verbatim

#### TEST

- [x] `check-plugin-integrity.ps1` green -- including the anchor and mojibake checks
- [x] No control characters and no mojibake in either edited document
- [x] All 36 suites green
- [x] `check-script-contract.ps1` + `check-roster-sync.ps1` green

### Where I left off

Finished. `CLAUDE.md` 875 -> 452 lines. The always-on layer drops from ~41,800 to ~30,300 tokens.
