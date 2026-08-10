## `feat/the-github-release-body-is-generated` progress

### Steps

- [x] Measure the 962-word internal note against test 2 first -- it decides the DOCUMENT model
- [x] `Build-GitHubReleaseBody` in `release-lib.ps1`, reading the PullRequest section rather than the
      first link in the entry
- [x] Wire it into `cut-release.ps1`: written before the commit, inside the path-scoped commit scope,
      with the ready `gh release create` line printed
- [x] Asserts: every tier, unlinked fallback, heading fallback, no invented pointer, the quoted-link trap
- [x] Prove it on the three real pending entries: 10 lines, 57 words
- [x] Retire the skill's three-row body table; keep step 5 last for its new reason
- [x] Rendall's lens: the body policy, and what the internal-note version was actually coupling
- [x] Record the on-`main` lesson in Chris's gatekeepers
- [x] Mirror regenerated, contract check and lint green
- [~] The one-hand-written-note model is NOT in this branch -- it needs the audience decision the
      measurement above fed, and it touches directory layout plus consumer-facing seams

### Where I left off

Done. The document model is the next branch, once Dave has chosen between one blended note and one note
with two named sections.
