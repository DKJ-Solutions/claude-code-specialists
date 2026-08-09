## `feat/workflow-default` progress

### Steps

- [x] `plugins/workflows/workflow-default/` with its manifest, registered in the marketplace
- [x] `discover-workflow.ps1`: eight questions, each answered with its evidence or with `SILENT`
- [x] Writes into the seam, so the teardown removes it without knowing it exists (Dave)
- [x] Never overwrites -- a second run reports the diff and leaves the file alone (Dave)
- [x] `check-report-lib.ps1` mirrored into this plugin for `Get-SeamPaths` alone. A third mirror of one
      lib, and the cost is named in the registry rather than hidden: the alternative was a literal seam
      path, which would be a third statement of where the bootstrap writes and the teardown deletes
- [x] The doctrine README and the skill page (Tessa)
- [x] `README.md` table and `INSTALL.md` default settings block: `team-alpha` + `workflow-default`
- [x] Both marked skill enumerations in the README -- caught by check 10, which is exactly what that
      marker is for: a prose list claiming to be complete goes stale silently otherwise.
      (Written without quoting the marker itself: check 10 masks fenced code but deliberately not
      inline backticks, because a real span's own names are backtick-delimited. So a passing mention
      of it in prose reads as an unterminated live span -- which is how this very line first broke the
      gate.)
- [x] `scripts/tests/discover-workflow.tests.ps1`, 37 asserts over six scenarios (Tycho), with the
      bare-repo `SILENT` case and the branch-names-only regression as the two that matter most
- [x] Two failures of my own, both caught by the gate rather than by reading: a top-level `2>$null` on
      a git call, which this repo forbids repo-wide because in PowerShell 5.1 it turns a successful
      native command into a terminating error; and the lint fixture's plugin list falling behind the
      registry, which throws loudly and took a dozen unrelated scenarios with it
- [x] Gates green: lint 0 errors, all 29 suites
- [x] Changelog entry: body + a score per tier

### Where I left off

Branch 4 of 6. `workflow-default` exists and is the plugin a fresh consumer now enables by default.

**Deliberately not built, and named instead:** the never-overwrite diff check compares each answer
against the whole document rather than against its own section, so two sections carrying the same
sentence could hide a change. Found by Tycho while writing the suite; no fixture produces it without
contrivance, the output is advisory rather than a gate, and this repo does not build repairs for
defects nobody has met. It is written down in the script so the next reader knows it was weighed.

Next: `feat/one-workflow-at-a-time` -- the check that exactly one workflow is enabled, living in
`team-alpha` because that is the only plugin always present. Then
`docs/migrating-to-teams-and-workflows`, which also owes the pre-seam lens path carried over from
branch 2.
