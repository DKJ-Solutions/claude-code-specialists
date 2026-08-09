## `fix/pr-template-restates-the-entry` progress

### Steps

- [x] Measure before cutting: 60 PRs (#468–#537), per-checkbox tick tally, and who fills each section
- [x] `.github/pull_request_template.md` down to one section, `## Changelog entry` + the placeholder
- [x] `open-pr.ps1`: recognise the new placeholder alongside the two legacy ones; keep every tick rule
      for consumers; docstrings rewritten to say why the fill logic outlives the sections
- [x] `open-pr.ps1` `-RefreshBody`: fall back to the previous description headings so a PR opened
      before the rename does not become silently unrefreshable
- [x] Rebuild the plugin mirror (`build-shared-scripts.ps1`)
- [x] Restate lint check 20's justification in `check-plugin-integrity.ps1`, its suite and `CLAUDE.md`
      — the collision it cites is gone, the conclusion is not
- [x] `open-pr` skill page: what `-RefreshBody` leaves alone, and the heading fallback
- [x] Tests: template-to-open-pr placeholder agreement (read from both files), the legacy-heading
      rewrite, a body with no checkboxes, and a full pre-#538 template scenario end to end
- [x] Gates: lint, script contract, all 30 suites green
- [~] `## Resolved issues` not added to the template, against the sketch in #538 — `open-pr` appends
      that block itself, so a heading here would either duplicate it or leave an empty section on a
      `-NoResolves` PR

### Where I left off

Done; gates green. Closes #538.
