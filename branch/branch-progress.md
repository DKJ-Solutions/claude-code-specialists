## `feat/one-changelog-for-the-product` progress

### Steps

- [x] Verify the premise before acting on it: does a consumer still reach the history once these files
      are gone? **Yes** — the marketplace source is a git clone of the WHOLE repo, so `CHANGELOG.md`
      and `releases/` sit in every consumer's
      `~/.claude/plugins/marketplaces/claude-code-specialists/`. Measured on this machine.
- [x] Remove the ten files: 5 × `<plugin>/CHANGELOG.md` + 5 × `<plugin>/RELEASE.md` (11,684 lines)
- [x] `release-lib.ps1`: retire `Build-PluginChangelogSection`, `Build-PluginChangelogIntro`,
      `Add-PluginChangelogSection`, `Build-PluginReleaseCard` and `Convert-EntryLinksForPluginChangelog`.
      **`Get-EntryPlugins` and `Remove-EntryPluginsLine` deliberately stay** — the `Plugins:` line has a
      second reader in the release notes and was never only for those files.
- [x] `cut-release.ps1`: drop the per-plugin loop; the lockstep version bump is untouched
- [x] `check-plugin-integrity.ps1`: retire check 9 (RELEASE.md present + version match) and check 17
      (per-plugin CHANGELOG intro vs. its generator). Both were correct checks that dissolved rather
      than weakened: with one of the two statements gone there is nothing left to compare.
- [x] Tests: `release-lib.tests.ps1` (323 asserts) and `check-plugin-integrity.tests.ps1` (165) lose
      the sections covering the retired functions and scenarios 33-37; the `release-card` coverage
      category goes with check 9. Two fixture helpers went with their scenarios rather than being left
      behind as orphans.
- [x] Docs: `README.md` (incl. the whole "Which release am I on?" answer, which pointed at
      `RELEASE.md`), `CLAUDE.md`, `CONTRIBUTING.md`, `plugins/INSTALL.md`, `releases/README.md`, the
      `cut-release` skill page, `.claude/rules/language-layers.md`, and the lenses of Rendall #06 and
      Sylvester #15.
- [x] Script comments that described the removed files: `repo-config.ps1` (the mojibake file set and
      `Get-ReleasePluginTier`), `fix-mojibake.ps1`, `check-script-contract.ps1`.
- [x] Gates: lint 0 errors, all 27 suites green in 127s.
- [x] Fill in the changelog entry

### Where I left off

Finished. The PR opens and waits: these ten files are consumer-facing, and deleting a document a
consumer may have bookmarked is outward-facing under the safety rules even though nothing breaks.

**One thing the next reader should not have to rediscover.** `Get-ReleasePluginTier` still returns
`$true` and still matters: the plugin/marketplace half of a cut is now *only* the lockstep version
bump, but that half is exactly what makes a consumer running group 1 alongside group 3 get matching
versions. Do not read "the cards are gone" as "the plugin tier is gone".
