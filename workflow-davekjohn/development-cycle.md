# Development cycle: `fix/pr-body-keeps-the-deploy-opening-v1` · 20260824-101651

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

Get-PrDescription recognises the DEPLOY heading as the start of the answer when there is no What section, so the merged development-cycle format stops falling back to a reader whose first-### heuristic now lands inside the body.

Get-PrDescription recognises the DEPLOY heading as the start of the answer when there is no What section, so the merged development-cycle format stops falling back to a reader whose first-### heuristic now lands inside the body.

## PLAN

- [x] Verify the inbound still stands, in this repo rather than only in the consumer that filed it:
      PR #856's body opens with the tier-2 text under the template's own heading, and the four
      paragraphs saying what the branch deploys are absent. Reproduces here.
- [x] Verify the reported REASON, which was inferred from the outside and turned out to point one
      function further than it named: `Get-PrDescription` does return `''`, but the loss happens in
      `Get-EntryDescription`, whose "first `### ` line is the heading" contract was written when the
      entry heading itself was an H3. Under the merged format that first `###` is
      `### What makes this deploy extra special` -- a section inside the body, hence the ~24% tail.
- [x] Check the repro the report offers before relying on it: it dot-sources via
      `Resolve-PluginScript`, which exists nowhere in this tree. The measurement is sound and was
      reproduced another way; the snippet as written would not run. Say so when closing.
- [x] Decide which of the two candidate sites takes the repair: `Get-PrDescription`, because the PR-body
      rule (the answer onwards, minus the front matter and the trailing Pull Request section) is still
      exactly right -- only its start line was missing. Widening `Get-EntryDescription` instead would
      change what a pre-dossier entry returns, the one shape it exists for.
- [x] Establish that nothing was lost permanently before scoping it as urgent: the fold is unaffected,
      `CHANGELOG.md` received every entry complete. What was lost is the review moment.

## CREATE

- [x] `Get-PrDescription` reads the DEPLOY heading via `Get-DevelopmentCycleEntryPattern` -- the same
      matcher the fold and both gates use -- with the author's own `What` heading still winning where
      both are present.
- [x] A local default for that pattern beside the probe, because the suite dot-sources this lib alone;
      documented as the same two shapes the lib ships rather than a second definition of the rule.
- [x] `Get-EntryDescription`'s docstring names itself a pre-merged-format reader and says why it is
      deliberately not widened.

## TEST

- [x] 14 new asserts in `scripts/tests/pr-body.tests.ps1`: the merged shape keeps its opening text and
      carries strictly more than the fallback would, the previous DEPLOY shape too, a `What` section
      still wins where both are present, a fenced DEPLOY heading is a quote, and the trailing
      `Pull Request` section is still dropped. 126 asserts green.
- [x] A drift guard, because a local default and a real matcher are two readers of one rule: the suite
      loads the scaffold lib **last** and asserts both readers return the same answer on all three
      fixtures. Without it the default could rot silently -- which is the accumulation-bug shape this
      repo keeps finding.

## DEPLOY: `fix/pr-body-keeps-the-deploy-opening-v1`

Since the development cycle became one document, every PR body has silently lost the entry's opening text
-- the substance a reviewer decides on. `Get-PrDescription` looks for a `What` heading, the merged format
has none (its body sits directly under `## DEPLOY:`), so the caller fell back to `Get-EntryDescription`,
whose "the first `### ` line is the entry heading" rule was written when the heading really was an H3.
Under the merged format that first `###` is a section inside the body, so the fallback returned the tail
from there: measured at 0 chars from one function and ~24% of the entry from the other, in a body that had
a heading, a filled-in significance section and a green CI. `Get-PrDescription` now recognises the DEPLOY
heading itself, through the same matcher the fold and both gates use, and a `What` section still wins
where an author wrote one. **The fold was never affected** -- `CHANGELOG.md` received every entry complete
-- so nothing is lost in the record; what is restored is the review moment.

**Score:** 4

### What makes this deploy extra special

This was reported by a consumer, on the first PR they opened under the merged format, and it reaches every
other consumer the same way it reached them: through a plugin update, with no action on their side. Their
report is also the reason it was found at all -- the failure is silent and the body looks complete, so the
gates could not have caught it. Two things go back to them with the close: the repair sits one function
further along than the report proposed, and the repro snippet names a `Resolve-PluginScript` that exists
nowhere in the tree, so it would not run as written.

**Score:** 4

### Pull Request

The PR body carries the entry's opening text again
