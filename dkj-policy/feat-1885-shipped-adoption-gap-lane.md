## feat/1885-shipped-adoption-gap-lane

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

- [x] Read #1885 and establish it still stands -- the four scripts it names are still shipped by
      `dkj-subagents-shopify` and still carried locally by the stores.
- [x] Decide whether the lane RECLASSIFIES an only-in/drifted path or ADDS beside it. Adds: the match
      is on filename, and reclassifying would let one coincidental name delete a real divergence
      finding -- the false negative this whole check exists to prevent.

### CREATE

- [x] `Get-ShippedScriptIndex` in `scripts/lib/sibling-divergence-lib.ps1` -- the marketplace's own
      `.ps1` files indexed by basename, from two sources: the `Get-SharedScriptPairs` registry and a
      walk of each published plugin's `scripts/` and `hooks/`.
- [x] `Find-ShippedMechanism` in the same lib -- the pure decision, over the comparison
      `Compare-SiblingInventory` already returns.
- [x] `Get-MarketplaceShippedScript` in `scripts/sync/check-consumer-siblings.ps1` -- the disk read,
      degrading to an empty set rather than throwing.
- [x] The SHIPPED reporting lane, the summary line, and the script's own docstring.
- [x] `connectors/README.md`: the finding-class table and why the lane exists. `PARTIAL` was missing
      from that table before this branch and is added in the same pass.
- [x] `scripts/README.md`: the row for the check.

### TEST

- [x] `scripts/tests/sibling-divergence.tests.ps1` cases 11 and 12 (plus an `Assert-False` helper):
      the `.ps1` bound, two-site and duplicate-site indexing, both real shapes of the gap, the
      adds-never-reclassifies property, and `PARTIAL` in a three-member group. 70 pass.
- [x] Lint gate `check-plugin-integrity.ps1`: 0 errors.
- [x] All 96 suites via `Invoke-TestSuiteGate`, the way CI runs them: pass.
- [x] End to end against the real register: the lane names six adoption gaps in the BWJ pair and
      nothing spurious -- six of 94 findings.

### DEPLOY: feat/1885-shipped-adoption-gap-lane

`check-consumer-siblings.ps1` gains a fifth finding class, **SHIPPED**: a comparable path that a
plugin in this marketplace **already publishes**. That is an *adoption gap* rather than divergence,
and it is a sentence none of the three consumer checks could form. `check-consumer-drift.ps1` compares
agent defs and personas, `check-consumer-siblings.ps1` compares consumer to consumer, and
`check-script-contract.ps1` asks whether a consumer exposes the seam functions the shared scripts
call -- so a store re-implementing a shipped script read as `DRIFTED` when both did and `ONLY-IN` when
one did, and neither verdict contained the fact that decides what to do about it.

The report was upside down as a result: the **cheapest** convergence -- adopt what already exists --
was the one nothing could see, while the expensive kind (decide an owner, move the mechanism, release,
adopt) was the only kind surfaced.

Measured on the BWJ pair the day it landed, it names **six** of 94 findings, four of which #1885
predicted and two it did not: `scripts/task/prune-merged.ps1`, which is #1869's own load-bearing
instance and is *still* carried locally by **both** stores, and `scripts/tests/test-lib.ps1`, which
`dkj-policy-bwj` had begun shipping hours earlier under #1881.

**It adds and never reclassifies.** A `SHIPPED` path is still reported as `ONLY-IN` or `DRIFTED`
beside it. The match is on filename -- weak evidence, stated as such in the report, exactly as the
`ALIASED` lane states its own -- so a wrong match costs a reader one file to open and can never delete
a real divergence finding. The index is bounded to `.ps1` for the same reason: every plugin ships a
`README.md`, and a basename index over all files would answer *"already shipped"* for every README in
every consumer. `.github/workflows` templates are excluded by that same bound and deserve it
independently -- those are **meant** to be copied verbatim, so a consumer holding one is the mechanism
working.

Still a detector. Nothing refuses; `-FailOnFinding` now counts a `SHIPPED` finding too.

**Score:** 3

#### What makes this deploy extra special

It inverts which convergence the tooling makes visible. Every lane before it reported work that needs
an ownership **decision** before anything can happen; this one reports work where the decision is
already made and only the adoption is outstanding -- and it found that the instance the whole sibling
check was built around, `prune-merged.ps1`, is one of them in both stores at once.

**Score:** N/A

#### Pull Request

The sibling check reports an adoption gap, not just divergence
