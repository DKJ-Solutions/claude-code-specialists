## Development: `fix/open-pr-label-preflight-v1` · 20260902-174922

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Inbound [#1221](https://github.com/DaveKJohn/claude-code-specialists/issues/1221): `open-pr.ps1`
resolved the branch prefix's label one line before `gh pr create --label` and let `gh` be the one to
discover it does not exist. `gh` refuses the whole create, so the run ends with every gate paid for,
the branch on `origin`, and no PR -- a state that reads exactly like a parked branch.

Verified against the tree before anything was built: the label was resolved at the create call, the
push sat ~350 lines above it, and nothing between the two asked whether that label exists. The
report's second finding was verified too -- the unknown-prefix fallback substitutes `question`, a
GitHub *default* label a repo may equally have deleted -- and it is covered by checking the label that
would be **sent** rather than the prefix table.

### CREATE

- [x] `Get-LabelNames` + `Get-MissingLabelNote` in `scripts/lib/pr-issues-lib.ps1` -- the parse and the
      refusal as pure functions, the way `Get-ExistingPrRecord` and `Get-MissingCheckSuiteNote` already
      are, because the caller drives a live remote and cannot be covered by a suite.
- [x] The label gate in `scripts/release/open-pr.ps1`: one `gh label list`, above the lint and test
      gates, create path only, not `-Force`-able. The label resolution moved up with it, so the label
      that is checked is the label that is sent.
- [x] Mirror regenerated (`scripts/sync/build-shared-scripts.ps1`).

### TEST

- [x] 32 new asserts in `scripts/tests/pr-issues.tests.ps1` -- the measured payload, the 5.1 parse
      traps, the case-insensitive compare GitHub itself applies, the bounded label list, and five
      call-site asserts pinning that the gate runs BEFORE the push and before the suites.
- [x] `scripts/tests/pr-issues.tests.ps1` green: 433 asserts.
- [x] `scripts/lint/check-plugin-integrity.ps1` green: 0 errors.

### DEPLOY: `fix/open-pr-label-preflight-v1`

`open-pr` now asks GitHub whether the label it is about to attach exists, and refuses there -- before
the lint and test gates, and therefore before the push. The label came from the repo-owned branch
prefix table and went to `gh pr create --label` unchecked, so a renamed or retired label killed the
create after every gate had run and the branch was on `origin`: a pushed branch with no PR, which
reads exactly like a parked one. The refusal names the label, the prefix that produced it, the seam
file that maps them and the labels that do exist -- so a rename (`bug` -> `type: bug`) is a repair
rather than a search.

It refuses instead of falling back, deliberately. Substituting a default label would classify the PR
wrongly and a repo that gates on the label would go green on a label that says nothing; dropping it
would turn that same gate red after a successful create. Both silent options look like kindnesses. The
unknown-prefix fallback is checked on the same footing, since `question` is a GitHub default a repo may
equally have deleted, and a query that cannot be read is not an answer: an old `gh`, a network hiccup
or a repo with no labels leaves the behaviour this script always had.

**Score:** 3

#### What makes this deploy extra special

Every consumer of this workflow labels its PRs from a seam table it owns, and a label is a repo
setting somebody else can change: measured in a consumer on September 1, 2026, `bug` and `enhancement`
were deleted org-wide because the issue **type** now carries that classification, and the seam table
was correct the day before. The failure that produced arrived at the most expensive possible moment --
after the entry, step and resolves gates, after the suites, after the push -- and left behind a state
indistinguishable from a parked branch. Now it costs one API call and lands in seconds, with both
remedies named in the line that refuses.

**Score:** 3

#### Pull Request

open-pr checks the branch prefix's label exists before it pushes
