## `docs/v4-9-0-timing-total` changelog

### Branch title

The v4.9.0 release note gains its end-to-end total

### Branch ID

20260815-093231

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.9.0`'s note was frozen at a 5m 36s head; the five remaining legs — writing the document
(3m 08s), its gates (3m 41s), its CI (7m 50s), the merge with the fold (3m 53s) and the publish (2s) —
are added, giving a **total of 25m 31s** from clock start to a published Release with its attachments.

**The tail was 19m 55s, 78% of the total, and this is the third consecutive release to land within
seventy seconds of the same figure** — 19m 26s, 18m 47s, 19m 55s. The head over those same three moved
from 15m 31s to 5m 02s to 5m 36s. That pairing is worth more than either number alone: the tail is made
of fixed legs and barely moves, so the growing *fraction* is the head having been fixed rather than the
tail getting worse. It also means the fraction is the wrong statistic to track, and the note now says so
by giving both series rather than the percentage on its own.

**The duplicated leg is measured a third time and is unchanged**: the merge re-runs the suites the pull
request already proved, at 3m 27s of the 3m 53s merge leg here, against roughly three minutes at
`v4.8.0` and 3m 18s at `v4.7.0`. Three consistent measurements make it the largest single saving left in
the release procedure; it stays named in *what was still open* rather than being acted on here.

**The attached copy stays frozen**, and the note says so, following the rule `v4.7.0` set: an attachment
is what was published at the moment of publication, and silently replacing it is the opposite of the
record the document is for.

### Significance

#### Tier 0

The timing series gains a third point, and with it the first conclusion that needed more than one: the
tail is near-constant in absolute terms, so the percentage that has been reported for three releases is
the wrong statistic. The duplicated merge leg now has three consistent measurements behind it rather
than two.

**Score:** 3

#### Tier 2

A consumer reading this release's note gets the whole cost rather than the fifth of it that was visible
before the document was merged. Nothing they do changes.

**Score:** 2

### Pull Request

