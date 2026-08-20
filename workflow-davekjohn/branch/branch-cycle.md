# `docs/v4-16-0-timing-total` cycle · 20260820-135606

## PLAN

- [x] Recover every remaining leg from commit, PR and Release timestamps rather than estimating

## CREATE

- [x] Add the total and the four legs the first pass could not see
- [x] Decide how to treat the 58m 53s requester gap — excluded from the total, named beside it, wall
      clock given once
- [x] Add the head percentage as a fifth reading, and the v4.15.0 comparison that carries the
      fixed-cost-per-event claim

## TEST

- [x] Check the arithmetic closes: 7m 36s frozen + 17m 53s tail = 25m 29s, and +58m 53s = 1h 24m 22s
- [x] Lint + test gates via `open-pr.ps1`

## DEPLOY

See `branch-deployment.md` — that is the part that travels to `main`.

## Where I left off

Both readings added to the merged release note. Ready for the PR.
