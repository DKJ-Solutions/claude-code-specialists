# Branch progress

**Branch:** `feat/step-list-gate`

## Steps

- [x] Own the three marks and the matcher in `entry-scaffold-lib.ps1` -- `Get-BranchProgressMarks`,
      `Get-BranchProgressFindings`, fence-aware like every other reader of this format
- [x] Scaffold writes its open step through the shared mark instead of a literal
- [x] `open-pr.ps1`: refuse the push while a step is unresolved, not `-Force`-able
- [x] `ship-pr.ps1`: refuse the merge for the same reason, re-read rather than trusted from step 1
- [x] `branch/README.md` -- the folder explains itself: the two files, the fixed names, the reset
      state, link resolution per file, and the six rules
- [~] A seam so a consumer can rename the three marks -- dropped: they are the format four readers
      agree on, like `CHANGELOG.md`'s own name, and `- [x]` is standard markdown rather than prose.
      The *wording* inside the files is already seamable, which is the part a repo genuinely owns.
- [x] Tests: eleven asserts on the matcher, including the ticked-stub case and the fence
- [x] Docs: `CLAUDE.md` (fourth gate), `CONTRIBUTING.md`, and the `open-pr` / `ship-pr` / `new-branch`
      skills
- [x] Mirror, lint, all suites
- [x] Take `main` in and re-run the gates on the merged tree
- [x] PR

## Where I left off

Done -- and this branch is the gate's own first subject: the list above had to be resolved before
`open-pr` would push it, `- [~]` included.
