## `fix/tier1-note-what-changed` progress

### Steps

#### PLAN

- [x] Verify #747's symptom, reason and proposal against the tree before building any of them
- [x] Reason as reported was WRONG: `-RankByTier` is a sort key, not a filter -- the hardcode is the
      `Tier -eq 2` selection in `cut-release.ps1`, so the defect is in the selection and not the renderer
- [x] Report's premise also wrong: a tier-1 repo CAN pre-fill the section from its tier-1 entries --
      measured by rendering a synthetic tier-1 changelog
- [x] Put the resulting design fork to Dave; he chose the symmetric pre-fill over #747's empty heading

#### CREATE

- [x] `cut-release.ps1`: resolve the audience tier via the existing `Get-EntryAudienceTier` rather than a
      second reader of the seam, and select the note's entries on it
- [x] `Build-ReleaseNoteDraft`: `-AudienceTier` parameter defaulting to 2, used for the ranking and for
      three tier-dependent wording defaults
- [x] Rename `SectionConsumers`/`HintConsumers` to `SectionAudience`/`HintAudience`, still reading both
- [x] Repair the two consumer-facing docs that described the defect as intended behaviour, and the key
      list in `repo-config.ps1`
- [x] Regenerate the plugin mirror via `build-shared-scripts.ps1` -- never hand-edited

#### TEST

- [x] Prove this repo's tier-2 output is byte-identical to `HEAD` across all six shapes the path can take
- [x] `cut-release-drive.tests.ps1`: two scenarios driving the real script, one at tier 1 and one pinning
      tier 2 as unmoved; the fixture patches the copied seam file and throws if the patch no-ops
- [x] `release-lib.tests.ps1`: tier-1 coverage plus the retired-key aliases, and the existing
      `$draftNoTier2` assert reworded to say which repo it is about
- [x] Confirm the four new asserts FAIL against the previous code -- a test that passes either way pins
      nothing
- [x] Full local gate: lint + all suites

### Where I left off

Work is complete and both gates are green. Ready for the PR chain.
