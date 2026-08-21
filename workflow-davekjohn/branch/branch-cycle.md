# `fix/sync-content-provenance` cycle · 20260821-145613

## PLAN

- [x] Read the eight open issues and pick the most important. #807 §2 is the only standing item that can
      silently lose merged work; its §1 was verified as already repaired on `main` (`7ca115aa`, not yet in
      any tag) rather than taken from the report.
- [x] Verify the report's own claims against the tree before scoping: the subject exists, the reason holds,
      and the reference implementation is readable on this machine (`davekokbwj/xoxowildhearts`).

## CREATE

- [x] `scripts/lib/sync-rules.ps1`: the content rule -- `Get-GitRawBlobId`, `Get-CrStrippedBytes`,
      `Get-GitStoredBlobId`, `Test-LiveContentIsOurs`, `Get-SyncFileVerdict`, plus a header saying why the
      time half was demoted rather than repaired.
- [x] `scripts/task/sync-main.ps1`: rewritten around it -- mirror pull, two-stage comparison, verdict per
      path, conflict refusal, never deletes, branch name before the pull. `-DryRun`/`-MirrorPath`/
      `-KeepMirror` in, `-SkipPull` retired but accepted so the refusal can name its replacement.
- [x] Verify the two git mechanisms the reference implementation depends on instead of porting them on
      trust. `git check-ignore --stdin <paths>` is broken (exit 128, swallowed); `git ls-tree --format`
      needs git 2.36. Both replaced with forms measured against git 2.54.
- [x] `plugins/teams/team-shopify/skills/sync-main/SKILL.md`: the rule, the three structural guarantees,
      the new parameter table, the conflict refusal, and why the theme-directory set is not a seam.
- [x] Registry and test-header comments that still said "the two queries".

## TEST

- [x] `scripts/tests/sync-rules.tests.ps1`: 46 asserts. The blob id against `git hash-object --no-filters`,
      the CR-stripping traps against git's real empty-blob id, provenance including the deleted-path `--`
      case, and every cell of the verdict table.
- [x] `scripts/tests/sync-main.tests.ps1`: 32 asserts, driven through the script against a mirror. The
      `ours/buried` case is the headline; the gitignore filter is what proves the argument form is in use.
- [x] One assert failed and was wrong rather than the code: the CRLF case appended CRLF to a file stored
      without a trailing newline, so it CR-stripped to content the repo has never held. Repaired with a
      two-line fixture, and the reason is written into the test so a later reader does not "fix" it by
      loosening the rule.
- [x] A correctness risk found while writing the comparison rather than reported: git quotes any path with
      a byte above 0x7F, which would have made an accented theme filename read as live-only and taken.
      `core.quotePath=false` on both path queries, pinned by an assert that was verified to FAIL with the
      flag removed.
- [x] `build-shared-scripts.ps1`, then the lint gate: 0 errors over 22 checks.

## DEPLOY

- [x] `build-shared-scripts.ps1` run: both `team-shopify` mirrors are LF-identical to their root source,
      so a consumer runs exactly what the suites here measured. The gates themselves are the gate's job
      rather than a step -- and the PR, the merge and the fold happen after the push, so neither mark fits
      them.

## Where I left off

The seven other open issues were read and left standing, deliberately, with two things worth carrying into
the next session:

- **#807 §1 is repaired but undelivered.** `7ca115aa` sits on `main` and `v4.17.0` was cut before it, so
  both Shopify consumers are still running the unrepaired floor. Delivering it needs a release, which is
  Dave's word.
- **#809, #811, #813 and #816 are one decision, not four.** They all concern the release-notes page, and
  #816 says so itself: dropping the type chip from the row (#811) and `**Type:**` from the note (#816)
  independently leaves the newest release with no type anywhere, because `live` currently displaces the
  chip. Worth scoping as one pass.
