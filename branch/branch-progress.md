# Branch progress

**Branch:** `fix/impact-strip-takes-its-heading`

## Steps

- [x] Establish where the empty section comes from and that the record (development notes) is unaffected
- [x] Confirm v3.5.0 did not ship it, so this is a regression rather than long-standing
- [x] Make `Remove-EntryImpactTable` drop the section heading when the section it introduced is empty
- [x] Keep the heading when the section holds anything else, and stay fence-aware on both halves
- [x] Add asserts for all three cases and verify them by falsification
- [x] Reverse the `release-lib` assert that pinned the broken behaviour, with the reason recorded
- [x] Mirror the lib into `plugins/specialists/scripts/lib/`
- [x] Run every suite

## Where I left off

Done. All suites green. Ready for the gates and the PR; after the fold, v3.6.0 is cut again — the
previous attempt's commit and tag were rolled back locally with Dave's word and were never pushed.
