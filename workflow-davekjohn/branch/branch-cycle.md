# `feat/shopify-theme-delete-marker` cycle

## PLAN

- [x] A consumer asked to be able to clear away its own spent preview themes; the guard offered no path.
- [x] Design chosen with the requester from three options: a marker seam, not a blanket non-live allow.

## CREATE

- [x] `guard-live-theme.ps1`: read the third seam, resolve `$DELETE_MARKER` (empty = off), collision rule, rewrite rule 2, header.
- [x] `team-shopify/README.md`: the seam table row plus a named section, since this grants a capability rather than narrowing one.
- [x] `adopt-shopify-floor.ps1`: a pointer in the appended seam block, mirrored via `build-shared-scripts.ps1`.

## TEST

- [x] `guard-live-theme.tests.ps1`: +17 cases, 85/85.
- [x] `adopt-shopify-floor.tests.ps1`: 36/36.
- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] The default asserted in both directions: unanswered seam refuses a delete however the command is decorated.

## DEPLOY

- [x] PR opened and merged on green gates -- scripts, tests and docs, nothing to judge by eye.

## Where I left off

The capability does not reach the requesting consumer until a release carries it: their plugin runs from
the cache, so `4.16.0` there still has the absolute rule. A cut is Dave's explicit request and has not
been made -- that is the one step left.
