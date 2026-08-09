## `feat/teams-and-workflows-tree` progress

### Steps

- [x] `plugins/teams/` and `plugins/workflows/` created, the five plugins moved in with `git mv`
- [x] `.claude-plugin/marketplace.json`: five `source` values, one directory level deeper
- [x] `plugins/agent-shared/` deliberately left beside them, not inside `teams/`: it is build source
      for the team plugins, not a publishable plugin, and those two directories hold only plugins.
      Same reasoning that keeps `connectors/` at the repo root
- [x] `plugins/INSTALL.md` and `UNINSTALL.md` deliberately left directly under `plugins/`: they explain
      the whole family rather than one group, and the lint's link scan globs `plugins/*.md`
      non-recursively, so they stay covered where they are
- [x] Markdown link paths across 27 files
- [x] The two link classes the extra level creates, which a name-only sweep does not catch: links from
      `plugins/INSTALL.md` into a plugin (relative to `plugins/`, so one segment deeper now) and links
      from INSIDE a moved plugin back out to the root (one more `../`)
- [x] Fixture paths in nine test suites
- [x] `scripts/sync/build-config-blueprint.ps1` -- the one production script that needed touching, and
      it needed it because its `-OutputPath` default was a hardcoded literal. Derived from the
      marketplace now, and it refuses rather than guessing if no plugin carries a `blueprint/`
- [x] The flat fixture in `release-lib.tests.ps1` put BACK to flat: the sweep had given it nested paths
      while its own marketplace stayed flat, so it tested nothing. It is deliberately not this repo's
      shape -- the nested case is a separate fixture, and having both is the coverage
- [x] Gates green: lint 0 errors, all 28 suites
- [x] Changelog entry: body + a score per tier

### Where I left off

Branch 3 of 6. The structural work of the restructure is complete: the tree now says what the doctrine
says, and a plugin's name says which half it belongs to.

**The measurement worth keeping from this branch:** the move produced 45 lint findings and every single
one was a dead link in a document. Not one production script broke. The only script edited was the
blueprint generator, and only to remove the last hardcoded plugin path in the repo -- which is exactly
what branch 1 was built to make true, stated as a number rather than as a hope.

Next: `feat/workflow-default` -- the sixth plugin, for a repo that has chosen no workflow. Then
`feat/one-workflow-at-a-time` (the exclusivity check, in the core team) and
`docs/migrating-to-teams-and-workflows`. The pre-seam lens path carried over from branch 2 belongs on
that last one.
