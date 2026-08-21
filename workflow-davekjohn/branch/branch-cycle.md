# `docs/redeploy-verify-past-the-cache` cycle · 20260822-002000

## PLAN

- [x] Establish what actually happened before writing anything: the first fetch's byte count and the
      absence of the new template's `Version X.Y` labels, then the cache-busted refetch, then three plain
      fetches, then `cmp` against the built file.
- [x] Decide whether this is a defect or impatience. It is a documented-check false negative, because the
      observation it produces already has a stated meaning on that page and it is the wrong one.

## CREATE

- [x] The skill's verification section gains the measurement, the ordering rule, and `cmp` rather than
      eyeballing a size.
- [x] The build script's printed closing advice says to fetch twice, in **both** mirrors, byte-identical.

## TEST

- [x] `cmp` proves the two script copies identical after the edit, so the shared-script drift lint holds.
- [x] The changed script lines are ASCII, per the script layer's rule -- checked with a non-ASCII grep
      rather than by looking.
- [x] The entry's links are written root-relative, since the fold copies this text into `CHANGELOG.md` at
      the repo root.
- [~] Add retry or cache-busting to a script -- **dropped deliberately.** The build script neither deploys
      nor fetches, and giving it either would make it the thing that verifies its own publication.

## DEPLOY

## Where I left off

Done. The page itself was rebuilt and redeployed before this branch existed, and verified live: 352,146
bytes, byte-identical to the build, newest row `Version 4.18`.
