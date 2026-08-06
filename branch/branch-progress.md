# Branch progress

**Branch:** `feat/branch-folder`

## Steps

- [x] Own the format in one place -- `entry-scaffold-lib.ps1`: the two paths, the reset templates, the
      per-branch scaffold, `Get-BranchFileDeclaredBranch` and `Test-BranchChangelogIsFilled`
- [x] `new-changelog-entry.ps1` writes both files, idempotent per file
- [x] Stop scaffolding the to-do heading into the entry; keep refusing it via a legacy marker
- [x] `fold-changelog-entry.ps1`: discover both forms, reset the pair instead of deleting, read the
      branch back off the step list, name both in the commit
- [x] `open-pr.ps1`: prefer the new path, fall back to the root; tick the checklist on the file
      *holding* an entry
- [x] `cut-release.ps1`: refuse a cut while the entry is unfolded
- [x] `new-branch.ps1 -Park`: commit both files
- [x] Follow the entry to its new path in the lint gate (entry-heading, link-scan, lifecycle) and in
      `Get-MojibakePaths`
- [x] Tests: entry-scaffold, fold-changelog (4 new cases), new-branch, shared-scripts, script-contract,
      repo-config
- [x] Docs: `CONTRIBUTING.md`, `CLAUDE.md`, the PR template, Derek #05, Rendall #06, and the
      new-branch / fold-changelog / park / ship-pr skills
- [x] Mirror to the plugin, lint green, all 26 suites green

## Where I left off

Complete and green. One decision deliberately **not** taken, because it is Dave's and he has not
answered it: whether `open-pr` should **refuse** a branch whose step list still has unticked items.
The list is a checkbox list so that gate can be added without reshaping anything, but nothing gates on
it today -- a step list is a convention at this point, not a workflow. Two sub-questions ride along with
it: whether a branch with *no* step list at all is refused, and what marks an item that turned out not
to be needed (without that, a gate teaches people to tick boxes for work they did not do, which is worse
than no gate because it reports success).
