# `feat/connector-xoxowildhearts` cycle · 20260820-002005

## PLAN

- [x] Verify #764's own precondition: its rule is "after the consumer's PR merges", so check that first
- [x] Measure the consumer's state independently instead of transcribing the report

## CREATE

- [x] `connectors/xoxowildhearts.json` -- the three team plugins, all 25 lenses, private, sibling checkout
- [~] The `workflow-davekjohn` block -- left out on purpose: their workflow choice is in an unmerged
      branch, and the check reads the local checkout, so either answer is an `[ERROR]` half the time
- [x] Notes carrying the measurement, the three divergences, and why the slot is open

## TEST

- [x] `check-connectors.ps1`: 0 errors (the two `[INFO]`s are life-hub's un-migrated ids, pre-existing)
- [x] All 25 lens files, the enabled plugins and the checkout verified against the consumer, not the report
- [x] `check-plugin-integrity.ps1` green

## DEPLOY

## Where I left off

Done. Two things came out of writing one JSON file, both worth more than the file.

The register refused the manifest on its first run -- the local checkout sits on the consumer's in-flight
branch, which switches the workflow plugin -- and that refusal is the register doing exactly its job.

And it answered half of #763 without being asked: `workflow-default` is the "no workflow chosen" slot, it
ships no session-check hook, and the folder `[ERROR]` #763 wants an opt-out for comes only from
`workflow-davekjohn`. The consumer switched to it at 00:16, eight hours after filing. #763's second half is
closed with that evidence; its first half (the bootstrap still scaffolding the retired `Get-ChangelogHeading`)
still stands and is the next branch.
