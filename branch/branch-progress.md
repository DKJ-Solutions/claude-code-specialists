## `feat/the-workflow-is-its-own-plugin` progress

### Steps

- [x] Create the plugin skeleton: `plugins/specialists-workflow/.claude-plugin/plugin.json`
- [x] Generate its `RELEASE.md` and `CHANGELOG.md` by CALLING `Build-PluginReleaseCard` /
      `Add-PluginChangelogSection`, not by copying another plugin's file — check 17 and the
      release-card check hold both against those functions, so deriving them is what makes them right
      by construction
- [x] `git mv` the seven workflow skills (`cut-release`, `fix-mojibake`, `fold-changelog`,
      `new-branch`, `open-pr`, `park`, `ship-pr`) and `scripts/{release,task,maintenance}`
- [ ] **Decide the shared-lib question below**, then move the remaining libs
- [ ] Split `hooks/`: `script-contract-sessioncheck` + `connector-sessioncheck` to the workflow pack,
      `roster-sessioncheck` stays in the core; `hooks.json` in both
- [ ] Rewrite the mirror paths in `Get-SharedScriptPairs` (`scripts/lib/shared-scripts-lib.ps1`) —
      the one registry the generator, the lint and the test all read
- [ ] Add the plugin to `.claude-plugin/marketplace.json`
- [ ] `specialists-init`: stop scaffolding `repo-config.ps1` + `branch-info.ps1` unconditionally —
      after the split they belong to the workflow pack, and a consumer who never enables it is being
      asked to configure scripts they do not have (this was planned as its own branch and turns out to
      be inseparable from this one: shipping the split without it means one release in which adoption
      scaffolds config for absent scripts)
- [ ] Docs: `README.md` (the four-plugins table becomes five, the repo layout, "what lives here"),
      `plugins/INSTALL.md`, `plugins/UNINSTALL.md`, `CLAUDE.md`, and the lenses of Derek #05,
      Rendall #06 and Sylvester #15
- [ ] `.claude/settings.json` here + `connectors/claude-code-specialists.json` — this repo consumes
      itself, so it has to enable the new plugin or lose its own workflow
- [ ] Tests: `check-plugin-integrity.tests.ps1` and `sync-roster.tests.ps1` name the moved paths
- [ ] Fill in the changelog entry

### Where I left off

**The open design question, and the reason this branch is parked rather than pushed through.**

Two libs are dot-sourced by BOTH halves, so neither half can simply own them:

| lib | core reader | workflow reader |
|---|---|---|
| `check-report-lib.ps1` | `check-roster-sync.ps1`, the bootstrap | `open-pr.ps1`, `fold-changelog-entry.ps1` |
| `native-capture-lib.ps1` | `check-report-lib.ps1` itself | `cut-release`, `ship-pr`, `new-branch`, `park-branch`, … |

Three candidate answers, none of them tested yet:

1. **A second mirror entry per lib** — `Get-SharedScriptPairs` already maps one root source to one
   plugin mirror, and both libs would simply gain a second mirror in the workflow plugin. The drift
   lint then keeps all copies identical by construction, which is the mechanism this repo already
   trusts. The registry holds 18 sources and shows no uniqueness assertion, but *"shows no"* is not
   *"was verified to tolerate"* — the generator loop, the lint loop and `shared-scripts.tests.ps1`
   each have to be read before this is called safe.
2. **Cross-plugin dot-sourcing** — the workflow scripts reach into the core plugin's cache directory.
   Rejected on sight: the two plugins are separately versioned and separately installed, so this
   builds a runtime dependency on a path that a version mismatch silently breaks.
3. **Split the libs by reader** — carve the shared surface into a core half and a workflow half.
   Cleanest conceptually, largest diff, and it needs a reading of what each function is actually for.

The measured facts to decide on are above; the decision is not mechanical, and making it badly is
worse here than making it later, because a wrong answer only shows up as a runtime failure inside a
consumer's plugin cache.

**Also worth knowing before resuming:** this branch's PR is deliberately opened but **not merged**.
`marketplace.json` on `main` is what a consumer's marketplace reads — no release or tag involved — so
adding a fifth plugin is outward-facing under the safety rules and waits for Dave's word. Everything
else in this movement (PRs #520 and #521) merged normally, because nothing in those reaches a
consumer until a release, and a release already requires him.
