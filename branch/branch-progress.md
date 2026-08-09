## `feat/plugin-tree-is-name-agnostic` progress

### Steps

- [x] One shared resolver that answers "which plugins exist and where do they live", read from
      `.claude-plugin/marketplace.json` -- name, root, manifest path. Landed as its own
      dependency-free lib, `scripts/lib/plugin-tree-lib.ps1`, rather than inside `release-lib.ps1`:
      two callers run at SessionStart and release-lib pulls in 3,000 lines behind it
- [x] `scripts/lib/shared-scripts-lib.ps1`: 21 full `Mirror` literals replaced by a `Plugin` field.
      Measured first -- every mirror was exactly `plugins\<plugin>\<Source>` -- so `Mirror` is fully
      derived and the file no longer states the layout at all
- [x] `scripts/lib/release-lib.ps1`: `Get-PluginManifestPaths` is a wrapper over `Get-PluginRoots`;
      `Get-TouchedPlugins` moved down into plugin-tree-lib with a MOVED-NOT-DELETED note left behind
- [x] `scripts/release/cut-release.ps1`: the plugin name comes from the manifest's own `name`, killing
      two identical three-`Split-Path` derivations. The lockstep map is keyed on the name now, so a
      disagreement reads as `team-alpha: 3.9.0` instead of an absolute path
- [x] `scripts/sync/check-connectors.ps1`: `Get-PluginDir` resolves through the marketplace. The slug
      check stays in front of it as defence in depth -- the name comes out of a register file
- [x] `scripts/lint/check-plugin-integrity.ps1`: the canonical-skillset scan anchors on each published
      plugin root, making true a claim its comment had been making without enforcing
- [x] `scripts/lint/check-consumer-drift.ps1`: both `$SourceDirs` and `$personaDirs` derived
- [x] `README.md`: checklist item 4 of *Adding a new plugin group* retired, with the reason recorded;
      `plugin-tree-lib.ps1` added to the repo-layout bullet and to Sylvester's script inventory
- [x] `scripts/release/fold-changelog-entry.ps1`: the stale "release-lib is NOT mirrored" comment and
      the `$repoRoot` lookup it justified, both found while working here and both repaired
- [x] Tests updated where they pinned the flat shape: `release-lib.tests.ps1` (roots passed in),
      `shared-scripts.tests.ps1` (skill page asserted against the resolved root, not a composed
      literal), plus the three fixtures that owed a newly-required sibling
- [x] A nested-plugin-tree test: `release-lib.tests.ps1` runs the detection against
      `plugins/teams/team-alpha` and `plugins/workflows/workflow-davekjohn`, so branch 3 is proven
      before it exists
- [x] The lint fixture declares its plugins. It had no `marketplace.json`, so under the new definition
      it published nothing and check 10's canonical set came out empty -- the fixture is now more like
      the repo it stands in for, not less
- [x] Verified by hand that `bootstrap.ps1:285-290` reads the consumer's plugin **cache**, not this
      tree, and correctly stays as it is
- [x] Gates green: lint 0 errors, all 28 suites, `build-agent-defs -Check`, `check-roster-sync`,
      `check-script-contract`. `check-connectors` reports the same pre-existing errors it reported at
      session start (stale machine records, life-hub not on this machine) -- unrelated to this branch
- [x] Changelog entry filled in: body + a score per tier

### Where I left off

Branch 1 of 6 is complete and green. The restructure it prepares, in order:

1. `feat/plugin-tree-is-name-agnostic` -- this one: the scripts stop encoding the layout.
2. `feat/teams-and-workflows-rename` -- the five plugins renamed, still flat under `plugins/`.
   **The only branch in the chain that breaks existing installs.**
3. `feat/teams-and-workflows-tree` -- moved into `plugins/teams/` and `plugins/workflows/`.
   Invisible to a consumer: plugin names do not change, only the repo-internal `source`.
4. `feat/workflow-default` -- the sixth plugin, for a repo that has chosen no workflow.
5. `feat/one-workflow-at-a-time` -- exactly one workflow may be enabled; the check lives in the core.
6. `docs/migrating-to-teams-and-workflows` -- how an existing consumer gets from here to there.

Next: branch 2.
