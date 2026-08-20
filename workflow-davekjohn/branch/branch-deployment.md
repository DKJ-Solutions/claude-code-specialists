## `docs/v4-15-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.15.0 release
document froze at a subtotal of **5m 12s** because three of its legs were still running on the file it was
written into — its own CI gate, its merge, and the publish. Those legs now have timestamps, so the total goes
in: **24m 34s** end to end, with writing the page **9m 37s**, CI and the merge **8m 22s**, the fold **5s** and
the publish **1m 18s**.

Two readings are added that the first pass could not produce. The head came to **21%** of the release, the
lowest of the four that have been timed (`v4.12.0` 24%, `v4.13.0` 30%, `v4.14.0` 32%) — a fourth reading for
the claim that most of a release happens after the document describing it is frozen. And the two tail legs are
split by whether they blocked a person: writing the page and waiting for CI are **73%** of the release between
them, but only the writing is a person's time, which is what makes the fixed-cost-per-event argument concrete
rather than rhetorical.

**Score:** 2

#### What makes this change extra special

A consumer running this workflow writes the same two passes, so the worked example is the instruction: the
paragraph they see is what a frozen subtotal looks like, and this edit is what closes it. The release note is
the one document that reaches every consumer as an attachment, and it now carries its own cost in the unit the
question is asked in — minutes — rather than in a proxy.

**Score:** 2

### Pull Request

The v4.15.0 release note gains its end-to-end total
