# `docs/v4-17-0-timing-total` cycle · 20260820-194812

## PLAN

- [x] Recover the three legs the first pass could not see, from clock readings and `gh` rather than from
      file timestamps.

## CREATE

- [x] Add the end-to-end total and its legs to the v4.17.0 release document's `What it is worth`.
- [x] Record the frozen-attachment point in `What was still open`, following the v4.15.0 precedent -- the
      attachment is what was published at the moment it was published and is not swapped.
- [x] Record the non-required check governing the merge wait as an open item, named rather than repaired.

## TEST

- [x] Read the required-check list from the `main` ruleset rather than assuming it: `lint-en-tests`, alone.
- [x] Read each check's duration from `gh pr checks` rather than inferring it from the wall clock.
- [x] Verify the legs sum to the end-to-end span: 5m 41s + 6m 33s + 4m 03s + 15m 22s + 40s = 32m 19s.

## DEPLOY

- [x] Ship via the ordinary branch + pull request route.

## Where I left off

Second timing pass written. This closes the v4.17.0 cut; the remaining acts -- publishing the marketplace to
the organisation, and this repo updating its own plugin install -- are separate decisions, not steps of the
release.
