## `fix/seam-docs-follow-the-one-document-model` progress

### Steps

- [x] Verify all three of inbound #605's claims against the tree
- [x] `Get-ReleaseConsumerBumps`: the contract's `Returns` says what the knob decides NOW, not before v4.3.0
- [x] Declare `Get-ReleaseNoteWording`, with its own key set and the honest note that it differs
- [x] Sharpen `Get-InternalNoteWording`'s record: it is `new-internal-note`'s map, read only as a fallback
- [x] Repair this repo's own `repo-config.ps1` comments -- the text `adopt-config` copies verbatim
- [x] Define `Get-ReleaseNoteWording` here, so this repo stops being served by the retired name
- [x] Regenerate the blueprint; confirm `releases/notes` present and the inverted sentence gone
- [x] Update the three pinned counts in `script-contract.tests.ps1` and add the record to the expected list
- [x] Confirm the 3 info signals are pre-existing and identical on `main`
- [x] Lint + full suites green

### Where I left off

Done. One thing deliberately left: `releases/internal` still appears twice in the blueprint and both are
correct -- they describe `new-internal-note.ps1`, which is still shipped for a repo running the two-document
flow. Verified rather than assumed before leaving them.
