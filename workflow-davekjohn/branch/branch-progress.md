## `docs/the-always-on-budget-remeasured` progress

### Steps

#### PLAN

- [x] Read what this repo had already decided before importing anything from the page -- the July 28
      measurement and its verdict were already in Nolan's lens
- [x] Establish the one practice that is genuinely diverged from, rather than adopting eight

#### CREATE

- [x] Re-measure the always-on path against the July 28 baseline, including the seam document that did
      not exist then
- [x] Record it in Nolan's lens, in the past tense with its date, beside the measurement it supersedes
- [x] Write the practice map: eight practices held against the tree
- [~] Move the release/changelog machinery behind a `paths:` rule -- dropped: a scoped rule is gone
      after a `/compact`, which for release rules means gone during a release. That is a trade on
      Dave's governance document, not a tidying job.

#### TEST

- [x] Lint gate green
- [x] All 36 test suites green

### Where I left off

#657 done. #669 and #655 are closed; #660 stays open with its two blockers named -- the missing
`read:project` scope and the fact that `pair-cli` is not visible under either owner. Both need Dave.
