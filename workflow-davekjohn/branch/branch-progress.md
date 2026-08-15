## `feat/cut-release-driven-by-a-suite` progress

### Steps

#### PLAN

- [x] Check the script is drivable at all before promising a suite: it resolves its root from
      `CLAUDE_PROJECT_DIR` and has `-NoPush`, so a fixture can hold it entirely off the network
- [x] Copy the fixture's seam libs verbatim from this repo, the choice `script-contract.tests.ps1`
      already makes, so a pass is grounded in the real answers rather than a stand-in

#### CREATE

- [x] `#708` — `cut-release-drive.tests.ps1`: happy path, unearned bump, new major without a section
- [x] Match the history page's real shape after the first draft silently wrote no row and refused
      nothing, and record why beside the fixture
- [x] Route every git call through `Invoke-NativeCapture` rather than re-learning #107 by hand
- [x] `#708` — the `.NOTES` coverage block in `cut-release.ps1`, stating what is proven and what stays
      uncovered, which is the asymmetry with `ship-pr.ps1` the issue was really about
- [x] Mirror the script to the plugin copy
- [~] Cover the push branch — deliberately not done: a suite that can reach a remote is a suite that
      can push, and no assertion is worth that
- [~] Cover the hand-written consumer/internal documents — not testable: they are prose a person writes

#### TEST

- [x] `cut-release-drive.tests.ps1`: 17 asserts, all passing, against a fixture with no remote
- [x] `cut-release-guardrail.tests.ps1` still green -- the two suites cover what the script SAYS and
      what it DOES, and neither replaced the other
- [x] `check-plugin-integrity.ps1` green, parse count up to 114 with the new suite in it
- [x] full test suite green

### Where I left off

