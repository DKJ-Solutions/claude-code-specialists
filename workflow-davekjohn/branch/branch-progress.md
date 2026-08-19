## `docs/root-plugin-neutral` progress

### Steps

#### PLAN

- [x] Set one test for the root sweep: does the sentence become false with the plugin uninstalled?
      Product facts (what this repo builds) stay; claims that the repo is *staffed* by specialists go.
- [x] Verify each of the three loose ends still stands before repairing any of them.

#### CREATE

- [x] Root `CLAUDE.md`: new opening stating the file holds on its own and naming the two layers; the
      specialist-as-actor prose reworded; four link labels renamed to their destination; the two
      duplicate orchestrator paragraphs above the `@`-import deleted, leaving the seam as one line.
- [x] Repair the two stale lens citations — release lens to its own tier-model section, performance
      lens to the release lens.
- [x] `scripts/task/adopt-workflow-folder.ps1`: the scaffolded folder page now states it is the layer
      on top of the consumer's root `CLAUDE.md`; mirror regenerated with `build-shared-scripts.ps1`.
- [~] Document the entry's root-relative link rule — dropped: it is already documented. Rule 2 of
      `BRANCH-portable.md` states it and `branch/README.md` opens by saying to read that first. The
      earlier report was mine and it was wrong; the grep behind it looked for "resolve from the root"
      while the text says "written root-relative".
- [x] Instead, repair the real gap that trap exposed: the lint's dead-link finding now names the
      resolution base and why, where that base is not the file's own directory.

#### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] All 43 test suites: pass in 164s.
- [x] `check-script-contract.ps1` and `check-roster-sync.ps1`: 0 errors, only the pre-existing INFO
      signals (four optional seam functions, one plugin shipping no agents directory).

### Where I left off

Nothing open. One thing a later reader should not re-litigate: the root's remaining mentions of
specialists, agent defs, teams and `.claude/specialists/` paths were **measured and deliberately
kept**. They describe the product this repo builds and files that survive an uninstall, so they pass
the same test the reworded lines failed. A sweep that removes them on sight would be repairing to the
word rather than to the rule.
