## `fix/audience-tier-strings` progress

### Steps

- [x] Verify inbound #640 still stands against the tree (symptom, reason, proposed mechanisms)
- [x] `entry-scaffold-lib.ps1`: resolve the L221-226 / L253-259 contradiction in the tier-ladder comment
- [x] `entry-scaffold-lib.ps1`: Route0/Route1 and Uncomment1/Uncomment2 state the post-#620 definition
- [x] `entry-scaffold-lib.ps1`: retire the pre-#640 route questions into `EntrySignificanceRetiredRoutes`
- [x] `open-pr.ps1`: the refused-entry tier table states the post-#620 definition
- [x] `new-branch/SKILL.md` + `CONTRIBUTING-portable.md`: tier tables updated, webshop worked example added
- [x] Plugin mirrors of both scripts updated byte-for-byte
- [x] `branch/templates/` regenerated from the new wording
- [x] All test suites green
- [x] Changelog entry written and scored
- [x] Copy-edit findings resolved: `branch/README.md` tier table (missed site), one canonical phrase per tier
- [x] Code-review findings resolved: `cut-release.ps1` gate refusals + `open-pr/SKILL.md` tier table (missed sites), BOM stripped

### Where I left off

After the merge: close inbound #640 with the evidence, then pick up inbound #643 on its own branch.
