# `fix/sync-reference-point-no-merges` cycle · 20260821-122049

## PLAN

- [x] Verify inbound #801 against the tree before scoping: the subject exists, the symptom stands
      (no `--no-merges` in the lookup), the reason holds, and `--no-merges` is a real flag whose
      direction is the protective one
- [x] Measure which of the report's four items are actually defects here: §1 yes, §3.2 yes (a note in
      the wrong place), §3.1 not applicable (no redirect or `cat-file` anywhere in these scripts),
      §2 a redesign rather than a repair -- to Dave as a proposal, not built here

## CREATE

- [x] `--no-merges` in `Get-SyncReferencePoint`, with the measured reason in its docstring
- [x] Note the merge case in `Get-SyncDefaultReferencePattern` too, since that is where a reader goes
      to narrow the pattern and the seam cannot solve it
- [x] Move the inline-`--` pitfall note to `Invoke-SyncGitQuiet` itself
- [x] Rebuild the team-shopify mirror (`build-shared-scripts.ps1`)

## TEST

- [x] A merged-sync-branch fixture: a real `--no-ff` merge whose body carries the sync subject
- [x] Assert the shipped lookup finds the sync commit, not the merge
- [x] Assert the *unrepaired* lookup does pick the merge, so the flag cannot be tidied away
- [x] Suite green: 19/19

## DEPLOY

See `branch-deployment.md`.

## Where I left off

Done and ready to ship. One thing that does **not** travel with this branch: the report's section 2
(replace the time window with a content-history rule, pull live into a mirror outside the repo, never
delete). That is a decision for Dave about the sync policy, recorded in the deployment entry so it is
not lost, and unaffected by this repair either way.
