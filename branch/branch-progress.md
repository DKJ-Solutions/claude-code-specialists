## `feat/source-repo-guard` progress

### Steps

- [x] Establish the scope by measurement: both SessionStart hooks invoke `check-roster-sync` and
      `check-script-contract` from the plugin, so a refusal there would fail every session start —
      11 of 13 entry points, hooks untouched (Dave's call)
- [x] Write `scripts/lib/source-repo-guard-lib.ps1`: the test is "does this repo hold its own copy of
      the script now running", not "am I in a plugin cache"
- [x] Register it as a travelling pair — the guard fires from inside the copy that was wrongly run, so
      one that stayed behind could never fire
- [x] Add the guarded dot-source to the 11 entry points
- [x] Test suite, with the allow cases carrying the weight, plus one integration case proving the run
      actually stops before doing any work
- [x] Repair the three claims this made false ("dot-sources no library" in `session-status`, the `lock`
      page and the `continue` page)
- [x] Note the enforcement and the two-script gap in `scripts/README.md`
- [x] Rebuild the shared-script mirror
- [x] Fill in the changelog entry (both tiers, with scores)

### Where I left off

