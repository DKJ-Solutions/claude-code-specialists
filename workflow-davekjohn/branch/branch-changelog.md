## Branch `docs/v4-14-0-timing-total` changelog - 20260819-135552

### What does the change on this branch bring to main?

#### Tier 0

The second timing pass on the `v4.14.0` release note: the end-to-end total, **26m 40s**, plus the four legs
the document could not see while it was being written -- its own gates, CI and the merge, the fold, and the
publish. The head it was frozen with was 8m 35s, so **68% of the release happened after the page describing
it was final**, which is what the two-pass rule exists for.

**Four releases now agree on the split, and the figures are stated so the next reader can check them rather
than trust them.** The head was 32% of the total here, 30% at `v4.13.0`, 24% at `v4.12.0` and 35% at `v4.4.0`
-- all four under a third, each taken from that release's own document. Four readings are not a distribution
and the note says so; what they support is the older claim that the tail is a property of the procedure rather
than a run of coincidences.

**This release ran six minutes longer than either of the two before it, and the note names where rather than
leaving it to be inferred.** All of it is tail: 18m 05s against roughly 14m 23s at `v4.13.0`. Two legs carry
it -- the test gate inside the cut read **364s** where `v4.13.0`'s cut read **147s** for the same 43 suites,
and CI ran **7m 27s** -- and a refused command is in there too: the first `ship-pr` was stopped by the
step-list gate over a step that named the ship chain itself. The gate was right, the step should not have been
written, and it is recorded because the same shape is available to the next person filling in a step list.

**The attachment on the GitHub Release keeps the head-only version and is deliberately not replaced**, per the
published-record rule -- an attachment is what was published when it was published. The bullet saying so is
rewritten from a promise into a statement now that the number exists, and it names this page as the current
version.

**Score:** 2

#### Higher than tier 0?

N/A -- the edit lands in the organisational half of the note, in a figure about what a release cost this repo.
A consumer's decision to update is unaffected, and the section they read is untouched.

**Score:** N/A

### Pull Request

The v4.14.0 release note gains its end-to-end total
