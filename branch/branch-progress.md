## `feat/the-pr-template-has-a-portable-half` progress

### Steps

- [x] Move the three recognised placeholder strings out of `open-pr.ps1` into `pr-body-lib.ps1`, so a
      gate can read them — this is what made the rest possible
- [x] `Get-PrTemplateCanonicalPlaceholder` + `Get-PrTemplateReference`, both derived from that one list
- [x] Ship `plugins/workflows/workflow-davekjohn/templates/pull_request_template.md`
- [x] Lint check 24: the reference byte for byte, this repo's own template to the contract only
- [x] Tests: `pr-body.tests.ps1` for the lib and the shipped file; six scenarios in
      `check-plugin-integrity.tests.ps1` for check 24, including the near-miss and the no-template case
- [x] Repair the existing assert that grepped `open-pr.ps1` for the literals — it can call the list now
- [x] Copy the new lib into BOTH lint fixtures, and warn about that trap at the dot-source: a lib a
      fixture does not copy kills the script rather than skipping a check — the test gate caught it as
      four failures in check 23, which this branch never touched
- [x] `open-pr` skill: the two promises, where the reference lives, and item 3's measurement-not-answer
- [x] `CONTRIBUTING-portable.md` + the plugin README's folder table
- [x] `CLAUDE.md`: what travels from #538, and why the placeholder list moved
- [~] The `## Specific to this repo` slot the issue asked for — dropped with the reason on the record:
      every heading in a PR template repeats in every PR body, so an empty slot is a permanent empty
      section. Both documents say to add one when there is something to put in it.
- [~] Extending `adopt-config` to offer the template — dropped from this branch: it works on seam
      FUNCTIONS with `copy`/`decide` markers, and a file is a third kind of record. Worth its own
      branch if a consumer asks; the reference plus the docs already close what #573 asked for.

### Where I left off

Done. #573 is fully answered once this merges — items 1, 2 and 3.
