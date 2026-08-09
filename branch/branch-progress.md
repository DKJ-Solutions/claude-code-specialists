## `fix/stamp-the-source-measurement` progress

### Steps

- [x] `check-connectors.ps1`: name the measured commit in the run header, once at run level, degrading
      silently where the source tree is not a git repo
- [x] `connector-sessioncheck.ps1`: lift that value out of the header into the summary line, with the
      pointer to `git rev-parse --short HEAD`; no second git call
- [x] Tests: the check prints a real short sha; the hook forwards it, does not forward the header
      itself, and invents nothing when the header carries no stamp
- [x] `connectors/README.md`: the measured instance and the two properties that are the design
- [x] Gates: lint + all suites green
- [~] Not extended to `roster-sessioncheck` / `script-contract-sessioncheck` — they make no version
      claim, which is the specific thing that ages here; widening it would add a token to every
      session start for a defect not yet measured there

### Where I left off

Done; gates green. Closes #533 together with PR #535, which shipped the other half.
