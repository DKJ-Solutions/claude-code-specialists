## `fix/the-consumer-draft-strips-its-branch-metadata` progress

### Steps

- [x] Verify the reason before repairing it: read the stripper and establish it works on the HEADING
- [x] `Remove-EntryAdminSections` in `entry-scaffold-lib.ps1`, fence-aware, retired names included
- [x] `-StripAdminSections` on `Format-RankedEntries`, passed only by `Build-ConsumerNotes`
- [x] Give `Remove-EntryPluginsLine` its caller back instead of writing a second one
- [x] Measure the before/after on the real v4.2.0 draft: 396 -> 271 lines
- [x] Asserts: the four sections, retired names, the fenced illustration, the read-before-strip ORDER
- [x] Assert the asymmetry: the development notes keep everything
- [x] Repair the two docstrings this change made stale, and regenerate the plugin mirror

### Where I left off

Done. The gates are the last word: `open-pr` runs the lint and all 30 suites.
