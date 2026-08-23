# `feat/worktree-lane` cycle · 20260823-093414

## PLAN

- [x] Measure the actual cost: split the CI runs by event, price the blocking leg per week, and check
      whether PR granularity is the cheaper lever before proposing machinery
- [x] Probe the two obvious designs against git instead of reasoning about them, and record which one
      the working tree actually refuses

## CREATE

- [x] `scripts/task/worktree-lane.ps1` -- open a lane (`-Name`) and hand one back (`-HandBack`)
- [x] `new-branch.ps1` gains `-RepoRoot`, on the #101 precedent, so a lane's branch and both dossier
      files land in the lane
- [x] Register `worktree-lane` in the shared-scripts registry and mirror both scripts into the plugin
      byte-identical
- [x] Skill page `skills/worktree-lane/SKILL.md`, and `-RepoRoot` documented in the `new-branch` skill
      (the lint gate's parameter check reads it)

## TEST

- [x] `scripts/tests/worktree-lane.tests.ps1` -- 35 asserts: open, rollback on a refused name, occupied
      path, both hand-back refusals, the happy hand-back from inside the lane, the two target refusals,
      and a structural assert that only the rollback removal is forced
- [x] Smoke-run both ends on the real repo, not only in the fixture
- [x] Lint gate green (`check-plugin-integrity.ps1`)
- [x] All suites green -- `shared-scripts.tests.ps1` failed first and was right to: the dual-context
      invariant caught a cwd dependency, now anchored

## DEPLOY

- [x] Entry written with both tier scores
- [x] Derek's lens: the lane rule beside the existing parallel-merge rule
- [x] Nolan's lens: CI median re-measured (7m 23s -> 8m 01s), the weekly bill, and what the number does
      not show
- [x] Ready to ship: `ship-pr.ps1` (PR -> CI -> merge -> fold)

## Where I left off

Everything is built, tested and documented; the branch is ready to ship. The one thing deliberately NOT
done is the one-line change to `ship-pr.ps1` (fold via whichever worktree holds main): measured as saving
two commands per lane and nothing in wall-clock, against touching the line that produces the state nothing
reports. Declined on that trade -- if it ever comes back, that is the reasoning to argue with.
