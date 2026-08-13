## `fix/cut-release-note-dir-seam` progress

### Steps

- [x] Verify the locked subject against the tree: line 896 in both copies, the empty `releases/notes/4.x/`,
      the body's own derived-path pattern twenty lines up, and the assert that is blind to the backslash
- [x] Derive the note's directory from `$noteAbs` (Sylvester #15), in the repo copy and the plugin mirror,
      held byte-identical
- [x] Delete the stray empty `releases/notes/` — expect no diff, git tracks no empty directory
- [x] Widen `$noteRootLiteralLines` to `releases[\\/]notes` (Tycho #18), verified **red** against the old
      line first: narrow saw 1 and passed, widened saw 2 with no `-Default` on the second
- [x] `cut-release-guardrail.tests.ps1` green — 53 asserts
- [x] Write the changelog entry (Rendall #06)
- [x] Review the diff (Victor #19)
- [x] `open-pr` → gates → merge → fold (Derek #05, Rendall #06)

### Where I left off

**Done and merged.** Two things belong to Dave rather than to this branch, both carried from the lock:

- The convention question raised for the **third** time — *"PR + merge + fold"* keeps being written into a
  scaffolded step list as a step, and the step-list gate runs *before* the push so it can never honestly be
  ticked. This branch hit it again and resolved it the same way: post-merge steps live in *Where I left off*.
  Worth writing into `branch/README.md` as a convention.
- The three items still waiting on Dave's word, unchanged: untracking
  `Microsoft/Windows/PowerShell/ModuleAnalysisCache`, the duplicate local gate run in `ship-pr`
  (~7 min/PR), and the two SessionStart entry points with no source-repo guard.
