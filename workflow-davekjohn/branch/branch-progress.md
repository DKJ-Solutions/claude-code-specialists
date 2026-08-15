## `feat/claude-app-publication` progress

### Steps

#### PLAN

- [x] Verify #683 still stands against the tree (filed 07:32Z today; the two commits since are the
      v4.9.0 release-note docs, unrelated) and re-check every fact it states as its starting position
- [x] Sweep the tree per item: 6 plugins, 17 skills, 2 hook bundles, 26 agent defs, 4 personas,
      15 manuals, 15 shared blocks, 34 plugin scripts
- [x] Settle the classification rule by measuring candidates, not by argument --
      `grep -rl '\.ps1' plugins --include='*.md'` gives 30, of which 28 true
- [x] Decide what the App package IS: a filtered publication to the existing target, same marketplace
      name, no new repo and no per-entry hide flag
- [~] Come back to Dave with the four open questions before building -- dropped: he switched the
      session to yolo mode mid-turn ("je hoeft niet te wachten op mijn beslissing"), so the questions
      are answered in the entry and the README instead of asked

#### CREATE

- [x] `Get-BusinessMarketplacePlugins` in `scripts/repo-config.ps1`, with the reasoning for excluding
      both workflows and for keeping the unit at the plugin
- [x] `publish-to-business.ps1`: `-Plugins`, `Select-PublishedPlugins` (prune + rewrite the manifest +
      drop an emptied kind directory), `Write-ManifestJson`, and the reverse integrity check
- [x] Fix the two defects the first dry run surfaced: the ANSI decode of the manifest, and `-File`
      binding `-Plugins a,b` as one string
- [x] The map as a README section beside *Where this runs*, with the rule and the three-valued verdict
- [x] Block 3 of the `cut-release` skill and `RELEASES-portable.md` -- the portable half, so a consumer
      receives the question rather than this repo's answer
- [x] Repair the stale repo-layout claim about `plugins/INSTALL.md` / `plugins/UNINSTALL.md` (#664)

#### TEST

- [x] `publish-to-business.tests.ps1`: seven new cases on a second fixture shaped like the real
      marketplace -- 58 asserts green
- [x] `repo-config.tests.ps1`: the tripwire that no workflow may enter the App keep-list, and that the
      list is never empty (empty publishes everything) -- 44 asserts green
- [x] Lint gate green (0 findings, 27 checks)
- [x] Dry run against the real target: 4 plugins, 98 files, manifest valid and encoding clean
- [x] Full suite via `open-pr`

### Where I left off

Everything on this branch is done. The publication itself is NOT part of it: running
`publish-to-business.ps1` for real changes what Claude App users receive, which is the outward-facing
act the constitution keeps out of a blanket go-ahead. It waits for Dave to ask for it, as Block 3 of the
cut-release checklist already says it should.
