## `fix/changelog-intro-in-the-shape-gate` progress

### Steps

- [x] Repair the four stale claims in `CHANGELOG.md`'s intro (section count, the impact table, the release
      minimum, the minor minimum)
- [x] Narrow check 20's `CHANGELOG.md` exclusion from the whole file to the entry blocks, so the head stays
      in scope
- [x] Drop the `###` marker requirement for that head only, so "three named sections" is caught
- [x] Match over whole text rather than per line — the measured drift also ran across a line break, and the
      measurement showed this changes nothing about what the tree pass reports
- [x] Add the regression tests: the intro is held, an entry is not, a reflowed claim is caught, the right
      count clears it (5 asserts, all green)
- [x] Repair the stale import comment naming `Build-PluginChangelogIntro` and check 17, both retired
      August 8
- [x] Run the lint + the suites, review the diff, open the PR

### Where I left off

