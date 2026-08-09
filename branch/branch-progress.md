## `feat/teams-and-workflows-rename` progress

### Steps

- [x] The five folders renamed with `git mv`, still flat under `plugins/`
- [x] Five `plugin.json` manifests: name, displayName and a description that states the new model
      (teams stack, workflows do not). The core's description also stopped claiming it ships
      `connector-sessioncheck`, which moved to the workflow plugin on August 8
- [x] `.claude-plugin/marketplace.json`: five names, five sources, and the top-level description
- [x] `.claude/settings.json` and `connectors/claude-code-specialists.json` -- this repo consumes
      itself, so it migrates in the same change
- [x] The three OTHER consumer manifests deliberately left on their old ids: the register records what
      a consumer HAS, and claiming a migration they have not done turns the register into a false alarm
- [x] The shared-scripts registry: two values, thanks to branch 1
- [x] Code literals: `bootstrap.ps1`'s workflow plugin name, `build-config-blueprint.ps1`'s output
      path, `teardown.ps1`'s two notes, the lint's printed install command
- [x] `adopt-config.ps1`: the two workshop blueprint paths derived from the marketplace instead of
      spelled out, so branch 3 needs no change here either
- [x] 11 manual headers naming their plugin
- [x] Docs swept in name order, longest first, so `claude-code-specialists` (the marketplace) and the
      `specialists-init` / `specialists-teardown` skill names could not be caught in the crossfire
- [x] The `.claude/plugins/claude-specialists/<plugin>/` lens path: the FAMILY segment stays, the
      PLUGIN segment moves. Six files, and getting that pair the wrong way round would have pointed
      every consumer's lens reader at a directory nobody writes
- [x] `releases/**`: link TARGETS repointed, prose left as history. A historical note's claims are
      history; its links have to keep resolving or the note is unreadable
- [x] Test suites: ~70 pinned names across 12 files
- [x] Three places where the rename quietly hollowed something out, each repaired rather than swept:
      the sibling-prefix and case asserts in `release-lib.tests.ps1` (they no longer shared a prefix
      or differed only in case, and passed while testing nothing), the ordinal-sort claim in
      `check-report-lib.ps1` (its example pair no longer demonstrates the difference -- now asserted
      on a synthetic pair instead), and the bootstrap durable-body fixture (cache dir and clone dir
      naming different plugins)
- [x] Gates green after the rename: lint 0 errors, all 28 suites
- [x] The model narrative: the group numbering recast as teams and workflows across the docs (Tessa),
      plus the four follow-ups she flagged in the script/manifest layer -- including the marketplace
      description, which COUNTED the plugins and would have gone stale the moment a sixth landed
- [x] Gates green again after the narrative pass: lint 0 errors, all 28 suites
- [x] Changelog entry: body + a score per tier (tier 2, score 5 -- consumers must reinstall)

### Where I left off

Branch 2 of 6, and the only one in the chain that breaks existing installs. Names, model narrative and
gates are all done.

**One action belongs AFTER the merge and is therefore not a step above** -- the step list is what
`open-pr` and `ship-pr` hold the branch to, so a step that cannot be closed before the PR would either
block it or teach someone to tick a box for work they have not done. This repo consumes itself through
the `github` marketplace source, so the moment this lands the two ids in its own `.claude/settings.json`
stop existing upstream:

```powershell
claude plugin marketplace update claude-code-specialists
claude plugin uninstall specialists@claude-code-specialists --scope project
claude plugin uninstall specialists-workflow-davekjohn@claude-code-specialists --scope project
claude plugin install team-alpha@claude-code-specialists --scope project
claude plugin install workflow-davekjohn@claude-code-specialists --scope project
```

**Carry into branch 6, the migration page:** a consumer still on the pre-seam lens path
`.claude/plugins/claude-specialists/<plugin>/` has the plugin name in that second segment, so after
reinstalling under the new name their lenses go unseen. Named rather than repaired -- no consumer in the
register is confirmed to be in that state, and a fallback built for nobody is a fallback nobody tests.

Then restart and check that Chris takes the floor -- that is the only real test of the `@`-import in
`.claude/specialists/SPECIALISTS.md`, which now points at `plugins/team-alpha/personas/`. Inbound #414
is what happens when that import breaks silently: the August 3 marketplace rename took it out for every
consumer at once.

Next: `feat/teams-and-workflows-tree` -- the move into `plugins/teams/` and `plugins/workflows/`.
Invisible to a consumer, and branch 1 was built so that it should need no script change at all.
