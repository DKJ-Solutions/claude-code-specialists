## `docs/v4-11-0-timing-total` changelog

### Branch title

The v4.11.0 release note gains its end-to-end total

### Branch ID

20260815-155745

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.11.0`'s note was frozen at a **5m 25s** head; the five remaining legs -- writing the
document (2m 55s), its own gates (4m 02s), CI (7m 40s), the merge with the fold (4m 18s) and the publish
(28s) -- are added, giving a **total of 25m 07s** from clock start to a published Release with its
attachments.

**The tail is 19m 42s, and this is the FIFTH consecutive release to land inside a seventy-second band**
-- 19m 26s, 18m 47s, 19m 55s, 19m 50s, 19m 42s -- while the head over the same span moved from 15m 31s
to about five minutes and stayed there. Four measurements made the tail look stable; the fifth is what
makes it a **property of the procedure** rather than a run of coincidences, and the document says so in
those terms. It gives both series rather than the tail's percentage, for the reason the previous note
already established: the tail is fixed legs and barely moves, so a rising *share* is the head having
been fixed, not the tail getting worse.

**The blocked-a-person figure fell from 4m 05s to about 3m 35s, and that is not reported as an
improvement.** The head's two intake moments were the same 40 seconds; what changed is that writing the
document took 2m 55s against 3m 24s -- one document rather than two registers, on a release whose
consumer selection was clearer. It is inside the noise of a single measurement and is given as the leg it
came from rather than as a trend, because two points are not a series.

**The duplicated merge leg is measured a fifth time and is unchanged**: `ship-pr` re-runs the suites the
pull request already proved, inside a 4m 18s merge leg here, against roughly 3m 27s, 3m 18s, three
minutes and 4m 02s at the four releases before. Five consistent measurements make it the largest single
saving left in the procedure and the best-evidenced one; it stays named in *what was still open* rather
than being acted on here, which is the fifth release running that this sentence has been true.

**The attached copy stays frozen**, and the note now says so in place of the bullet that promised this
edit -- the rule `v4.7.0` set: an attachment is what was published at the moment of publication, and
silently replacing it is the opposite of the record the document is for. The bullet it replaces would
otherwise have become false the moment this merged, which is the failure mode of writing a promise into
a published record instead of a condition.

### Significance

#### Tier 0

The release procedure's own cost, complete for the fifth release running, in the unit the question was
asked in. What it buys here specifically is the fifth point on the tail series -- the one that turns a
stable-looking figure into a measured property, and therefore turns "the merge re-runs the suites" from
a recurring observation into the best-evidenced saving this procedure has.

**Score:** 3

#### Tier 2

A consumer reading this release's note gets the whole cost rather than the fifth of it that was visible
when the document was frozen, and is told plainly that the attached copy is the frozen one. Nothing they
do changes.

**Score:** 2

### Pull Request
