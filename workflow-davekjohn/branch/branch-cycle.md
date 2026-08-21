# `fix/entry-link-destination-gate` cycle · 20260821-135857

## PLAN

Inbound [#806](https://github.com/DaveKJohn/claude-code-specialists/issues/806). Symptom verified: the fold
has no link validation at all and `branch/templates/` says nothing about the convention. **Its reason was
verified and does NOT hold** -- `check-plugin-integrity.ps1` has resolved the entry's links from the repo
root since August 6, 2026, so the claim that a consumer-side linter structurally cannot do this is false.
That moved the repair from the fold to `open-pr` plus the guidance; the reasoning is in the entry.

## CREATE

- [x] `Get-EntryLinkTargets` / `Get-EntryLinkFindings` in `entry-scaffold-lib.ps1`, with the three
      exclusions the measurement demanded (fenced, inline, html comments)
- [x] The link gate in `open-pr.ps1`, printing the root-relative form rather than only the dead link
- [x] The convention in the first section's guidance block, so it reaches the author before the gate --
      moved from `What` to `Tier` after finding `What` is not rendered by the two-section entry at all
- [x] `BRANCH-portable.md` and the `open-pr` skill page, including why `branch-cycle.md` is exempt
- [~] A check in the fold -- dropped, with the reason recorded in the entry: it would be a second
      implementation of a rule the lint already owns, and a fold-time refusal produces the half-state
      the fold's own header argues against

## TEST

- [x] 14 asserts in `entry-scaffold.tests.ps1`: the target extraction, the three exclusions measured
      against the real false positive, the finding, the suggestion, the typo case that gets no guess, and
      that the guidance reaches the generated template
- [x] Templates regenerated (`new-branch.ps1` refreshed the drifted one), mirrors synced, lint clean
- [x] Eight affected suites green locally; the full set runs at the PR

## DEPLOY

- [x] This branch's own entry is the first one the new gate judges -- its links are root-relative

## Where I left off

Ready for the PR. One inbound issue remains: #805, `team-shopify` should own `push-preview`.
