## `fix/the-gate-names-the-shape-it-refuses` progress

### Steps

- [x] Reproduce all three refusals in both shapes before changing anything — confirmed the section
      shape gets `third column` / `second column` / `| row |`, and that the legacy table gets the
      identical wording, where it is correct
- [x] Record the shape: `Shape` on `Resolve-EntryImpact` (`sections` / `table` / `line` / `none`),
      additive so `Table` and every existing caller are untouched
- [x] Word all three refusals per shape, keeping the table's own wording for a real table
- [x] `Get-EntryTierSectionMarker`, so the refusal and the formatter spell `#### Tier N` from one
      source; the two hand-built copies replaced
- [x] Asserts on both branches for all three messages, the four shape stamps, the `Tier: N` case, and
      the marker held against the formatter's own output
- [x] Mirror the shared lib into `workflow-davekjohn` (`build-shared-scripts.ps1`)
- [x] Lint + all suites green
- [~] The stale table vocabulary in `fold-changelog-entry.ps1`'s docstring — dropped from this branch
      deliberately, not overlooked. It is the same class but a different reader (a developer reading
      source, not an author meeting a refusal), and its second half names the retired
      `### Who is this for` heading, so it is a doc change needing its own verification. Reported to
      Dave rather than half-repaired here.

### Where I left off

Done — the chain is at the PR step.
