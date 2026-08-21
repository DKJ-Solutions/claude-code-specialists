# `fix/cut-release-baseline-crosscheck` cycle · 20260821-132102

## PLAN

Inbound [#802](https://github.com/DaveKJohn/claude-code-specialists/issues/802), verified against the
tree on pickup: the tag-derived baseline (`cut-release.ps1`, the non-plugin-tier branch), the silent
`-NoPush` path, and the stale mirroring claim in the skill all stand exactly as reported.

## CREATE

- [x] `Get-OverviewLatestVersion` in `release-lib.ps1` — the release the overview records as newest,
      walking on past an empty top table (the freshly-opened-major case)
- [x] The baseline cross-check in `cut-release.ps1`, with the other guardrails and before the first
      write; the overview is read once and both guardrails share the snapshot
- [x] `-Type` as the way through, refused alongside `-Bump`
- [x] `-NoPush` closes with `($current -> $new, $typeLabel)`
- [x] The `cut-release` skill: `-Type` documented, and the "not mirrored" claim repaired

## TEST

- [x] `release-lib.tests.ps1`: eight unit asserts on `Get-OverviewLatestVersion`, plus a live
      invariant that maintains itself — this repo's overview and its lockstep manifests must name the
      same release, so no cut has to come back and edit a pinned number
- [x] `cut-release-drive.tests.ps1`: the refusal (naming both numbers, tree untouched), the `-Type`
      run that gets through it asserted on the **label** rather than the exit code, `-Type` alongside
      `-Bump`, and the `-NoPush` closing line
- [x] All 44 suites green, lint gate clean, mirrors regenerated

## DEPLOY

- [x] `build-shared-scripts.ps1` run — both mirrors in sync

## Where I left off

Ready for the PR. Two more inbound issues follow on their own branches: #806 (the fold relocates an
entry two directories up, so its relative links are validated at the wrong path) and #805
(`team-shopify` should own `push-preview`).
