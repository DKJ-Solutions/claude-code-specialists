## `feat/one-hand-written-release-note` progress

### Steps

- [x] `Build-ReleaseNoteDraft` in `release-lib.ps1` -- three sections, consumer half pre-filled
- [x] `cut-release.ps1`: draft it, guard it, point the overview row at it, print the edit as the follow-up
- [x] Split the two conditions: the seam decides whether there is a document, tier 2 whether it has a
      consumer section
- [x] Lint check 25 reads `releases/notes/` as well as the `releases/consumer/` archive
- [x] Fix the strict-mode `.Count` bug the gate's own run caught
- [x] 19 asserts on the draft, including the absent consumer section and the retired heading
- [x] Repoint the guardrail assert from the consumer path to the note, and add one for the body
- [x] Docs: the tier table in `CLAUDE.md`, the `cut-release` skill steps 1-4, Rendall's lens
- [x] Mirror regenerated; lint and all 30 suites green locally
- [~] `new-internal-note.ps1` NOT deleted -- it ships to consumers and still works; nothing here calls it
- [~] The 23 archived documents NOT migrated -- published records stay put

### Where I left off

Done. The first cut under this model will be the proof: the draft has so far been produced by the suite and
by hand against the pending entries, never by a real run.
