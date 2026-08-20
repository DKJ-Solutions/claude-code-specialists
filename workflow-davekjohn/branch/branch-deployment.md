## `docs/v4-17-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.17.0 release
document froze at a subtotal of **11m 12s** because three of its legs were still running on the file it was
written into -- its local gates, its CI and merge, and the publish. Those legs now have clock readings, so the
total goes in: **32m 19s** end to end, with the local gates and push **4m 03s**, CI and the merge **15m 22s**,
and the fold plus publish **40s**. There was no requester gap to separate out this time; the run was
continuous, so wall clock and working time are the same number.

**The reading worth the branch is which check governed the wait.** `lint-en-tests` is the only required check
on `main` and it passed in **9m 29s**. `claude-review` is not required and took **15m 09s**, and `ship-pr`
waits for every check rather than for the required one -- so the merge landed 15m 22s after the pull request
opened, and that single leg is **48%** of the release. Both figures were read from `gh pr checks` and the
ruleset rather than inferred from the wall clock.

**It is named and not repaired**, under the rule that a risk which has not bitten gets written down rather
than fixed. One measurement is not evidence for changing what the merge path waits on, and the same wait is
what a reviewer would want if the review were the point. It is recorded in the release document's open
section so the next release has something to compare against.

Two readings the first pass could not produce. The head came to **18%** of the total, the lowest of the six
releases timed so far (`v4.15.0` 21%, `v4.12.0` 24%, `v4.16.0` 26%, `v4.13.0` 30%, `v4.14.0` 32%) -- and the
reason is stated rather than left to read as an improvement: the head did not get faster, the tail got longer.
And the frozen subtotal was 65% short of the total, in line with 66% at `v4.4.0` and 70% at `v4.16.0`.

**Score:** 2

#### What makes this change extra special

It puts a third consecutive end-to-end measurement beside the first two, and this one complicates the
fixed-cost claim in a useful direction rather than confirming it: **24m 34s** for v4.15.0's thirteen entries,
**25m 29s** for v4.16.0's four, **32m 19s** for v4.17.0's nine. The spread still does not track the entry
count, which is the claim -- but the longest of the three is longest for a reason that has nothing to do with
its contents, and a reader who saw only the three totals would draw the wrong conclusion about batching.

For a consumer running this workflow, the transferable part is the diagnostic rather than the number: when a
release feels slow, check which check is governing the merge wait before assuming the work grew. The required
gate and the slowest gate are not necessarily the same one, and only the first is the one anybody chose.

**Score:** 2

### Pull Request

The v4.17.0 release note gains its end-to-end total
