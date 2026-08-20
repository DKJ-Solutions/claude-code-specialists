# `docs/v4-15-0-release-note` cycle · 20260820-090800

## PLAN

- [x] Read the whole generated draft, all 12 tier-2 entries, before rewriting any of it
- [x] Verify the v4.14.0 defect did not repeat — the two entries headed `Higher than tier 0?` carry prose
- [x] Collect the timing legs from commit timestamps rather than estimating them

## CREATE

- [x] Rewrite the audience section: urgency first, second person, action stated or explicitly absent
- [x] Write *what it is worth* — the guard, the permission-list gap, the four documents naming absent things
- [x] Write *what was still open* as a snapshot, including the two guard reports the cut does not answer
- [x] Timing, first pass: clock start, the measured legs, the subtotal to freeze

## TEST

- [x] `check-plugin-integrity.ps1` — 0 errors; `[consumer-tier]` checked 25 docs, no findings
- [x] All suites — 44 suites, 208 asserts, 0 fail, 148s

## DEPLOY

## Where I left off

The v4.15.0 release document, written and ready to ship. The cut is already tagged and pushed; the GitHub
Release is published after this merges, and the end-to-end total then lands in its own small edit.
