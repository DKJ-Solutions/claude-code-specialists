## `docs/v4-8-0-timing-total` changelog

### Branch title

The v4.8.0 release note gains its end-to-end total

### Branch ID

20260813-210057

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.8.0`'s note was frozen at a 5m 02s subtotal; the five remaining legs — writing the
document (3m 48s), its gates (3m 12s), its CI (7m 33s), the merge with the fold (3m 54s) and the
publish (20s) — are added, giving a **total of 23m 49s** from clock start to a published Release with
its attachments.

**The tail was 18m 47s, 79% of the total — and within forty seconds of `v4.7.0`'s 19m 26s.** Four timed
releases have now produced four different fractions, but the last two agree on something more useful
than a fraction: the tail is nearly constant in absolute terms, because it is made of fixed legs — this
CI run landed within two seconds of the previous release's, the document gates within three seconds.
The fraction grew only because the head shrank. That moves the optimisation question: the head is at
five minutes and nearly all gates, so the next saving lives in the tail's one duplicated leg — the
merge re-running the suites the PR already proved — measured here at about three of the merge leg's
3m 54s, consistent with `v4.7.0`'s 3m 18s.

**The copy attached to the GitHub Release is the frozen one**, and the note says so, following the rule
`v4.7.0` set: an attachment is what was published at the moment of publication, and silently replacing
it is the opposite of the record the document is for.

### Significance

#### Tier 0

The fourth timed release turns "the tail is unpredictable" into something sharper — the tail is
constant, the head is what varies — which redirects the next optimisation from the head (already at
five minutes) to the duplicated merge-leg gate run.

**Score:** 3

#### Tier 2

A consumer reads the release note, so a measured claim inside it is a claim made to them; this one
tells them where a release's time actually goes, on numbers from two consecutive releases that agree.

**Score:** 2

### Pull Request

