## `feat/the-workflow-is-its-own-plugin` progress

### Steps

- [x] Create the plugin skeleton: `plugins/specialists-workflow-davekjohn/.claude-plugin/plugin.json`
- [x] Generate its `RELEASE.md` and `CHANGELOG.md` by CALLING `Build-PluginReleaseCard` /
      `Add-PluginChangelogSection`, not by copying another plugin's file — check 17 and the
      release-card check hold both against those functions, so deriving them is what makes them right
      by construction
- [x] `git mv` the seven workflow skills (`cut-release`, `fix-mojibake`, `fold-changelog`,
      `new-branch`, `open-pr`, `park`, `ship-pr`) and `scripts/{release,task,maintenance}`
- [x] **The shared-lib question is answered, and the answer is not one of the three candidates** —
      see "Where I left off" below. Both rows of the table that parked this branch were *mention*
      read as *use*. One lib does end up shared (`check-report-lib`), for a different reason, and it
      got candidate 1 after all three readers were verified to tolerate it.
- [x] Name settled with Dave, August 8, 2026: **`specialists-workflow-davekjohn`**. The name says
      whose way of working it is, which is the whole point of the pack being opt-in.
- [x] Split `hooks/`: `script-contract-sessioncheck` + `connector-sessioncheck` to the workflow pack,
      `roster-sessioncheck` stays in the core; `hooks.json` in both. `check-script-contract.ps1`
      travels with its hook — it demands `branch-info.ps1`/`repo-config.ps1` from a repo whose scripts
      ship in this pack.
- [x] Rewrite the mirror paths in `Get-SharedScriptPairs` (`scripts/lib/shared-scripts-lib.ps1`) —
      the one registry the generator, the lint and the test all read
- [x] **Not in the original list, and it blocked nine entry points:** the lint's check 18 and
      `shared-scripts.tests.ps1` both looked for a script's documenting skill at a hardcoded
      `plugins\specialists\skills\...`. The registry now DERIVES the page path from the mirror
      (`SkillRel` + `Plugin`), so a script that moves takes its page lookup with it.
- [x] Add the plugin to `.claude-plugin/marketplace.json`
- [x] `.claude/settings.json` here + `connectors/claude-code-specialists.json` — this repo consumes
      itself, so it enables the new plugin
- [x] `specialists-init`: stop scaffolding `repo-config.ps1` + `branch-info.ps1` unconditionally.
      Done as a SPLIT rather than a removal, because the measurement said so: `Get-RosterPath` and
      `Get-RosterIgnoredIds` are read by `check-roster-sync`, which stays in the core. So the roster
      half is always written and the workflow half joins it only when the pack is enabled;
      `branch-info.ps1` is entirely the pack's and is not placed without it. Assembled from parts, so
      the roster functions exist in one here-string rather than two.
- [x] `specialists-teardown`: the split created a scaffold with NOTHING to fill in, so the
      placeholder test read a core-only `repo-config.ps1` as authored and would have kept it forever
      — adoption exactly as irreversible as that skill promises it is not. `Test-LooksGenerated`
      gained a second recognised shape, keyed on "still exactly what the bootstrap wrote".
- [ ] Tests: five suites go red on the move — `bootstrap-drift`, `script-contract`, `connectors`,
      `teardown`, `check-plugin-integrity`. Four are path updates and are done; **`bootstrap-drift`
      is the real one and is NOT done** — see below.
- [ ] Docs: `README.md` (the four-plugins table becomes five, the repo layout, "what lives here"),
      `plugins/INSTALL.md`, `plugins/UNINSTALL.md`, `CLAUDE.md`, and the lenses of Derek #05,
      Rendall #06 and Sylvester #15. The dead links the lint caught are already repaired; this is the
      prose that has to say there are five plugins and what the fifth is for.
- [ ] Fill in the changelog entry

### Where I left off

**The design question that parked this branch was a misreading, and the correction is worth keeping.**
The table said `check-report-lib` and `native-capture-lib` each had readers in both halves. Measured:

- `open-pr.ps1` and `fold-changelog-entry.ps1` name `check-report-lib` only in a COMMENT ("Like
  check-report-lib.ps1 this lib is not repo-owned…"). Neither dot-sources it.
- `check-report-lib.ps1` names `native-capture-lib` on line 294 to say it **needs none of** its EAP
  dance. It does not dot-source it either.

Both rows were *mention* read as *use* — the defect class already recorded four times in
[Sylvester #15](../.claude/specialists/lenses/05-15-extension.md). `native-capture-lib` has no core
reader at all and moved to the pack whole.

**One lib IS shared, for a reason the note never identified.** Moving `check-script-contract.ps1` to
the pack (it demands config for scripts a core-only consumer does not have) leaves
`check-roster-sync` in the core and `check-script-contract` in the pack, both dot-sourcing
`check-report-lib`. That got **candidate 1** — a second registry entry, same source, second mirror —
after the three readers were actually read rather than assumed:

| reader | tolerates a second entry? |
|---|---|
| `build-shared-scripts.ps1` | yes — loops per pair, copies Source → Mirror, keys on nothing |
| lint check 8 | yes — same per-pair shape |
| lint check 18 | yes — `if ($pair.LibOnly) { continue }` skips libs entirely |
| `shared-scripts.tests.ps1` | **only with a unique `Name`** — 11 lookups use `Where-Object { $_.Name -eq … }` and would get an array back |

Hence `check-report-lib-workflow` as the second entry's name. A new assert in that suite now refuses
any mirror that dot-sources a lib living in the other plugin — the assertion that would have caught
the original misreading.

**State: the lint gate is GREEN (0 errors), `shared-scripts.tests.ps1` is green at 228 asserts.**

**The one real test job left is `bootstrap-drift.tests.ps1`**, and it is not a path update. Its main
fixture has no `settings.json`, so it now correctly receives the core-only scaffold — which means the
suite has to be rebuilt around BOTH cases rather than retargeted:

- the existing 1c asserts (`branch-info.ps1` placed, `Get-RepoName`, `Get-ChangelogHeading`,
  `Get-LiveStage`) belong to a NEW fixture that enables `specialists-workflow-davekjohn`;
- the main fixture gets the mirror-image asserts: `repo-config.ps1` placed with the roster pair,
  `branch-info.ps1` absent, no workflow function present, and the `[notice]` line saying why;
- section 1d (`Test-DerivedRepoName`) runs bootstrap in throwaway git repos with no settings, so
  those fixtures need the pack enabled too — RepoName lives in the workflow half now, and without it
  there is nothing to derive into.

Add one assert the suite never had: an untouched core-only `repo-config.ps1` is recognised by
`Test-LooksGenerated -Kind 'repo-config'`, and one with an ignored id added to it is not.

**Also worth knowing before resuming:** this branch's PR is deliberately opened but **not merged**.
`marketplace.json` on `main` is what a consumer's marketplace reads — no release or tag involved — so
adding a fifth plugin is outward-facing under the safety rules and waits for Dave's word.

**Corrected August 8, 2026:** the sentence above described a PR that did not exist —
`gh pr list --state all --head feat/the-workflow-is-its-own-plugin` was empty. Nothing was waiting;
the PR still has to be opened. What stands is the second half: it opens, it does not merge.
