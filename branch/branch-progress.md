## `fix/unrecognised-placeholder-is-silent` progress

### Steps

- [x] Verify #573 against the tree of today: the three claims, and the melding's own reasoning
- [x] `open-pr.ps1`: record whether any placeholder matched, and warn after the loop when none did
- [x] The warning names the file, the strings compared against, and the source of that list
- [x] Docstring: point at `Get-PrDescriptionPlaceholder` as the seam for a differing placeholder line
- [x] `skills/open-pr/SKILL.md`: the same pointer, plus repair the two stale `first ## line` statements
- [x] Test (`shared-scripts.tests.ps1`): a near-miss template warns AND loses the description; the
      ordinary path stays quiet
- [x] Mirror the shared script into the plugin (`build-shared-scripts.ps1`) and run the suites
- [~] Ship the template's shape with the plugin (#573 item 2) and the "#538 as a measurement" caution
      (item 3) — dropped from THIS branch on purpose: a separate `docs/` branch, because it is a design
      choice (a shipped file versus rendering it like `branch/templates/`) rather than a defect repair.
      #573 stays open until that branch lands.

### Where I left off

Item 1 is finished and green. Item 2 + 3 are the next branch.
