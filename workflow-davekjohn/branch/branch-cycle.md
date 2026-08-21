# `fix/test-capture-keeps-the-message-whole` cycle · 20260821-212449

## PLAN

- [x] Reproduce the failure and establish that it is deterministic here: `prune-merged.tests.ps1` red
      4 runs out of 4, while `gh run list` shows CI green on the same two commits.
- [x] Verify the REASON before repairing it. The first inference — a wrap at a space, joined into
      `branch'main'` — was **wrong**; dumping the raw capture showed a whole block of PowerShell
      decoration (`At <file>:<line> char:<n>`, `+ CategoryInfo`, `+ FullyQualifiedErrorId`) sitting
      between `no local branch` and `'main'`.
- [x] Establish that `prune-merged.ps1` itself is correct: its refusal message names the branch and the
      seam, on one line, at `scripts/task/prune-merged.ps1:133`.
- [x] Confirm the mechanism in isolation before touching the suite: `Out-String` formats each
      `NativeCommandError`, an explicit `[string]` cast returns the raw stderr line.

## CREATE

- [x] `Get-FlatOutput` reads each captured record as text and joins with nothing between, instead of
      rendering the collection with `Out-String`.
- [x] Rewrite the helper's comment around the mechanism rather than the symptom, so the next reader
      does not repeat the wrong inference.

## TEST

- [x] The suite goes green, 28 pass / 0 fail, three consecutive runs.
- [x] No new assert added: the existing one now measures what it always claimed to.
- [~] Repair the five sibling suites carrying the same `Out-String` root cause — **dropped
      deliberately.** `park-branch`, `session-status`, `new-branch`, `find-specialist-mentions` and
      `shared-scripts` are green; per Dave's standing rule a risk that has not bitten is named, not
      pre-emptively repaired. Named in the entry, with the measurement that they have diverged on the
      normalisation (`''`, `' '`, `-replace '\s',''`) and agree on the cause.

## DEPLOY

## Where I left off

Done. This branch exists because the release cut Dave asked for could not run: the local test gate is what
`cut-release.ps1` meets, and it was red on `main` over a correct script. With this merged the cut proceeds
on a green gate.
