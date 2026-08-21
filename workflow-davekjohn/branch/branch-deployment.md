## `docs/v4-18-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.18.0 release
document froze at **43m 55s** because three of its legs were still running on the file it was written into --
its own local gates, its CI and merge, and the publish. Those legs now have clock readings, so the total goes
in: **63m 33s** end to end, 19:09:35 to the Release published at 20:13:08, with the note's local gates and
push **4m 37s**, its CI and merge **14m 19s**, and the fold plus publish **42s**.

**Two of this release's readings invert what the previous six supported, and both are stated as mechanisms
rather than as numbers.**

- **The head is 58% of the release** -- 36m 37s of 63m 33s to the tag being pushed -- against 18% at v4.17.0
  and 21% to 32% across v4.12.0 through v4.16.0. Every earlier reading said most of a release happens after
  the version number exists. The reason this one says the opposite is that **a blocked cut moves work into the
  head**: the cut refused on a red test gate, and the 31m 50s of diagnosing and shipping that unrelated repair
  all fell before the tag, because nothing downstream could start until it merged. So the head/tail split
  measures where the obstacles were rather than where the effort inherently is.
- **The unmeasurable share is 31%**, against 65% at v4.17.0, 66% at v4.4.0 and 70% at v4.16.0. Same cause
  read from the other end: the tail a document cannot time about itself is roughly constant per release, so it
  looks small here only because the head was abnormally large.

**And the total is nearly double the previous longest for a reason that is not its size.** 24m 34s for
v4.15.0's thirteen entries, 25m 29s for v4.16.0's four, 32m 19s for v4.17.0's nine, 63m 33s for this one's
fifteen. The spread has never tracked the entry count and still does not. What made this release expensive is
that it needed **two** pull requests where a release normally needs one -- a repair before the cut, then the
note -- and therefore two full CI cycles. CI is the largest single cost in here at **23m 12s**, or **37%** of
the release.

**The first pass's reading about which check governs the merge is CORRECTED here rather than confirmed**, which
is the part of this branch worth more than the total. That pass had one data point -- the repair's pull request,
where the required `lint-en-tests` took 8m 37s against `claude-review`'s 3m 02s -- and concluded the ordering
had reversed from v4.17.0. This note's own pull request says the opposite: `claude-review` **14m 05s** against
`lint-en-tests`'s **9m 58s**. Across three readings the tally is **two to one** for the non-required check
governing the wait, so the direction of the evidence is the same as v4.17.0's after all, and the even split the
first pass implied was an artefact of measuring once. The unstable quantity turns out to be `claude-review`'s
own duration -- 3m 02s and 14m 05s on two pull requests forty minutes apart -- rather than the ordering, which
is a different question from the one that was being asked. Still named and not repaired: a check whose runtime
varies fourfold is the thing to understand before changing what a merge waits on.

The note's open section also gains the standing line that the attachment carries the frozen subtotal only and
is deliberately not swapped -- extended this time to say that the same second pass corrected a reading, so a
reader holding the attachment knows there are two reasons to prefer the page.

**Score:** 2

#### What makes this change extra special

It puts a fourth consecutive end-to-end measurement beside the first three, and this one is the first that
**breaks** the pattern the other three built rather than adding to it. A reader who saw only the four totals
would conclude that releases are getting slower as they get bigger; the measurement says the opposite, and
names the mechanism -- one blocked cut, two CI cycles instead of one.

For a consumer running this workflow the transferable part is a diagnostic they can apply without any of these
numbers: **when a release runs long, check whether it shipped one pull request or two before assuming the work
grew.** A release that had to repair something before it could cut pays for a whole extra CI cycle, and that
cost lands in the head, where the earlier readings had taught everyone not to look.

The correction is worth its own line for the same reason the first pass was: a timing is a count, and this one
was taken once. Publishing an even split off a single pull request and then finding the opposite on the next
one is precisely the recount discipline the house rules ask for, applied to a figure written an hour earlier by
the same hand.

**Score:** 2

### Pull Request

The v4.18.0 release note gains its end-to-end total
