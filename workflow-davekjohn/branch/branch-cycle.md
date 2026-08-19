# `fix/team-shopify-store-neutral` cycle · 20260820-000746

## PLAN

- [x] Verify inbound #765 still stands: the three descriptions do name the store, in this tree, today
- [x] Recount the subject before scoping it -- the report's number is whatever its grep matched

## CREATE

- [x] The three `description:` lines the report named
- [x] The three body identity lines it did not -- *"You are **Liam**, the Liquid Developer for
      smartwatchbanden"* -- which is the sentence the subagent acts on
- [x] Steven's `~68 themes`, one consumer's inventory stated as the specialist's own reality
- [~] `plugin.json`'s "(e.g. smartwatchbanden)" -- left: an example, correctly marked as one, and the
      report says so too
- [~] The manuals -- nothing to do: they already say `--store <store>.myshopify.com` throughout

## TEST

- [x] `grep -ri smartwatchbanden plugins/teams/team-shopify/` returns only the marked example
- [x] `check-plugin-integrity.ps1` green, including `[agent-def]` and `[specialist]`
- [x] All test suites green

## DEPLOY

## Where I left off

Done. The recount is the part worth carrying: 3 reported, 6 actually, and the three the report missed were
the ones each subagent reads as its own name. Reported back on the issue with the measurement rather than
repaired quietly to the number that was filed.

Verified in passing that the previous branch's promotion works end to end -- `new-branch` wrote this cycle
file with an `#` title over `##` phases, and the lint's byte-exact template check is green on it.
