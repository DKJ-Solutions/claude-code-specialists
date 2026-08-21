# `feat/branch-files-say-reread-me` cycle · 20260821-191445

## PLAN

- [x] Verify inbound #817: both write events are where the report says (`new-branch.ps1` creates the pair,
      `fold-changelog-entry.ps1` resets the entry and the step list), and `open-pr.ps1` is not a third --
      its two `WriteAllText` calls write the PR body to a temp file.
- [x] Take the report's own framing: the refusal is the harness's guard and is not repaired here. Options 1
      and 2 both, since they reach different readers; option 3 (do nothing) declined for the reason the
      report gives -- it recurs on every branch in every consumer.

## CREATE

- [x] `Get-BranchFilesRereadNote` in `scripts/lib/entry-scaffold-lib.ps1` -- one source, because two
      scripts print it.
- [x] `scripts/task/new-branch.ps1` prints it after the pair is written, and only then: a run that KEPT
      both files changed nothing a session was tracking.
- [x] `scripts/release/fold-changelog-entry.ps1` prints it after the reset, gated on the branch entry
      having actually been folded rather than on a legacy root entry.
- [x] `BRANCH-portable.md`: the portable statement, for the session that did not run the script.
- [x] `workflow-davekjohn/CLAUDE.md`: the local pointer at it.
- [x] Mirror all three scripts to `plugins/workflows/workflow-davekjohn/scripts/`, byte-identical.

## TEST

- [x] `new-branch.tests.ps1`: the note prints on the run that writes the pair, and does not on the
      idempotent rerun. 114 asserts, all pass.
- [x] `fold-changelog.tests.ps1`: it prints on the fold that resets the pair, and not on a run with
      nothing to fold. 134 asserts, all pass.
- [x] Lint gate + all suites via `open-pr.ps1`.

## DEPLOY

## Where I left off
