## `feat/branch-entry-gate` deployment

### What does the change on this branch deploy to main?

The branch-entry convention gains a gate that ships instead of being written per repo:
`scripts/lint/check-branch-entry.ps1`, plus the six lines of CI workflow that call it --
`.github/workflows/branch-entry.yml` here, and the same file placed in a consumer by
`adopt-workflow-folder`. One seam comes with it, `Get-EntryGateExemptPrefixes`, defaulting to `sync`.

**It adds no rule of its own**, which is the whole design. It calls the same two functions `open-pr`
calls -- `Test-BranchChangelogIsFilled` and `Get-EntryScaffoldFindings` -- so there is one definition of
"written" in the system rather than a second one in every consumer's CI. That makes it *simpler* than the
hand-written gates it replaces, not more complex.

Three things this branch measured rather than accepted, all of which changed the design:

- **Both hand-written gates are stricter than the convention.** Each refuses a merge over a missing
  significance score, justified by "tier 0 can never legitimately stay empty" -- while
  `entry-scaffold-lib.ps1` reads TIER 0 OWES NOTHING and Dave placed that refusal at the release cut on
  August 5, 2026, so an author who has not settled a score is not blocked from merging. The shipped gate
  reports it and names the cut. That is the load-bearing test in the suite.
- **A PowerShell gate cannot be a job in `ci.yml`**: that workflow also runs on `push: main`, where the
  entry sits in its reset state by design after every fold, so the trunk would be red after every merge.
  Its own workflow file, `pull_request` only.
- **The consumer workflow pins `main`, not a tag.** The entry's path has moved twice; a pinned gate does
  not fail loudly, it refuses branches that *do* carry an entry at the current path.

Two halves of the report are deliberately not built, both with a measurement: the second job of the
consumer's file (`preview-answered`) is repo-specific -- no PR template this marketplace ships has a
Preview section -- and making the check *required* is a branch-protection setting, which is Dave's rather
than a scaffolder's.

**Score:** 3

#### What makes this change extra special

A convention that enforces nothing rots quietly, and this one had the machinery to enforce itself sitting
right there: the plugin ships every reader of the format and shipped nothing that checked it. The two
gates that existed are both local, so a branch pushed by hand or a PR opened in the GitHub UI met neither
-- which is why both consumers wrote their own, from scratch, against a document whose signature they had
to reverse-engineer. Both got it wrong in the same direction, and neither could verify their YAML before
it shipped: one recorded having no parser on the machine at all.

For a consumer this is the difference between owning a gate and running one. The source now runs the same
file on its own PRs, so it is exercised here rather than being unverified in every repo that has it.

**Score:** 4

### Pull Request

The branch-entry convention gains a shipped gate, out of the libs the plugin already owns
