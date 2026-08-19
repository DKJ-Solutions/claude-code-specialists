## `docs/v4-14-0-release-note` progress

### Steps

#### PLAN

- [x] Establish the state before the cut: clean `main`, no parked branches, 16 pending entries, highest tier
      pending 2 -> minor, audience tier 2, not a major so no section/pin preparation.
- [x] Verify the two consumer claims the page leads with: `/handover` exists as the renamed skill, and
      `Get-ReleaseHistoryPath`'s default is the repo root.

#### CREATE

- [x] Rewrite the *For consumers* section from the eight tier-2 entries, ordered on action rather than score,
      with an explicit "no action needed" on every item that has none.
- [x] Write in by hand the two entries the draft rendered with an empty body (`docs/destination-reach`,
      `feat/agent-shared-under-teams`), recovered from `CHANGELOG.md`.
- [x] Fill *What it is worth* and *What was still open at this release*, first-pass timing included.
- [x] Re-read the carried-forward organisation figure at the target instead of inheriting it; corrected
      4.11.0 -> 4.13.0 with its source commit and date.

#### TEST

- [x] Lint + test gates via `open-pr.ps1` (the seven consumer-document tests are prose, applied by hand;
      only the "no link into `development/`" rule is a gate).
- [ ] CI `lint-en-tests` green, then merge and fold.

### Where I left off

The document is written and the entry is filled in. Remaining after the merge: publish the GitHub Release
with its three attachments, then the second timing pass — the total plus the three legs the frozen document
could not see — as its own small PR.
