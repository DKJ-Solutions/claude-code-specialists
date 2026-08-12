## `docs/v4-6-0-timing-total` changelog

### Branch title

The v4.6.0 release note gains its end-to-end total

### Branch ID

20260813-001510

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists precisely because the release note cannot time its own
publication. `v4.6.0`'s note is frozen at a 46m 05s subtotal; the five remaining legs — writing the document,
its gates, its CI, the merge and the publish — are added, giving a **total of 64m 52s** from clock start to a
published Release with its attachments.

**The tail was 18m 47s, 29% of the total, against two thirds at `v4.4.0` — and the note says that is not an
improvement.** The head was inflated here by a mid-release repair `v4.4.0` did not have. What both
measurements agree on is that the tail is never small enough to estimate, which is the whole argument for two
passes.

**A wrong measured figure in the first pass is corrected rather than left, and named where it was wrong.**
The note claimed shipping one three-line fix ran the 32 suites *"four times — twice locally, twice in CI — for
about 27 minutes"*. The 27 minutes was the whole release's four timed local runs; the fix accounted for two of
them. The real count is **ten runs over the release**, five local and five in CI, with the four timed local
ones at 26m 58s. The pending `CHANGELOG.md` entry for
[#634](https://github.com/DaveKJohn/claude-code-specialists/pull/634) carried the same claim and is corrected
with it — it was still pending rather than published, so this is a repair and not a rewrite of a record.

**The recount also found the two savings the wrong figure was hiding**, which is the reason it was worth
recounting rather than just softening: `ship-pr` re-runs locally what `open-pr` proved minutes earlier on the
same commit, and three of the five CI runs land on commits nobody waits for. The second is worth nothing to
shorten; the first is about seven minutes off every pull request in this workflow. Neither is built here —
this branch is the measurement, not the repair.

### Significance

#### Tier 0

The seven-minute duplicate gate run is now a measured figure somebody can act on rather than a suspicion, and
the total is in the document instead of only in a chat message nobody will find again.

**Score:** 3

#### Tier 2

A consumer reads the release note, so a false measured claim inside it is a claim made to them. This is also
the second release in a row whose note reports its own process failure rather than only its successes, which
is the habit that makes the rest of the document trustworthy.

**Score:** 2

### Pull Request

