## `feat/releases-portable` progress

### Steps

- [x] Verify inbound #646 still stands (the rule split, the two mirrors, the non-portable sentence)
- [x] `RELEASES-portable.md` created in the plugin from the above-the-rule half, UTF-8 intact
- [x] Portable adaptations: title, intro (own page vs. your page), reading rule, `Get-ReleaseHistoryPath` phrasing for the release list, "points here" sentence made seam-aware
- [x] Relative links resolved: source-tree links stay absolute, every-repo files named in code, CONTRIBUTING link points at the portable sibling
- [x] `releases/README.md` reduced to the local half with a pointer head (CONTRIBUTING.md model)
- [x] Mirroring instruction rewritten: consumers keep only their own half, delete hand-copied mirrors
- [x] Six inbound anchors repointed (CONTRIBUTING.md x3, README.md x2, Rendall's lens x1)
- [x] Lint gate green (dead links, anchors, entry-shape claims)
- [x] Changelog entry written and scored

### Where I left off

After the merge: close inbound #646 with the evidence (both consumers can shrink their mirrors to a
pointer at the next sync). Then the BRANCH-portable (Dave, August 13, 2026): the same split applied to
branch/README.md — deliberately not a PR-portable, because the PR cycle already travels in
CONTRIBUTING-portable.md §§3-5.
