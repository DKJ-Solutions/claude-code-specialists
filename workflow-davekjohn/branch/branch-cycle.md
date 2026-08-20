# `feat/shopify-floor-adoption` cycle · 20260820-094648

## PLAN

- [x] Verify all three inbound reports against the tree before scoping
- [x] Read both consumers' own `.theme-check.yml` and CI workflow instead of inventing check names
- [x] Ask Dave the one decision the starter config needs: green on arrival, or assume a clean theme

## CREATE

- [x] `scripts/task/adopt-shopify-floor.ps1` + its `team-shopify` mirror and registry entry
- [x] `adopt-shopify-floor/SKILL.md`, and the two canonical skill-list spans in the root README
      (the marker itself is not quoted here: check 10 reads a lone opener as an unclosed span)
- [x] The guard and the floor session check read a non-numeric id as unanswered
- [x] The floor session check reports a second `PreToolUse` guard in the consumer's own settings
- [x] The README's *Converging off a hand-written guard* section

## TEST

- [x] `adopt-shopify-floor.tests.ps1` — new, 36 asserts, 0 fail
- [x] `guard-live-theme.tests.ps1` — groups 5 and 6 added, 69 asserts (from 51), 0 fail
- [x] `check-plugin-integrity.ps1` — 0 errors (it caught both missing skill-list entries first)
- [x] The integrity fixture's marketplace grows with the registry — the new `team-shopify` pair made
      `Get-SharedScriptPairs` throw inside the synthetic tree and failed 22 unrelated scenarios; the
      fixture's own comment had predicted it. All four integrity suites green: 42 · 75 · 73 · 48

## DEPLOY

## Where I left off

All three inbound items answered. #777's third point is closed as already-answered rather than built: the
README has named the accepted marker spellings since `056a097`. Reply on each issue after the merge.
