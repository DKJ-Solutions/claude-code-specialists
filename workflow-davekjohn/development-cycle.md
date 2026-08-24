# Development cycle: `docs/merge-wait-23-percent-n100-v1` · 20260824-090411

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

Repoint the two-to-one claim (n=3) to 23% over n=100 in the published 4.18.0 audience note and in the pending CHANGELOG entry, naming the sample size that produced the error.

Repoint the two-to-one claim (n=3) to 23% over n=100 in the published 4.18.0 audience note and in the pending CHANGELOG entry, naming the sample size that produced the error.

## PLAN

- [x] Verify the claim still stands: found in three places, not the one the report named -- lines 288
      and 330 of the published `4.18.0.md` audience note **and** a pending `CHANGELOG.md` entry that
      has not been cut yet, so left alone it reaches v4.19.0's release documents as a current figure.
- [x] Establish that correcting it is Dave's call rather than a repair: the note is published, and the
      report says so itself. Asked; answered "both places".
- [x] Decide what NOT to touch: the copy attached to the GitHub Release stays frozen, under the
      standing rule the note's own open section already states.

## CREATE

- [x] Repoint both paragraphs in `workflow-davekjohn/releases/audience/4.x/4.18.0.md`, each keeping the
      reading it was built on and gaining the population figure beneath it.
- [x] Mark the tally superseded in the pending `CHANGELOG.md` entry, keeping that entry's account of
      what its own branch did.

## TEST

- [~] No suite: the change is prose in two documents, and the only mechanical claims in it -- that the
      links resolve and that the release-note tree still parses -- are what `check-plugin-integrity.ps1`
      and the release suites already read on every PR.

## DEPLOY: `docs/merge-wait-23-percent-n100-v1`

A measurement published in v4.18.0's release note said the tally was **two to one** for the non-required
check governing `ship-pr`'s merge wait. Over the population -- n=100 paired pull-request runs -- it is
**23 of 100**, and the median cost of that wait is **0s**. Both paragraphs now carry the population figure
and name the n=3 that produced the error, so a reader sees the sample size rather than only the corrected
number. The same claim was also sitting in a changelog entry that has not been cut yet; left alone it
would have reached the next release's documents as current, so it is marked superseded there too. The
copy attached to the GitHub Release is deliberately not swapped.

**Score:** 3

### What makes this deploy extra special

N/A -- the corrected figure is this repo's own CI timing. Nothing a subscriber of a service does changes
because of it.

**Score:** N/A

### Pull Request

The merge-wait figure is corrected to 23% over n=100
