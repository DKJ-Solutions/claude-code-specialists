### Record why remote branch deletion stays a manual action · Docs · 2026-07-27

Follow-up to PR #199. Clearing the seven backlog branches ran into the auto-mode classifier, which
blocks `git push origin --delete`. Dave asked whether that block could simply be lifted, weighed it,
and decided against — recorded in Derek #05's lens so the next session does not redo the analysis
and propose the permission again.

**The reasoning is the part worth keeping, because the obvious answer is the wrong one.** It looks
like a permission that would save manual work. It would not, because `deleteBranchOnMerge` (switched
on in #199) already removes merged branches by itself. What is left over is precisely the inverse
set: branches that are **not** merged — a parked branch from `park-branch.ps1`, unfinished work, a
branch pushed from the other machine. Those are the ones whose deletion cannot be undone from
`main`. So the permission would carry nearly all of the risk and almost none of the benefit.

`main` itself was never the exposure, incidentally: the active `main-ci-gate` ruleset carries a
`deletion` rule, so that path is closed regardless of any permission.

Backlog cleanup is therefore handed over as a paste-ready command rather than attempted — the same
handover pattern PR #198 wrote into Sylvester #15 for permissions files, applied here to a
destructive git action.
