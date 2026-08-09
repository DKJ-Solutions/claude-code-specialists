## `feat/one-workflow-at-a-time` progress

### Steps

- [x] `workflow-sessioncheck.ps1` in the core team, registered beside `roster-sessioncheck`
- [x] Zero and one workflow are silent; two or more is an `[ERROR]` naming each id AND the settings
      layer that enabled it. Never blocks -- always exit 0, like the three checks before it
- [x] The ids go through `Format-SafeToken`: they are `enabledPlugins` KEY NAMES from a settings file,
      so arbitrary strings, and this line is forwarded into the session context (inbound #309)
- [x] Lint check 23, `[plugin-kind]`: `team-*` under `plugins/teams/`, `workflow-*` under
      `plugins/workflows/`, and a name with neither prefix refused -- because the hook counts workflows
      BY that prefix, so an unprefixed one would be invisible to it
- [x] Proven by hand before the tests existed: two workflows from two different layers, each reported
      with its own layer, exit 0
- [x] Documentation (Tessa): the README's teams/workflows section, its `Adding a new team` checklist,
      the hook enumeration in two places, `INSTALL.md`'s switching passage, and Sylvester's lens.
      She found a fifth place the count was stated -- leaving it would have put the inconsistency back
      one section down
- [x] Changelog entry: body + a score per tier
- [x] `scripts/tests/workflow-exclusivity.tests.ps1` (Tycho): 23 asserts over nine scenarios, both
      halves, with the two-layers case carrying the most weight. He found no bug in either the hook or
      the check -- but he DID walk into the registry throw while building his fixture and looked for
      the plugin list with a grep that missed the two-space entries, so that error now names the whole
      set it needs and the set the marketplace actually declares
- [x] Gates green: lint 0 errors, all 30 suites

### Where I left off

Branch 5 of 6, complete and green.

Next and last: `docs/migrating-to-teams-and-workflows`. What it owes, gathered as this chain went:

1. The id table per consumer -- uninstall old, install new, marketplace refresh first.
2. **The workflow choice they did not have before.** All three registered consumers ran no workflow at
   all; after this they should enable one, and if nobody says so they will install the teams and take
   half the product.
3. The pre-seam lens path carried from branch 2: the plugin name is the second segment of
   `.claude/plugins/claude-specialists/<plugin>/`, so a consumer still on that layout stops seeing
   their lenses after reinstalling under the new name. Named, not repaired -- no consumer in the
   register is confirmed to be in that state.
4. Why the register keeps a consumer on their OLD ids until they actually migrate.
