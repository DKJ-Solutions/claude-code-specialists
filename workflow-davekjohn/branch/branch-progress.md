## `docs/v4-10-0-timing-total` progress

### Steps

#### PLAN

- [x] Reconstruct every leg from real timestamps (git commit times, command returns) rather than estimates
- [x] Check the tail against the three previous releases before claiming a pattern

#### CREATE

- [x] Replace the head-only paragraph in `What it is worth` with the total and both series
- [x] Update the duplicated-merge-leg bullet with this release's fourth measurement
- [x] Replace the "total not in it yet" bullet with the frozen-attachment rule

#### TEST

- [x] Gates green via `open-pr.ps1`
- [~] No automated test: the deliverable is prose in a published record, and the one rule with a measured basis (no links into `development/` or `internal/`) is already lint check 25

### Where I left off

Nothing outstanding. The attachment on the GitHub Release is deliberately left frozen at the head-only
version, and the document now says so.
