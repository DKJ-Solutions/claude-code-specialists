## `docs/v4-7-0-timing-total` changelog

### Branch title

The v4.7.0 release note gains its end-to-end total

### Branch ID

20260813-121522

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.7.0`'s note was frozen at a 15m 31s subtotal; the five remaining legs — writing the
document (4m 23s), its gates (3m 15s), its CI (7m 35s), the merge with the fold (3m 18s) and the publish
(27s) — are added, giving a **total of 34m 57s** from clock start to a published Release with its
attachments.

**The tail was 19m 26s, 56% of the total**, against 29% at `v4.6.0` and two thirds at `v4.4.0`. Three
releases have now been timed and produced three very different fractions, which is the argument for two
passes stated more strongly than one measurement could: the tail is not merely large, it is unpredictable,
so an estimate written at the freeze would have been wrong in a different direction each time.

**A figure carried forward from `v4.6.0` did not survive being measured, and it is the one somebody was
about to act on.** That note put the duplicate gate run — `ship-pr` re-running locally what `open-pr` proved
minutes earlier on the same commit — at *about seven minutes off every pull request*. Timed end to end
here, `open-pr`'s whole leg was 3m 15s and `ship-pr`'s 3m 18s, so removing the second run recovers **a
little over three minutes**, not seven. The saving is still real and still the largest single one on the
table; it is half the size the plan assumed. Both the note's *what it is worth* section and its *still open*
bullet are corrected, and the bullet now carries the measured figure rather than the inherited one.

**The copy attached to the GitHub Release is the frozen one**, and the note says so rather than leaving a
reader to discover that the file in the repository and the file they downloaded disagree. Re-uploading the
asset was considered and not done: an attachment is what was published at the moment of publication, and
silently replacing it is the opposite of the record this document is for.

### Significance

#### Tier 0

The seven-minute estimate is the number the next optimisation would have been budgeted against, and it was
wrong by half. Correcting it before anyone builds against it is worth more than the saving itself, and the
third timed release is what turns "the tail is large" into "the tail is unpredictable" — which is the actual
case for the two-pass method.

**Score:** 3

#### Tier 2

A consumer reads the release note, so a measured claim inside it is a claim made to them — and this one
would have shaped what they chose to optimise in their own workflow. This is also the third release running
whose note reports its own corrected figure rather than only its successes, which is the habit that makes
the rest of the document worth trusting.

**Score:** 2

### Pull Request

