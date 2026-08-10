## `fix/the-fold-refuses-a-pre-flat-changelog` progress

### Steps

- [x] Verify inbound #561 still stands: the fold has no pre-flat detection, and the cut's guard lives in
      release-lib where the fold cannot reach it
- [x] Move `Get-EntryHeadingPattern` + `Split-EntryBlocks` down into `entry-scaffold-lib.ps1`, following the
      `Get-FencedLineFlags` precedent, leaving a MOVED-NOT-DELETED note in `release-lib.ps1`
- [x] Add `Get-ChangelogEntryBlocks` + `Get-PreFlatChangelogRefusal` beside `Test-EntryDeclaresShape`
- [x] Have `Split-Changelog` read the shared refusal instead of its inline copy, passing the cut's own
      consequence clause
- [x] Refuse in the fold's pre-pass, before any write, naming the entry file still waiting
- [x] Mirror the shared scripts into the plugin
- [x] Tests: the fold refuses a pre-flat document byte-identically and folds a fence-quoted one; unit tests
      for the shared refusal; ownership asserts for both moved functions
- [x] Lint gate + all suites green

### Where I left off

Done. The one thing worth remembering from the round: the first version of the "the fold does not load
release-lib" assert was written as `-notmatch 'release-lib'` and went red against a correct script, because
the fold's header explains at length why it does not load that lib. A matcher satisfied by a mention rather
than a use — the fifth instance of that class here. It is keyed on the dot-source line now, with the trap
recorded above the assert.
