## `feat/agent-shared-under-teams` progress

### Steps

#### PLAN

- [x] Measure the folder's real reach before moving it: which files carry a `BEGIN shared:` block, and in
      which plugins. Result: 30 files, all four teams, zero in either workflow.
- [x] Establish that no gate reads the tree by shape rather than by marketplace — `[plugin-kind]`,
      `Get-TouchedPlugins`, the link scan, the shared-script mirror check.
- [x] Establish what the move changes in `publish-to-business.ps1`'s kind-directory pruning.

#### CREATE

- [x] `git mv plugins/agent-shared plugins/teams/agent-shared`.
- [x] Repoint the one real path constant, `Get-AgentSharedDir` in `scripts/lib/agent-shared-lib.ps1`,
      plus the lint's link-scan spec.
- [x] Update the docstrings and comments that state the layout: `agent-shared-lib.ps1`,
      `build-agent-defs.ps1`, `check-plugin-integrity.ps1`, `check-connectors.ps1`,
      `publish-to-business.ps1`, and `plugin-tree-lib.ps1` (+ its mirror via
      `build-shared-scripts.ps1`).
- [x] Repoint the six markdown links and the prose that states the placement: root `README.md`,
      `plugins/README.md`, `plugins/teams/README.md`, `plugins/teams/agent-shared/README.md` (its own
      relative links go one level deeper), `workflow-default`'s README + SKILL + script, `scripts/README.md`,
      `06-24-agent.md`, `CLAUDE.md`, and the two lenses carrying a path (`05-15`, `06-24`).
- [~] Update `releases/**` and `workflow-davekjohn/releases/README.md` — dropped: those mention the old
      path in prose only, never as a link, and they are published history that the record rule leaves alone.

#### TEST

- [x] `build-shared-scripts.ps1` — mirror rebuilt (1 updated).
- [x] `build-agent-defs.ps1 -Check` — all 30 shared blocks in sync from the new location.
- [x] `check-plugin-integrity.ps1` — 0 errors, link-scan over 273 files.
- [x] Widen the two `Get-TouchedPlugins` asserts instead of repathing them, so the nested case covers a
      non-plugin **inside** a grouping directory; repoint the `agent-shared.tests.ps1` and
      `check-plugin-integrity-links.tests.ps1` fixture paths.
- [x] All suites in `scripts/tests/` green.

### Where I left off

Work is complete and both gates are green locally. Remaining after the merge: nothing beyond the ordinary
PR → CI → merge → fold.

**One observation deliberately not repaired on this branch.** The root README's enumeration of the shared
blocks had drifted to twelve names against a directory of fourteen, and nothing checks it. The two missing
names were added here because the sentence was being repathed anyway, and the sentence now states that the
directory is the authority. Building the gate that would keep it honest is a separate, scoped job — the
`<!-- skills:all -->` span mechanism already in `check-plugin-integrity.ps1` is the obvious model for it.
