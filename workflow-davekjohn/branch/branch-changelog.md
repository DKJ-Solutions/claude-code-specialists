## `docs/v4-10-0-timing-total` changelog

### Branch title

The v4.10.0 release note gains its end-to-end total

### Branch ID

20260815-123108

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.10.0`'s note was frozen at a **5m 12s** head; the five remaining legs -- writing the
document (3m 24s), its own gates (4m 08s), CI (7m 55s), the merge with the fold (4m 02s) and the publish
(21s) -- are added, giving a **total of 25m 02s** from clock start to a published Release with its
attachments.

**The tail is 19m 50s, and this is the FOURTH consecutive release to land inside a seventy-second band**
-- 19m 26s, 18m 47s, 19m 55s, 19m 50s -- while the head over the same span moved from 15m 31s to about
five minutes and stayed there. The document gives both series rather than the tail's percentage, and says
why: the tail is made of fixed legs and barely moves, so a rising *share* is the head having been fixed,
not the tail getting worse. Reporting the fraction alone would read as a regression in a procedure that
has only improved.

**A leg the previous notes did not separate: how much of it blocked a person at all.** About 4m 05s of
the 25m -- the intake question the cut ends in (what the release is called), the inspection before the
push, and writing the document. The other 21 minutes ran unattended. That split is the one that decides
whether the total is worth shortening, and a single figure hides it.

**The duplicated merge leg is measured a fourth time and is unchanged**: `ship-pr` re-runs the suites the
pull request already proved, inside a 4m 02s merge leg here, against roughly 3m 27s, 3m 18s and three
minutes at the three releases before. Four consistent measurements make it the largest single saving left
in the procedure; it stays named in *what was still open* rather than being acted on here.

**The attached copy stays frozen**, and the note now says so in place of the bullet that promised this
edit -- following the rule `v4.7.0` set: an attachment is what was published at the moment of
publication, and silently replacing it is the opposite of the record the document is for. The bullet it
replaces would otherwise have become false the moment this merged, which is the failure mode of writing a
promise into a published record instead of a condition.

### Significance

#### Tier 0

The release procedure's only record of what it costs end to end, in the unit the question is asked in.
It also adds the blocked-versus-unattended split, which is what turns the total from a number into a
decision about whether to shorten it -- and retires a bullet that would have gone stale on merge.

**Score:** 3

#### Tier 2

A consumer reading this release's note gets the whole cost rather than the fifth of it that was visible
when the document was frozen, and is told plainly that the attached copy is the frozen one. Nothing they
do changes.

**Score:** 2

### Pull Request

