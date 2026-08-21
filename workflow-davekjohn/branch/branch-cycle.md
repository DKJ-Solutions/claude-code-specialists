# `feat/register-xoxowildhearts-workflow-slot` cycle · 20260821-123800

## PLAN

- [x] Verify the subject of inbound #800 rather than the report: the four commits it names exist and say
      what it says, the consumer's `.claude/settings.json` on `main` holds `workflow-davekjohn: true`,
      and the plugin ships no `agents/` -- so `extensions: []` is measured, not un-filled
- [x] Answer the deferral's own caveat ("if the slot is expected to move again, defer a second time"):
      read the slot on all 16 remote branches, not only `main`
- [x] Verify the report's stated reason -- the version check's blind spot -- against
      `check-connectors.ps1`: the loop iterates the manifest's `plugins` array, confirmed
- [x] Measure the size of that blind spot across all five connectors, to see whether it wants a repair
      of its own. Population after this change: 0, so it is named and not built

## CREATE

- [x] The `workflow-davekjohn@claude-code-specialists` block with an empty `extensions` array
- [x] Rewrite the deferral passage into the registration, keeping the deferral's reasoning because it
      was right
- [x] Correct the three "differences" in the same field, all three measured false today, and the
      inbound-#763 reading that went with one of them
- [~] No script or check change. The blind spot the issue describes as its "Why" is real and verified,
      and registering the slot empties it -- so a new plugin-level `[INVENTORY]` line would guard a
      class with no members. Left as a proposal for Dave instead of built

## TEST

- [x] `check-connectors.ps1`: xoxowildhearts now reports four plugins `[OK]` where it reported three,
      including `all 0 registered extensions present` and `machine record is on the source version`
- [x] The two remaining `[ERROR]` lines are this repo's own install records (v4.16.0 vs v4.17.0),
      unrelated to this branch and reported to Dave rather than silently fixed here
- [x] Lint gate + all suites, via the `ship-pr` run below

## DEPLOY

See `branch-deployment.md`.

## Where I left off

Ready to ship. Two things deliberately not in this branch: the plugin-level blind-spot check (population
zero -- Dave's call), and this repo's own out-of-date install records, which are a `claude plugin update`
per plugin rather than a repo change.
