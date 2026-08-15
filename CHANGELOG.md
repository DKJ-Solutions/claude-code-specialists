# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`workflow-davekjohn/releases/README.md`](workflow-davekjohn/releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-10-0-release-note` changelog

### Branch title

The v4.10.0 release note

### Branch ID

20260815-121334

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can generate.

**The document's first statement is that nothing in it asks for action** -- and then it leads with the
one thing that does, which belongs to the *previous* release. A consumer updating from 4.8.0 or earlier
straight to 4.10.0 is not carried past v4.9.0's two migrations, and nothing in a v4.10.0 note would
otherwise tell them so. Test 3 orders by urgency rather than by which release a change belongs to, so the
conditional migration leads and the link points at the v4.9.0 note rather than restating it.

**The Claude App item is scoped to the reader it actually reaches.** The draft carried it as a fact about
the published set; for a consumer it is true only where their organisation republishes the marketplace
internally, and false for anyone installing from GitHub -- so the section says which of the two they are
before it says what changed. What they notice is stated as the outcome (two entries that could only fail
at their last step are no longer offered, and nothing they have breaks) rather than as the artifact
(152 files becoming 98), which is test 2 doing the cutting.

**The inbound check is written as something the reader will see, not as a rule that was added.** A fourth
question at intake is a process decision; what reaches a consumer is that a name occurring nowhere but in
its own report is now raised as a question before anything is designed, and that *"I cannot see it from
here"* is explicitly not the same answer as *"it is not there"*. The second half is the whole defect #660
cost, so it is the half worth carrying outward.

**One entry got no heading of its own, deliberately.** The v4.9.0 timing total scored tier 2 at 2 with
the author's own reason ending *"nothing they do changes"* -- and its content is an internal cost
measurement, which is exactly what test 2 refuses. It survives as one clause under the migration item
(the v4.9.0 note is complete now), because the selection says which entries are candidates and the tests
say how they are written.

**`What was still open` names four items and one of them is this document.** A release note cannot carry
its own end-to-end total, so the gap is written into the document rather than left for a reader to
notice -- alongside the duplicated merge leg (third release running, ~3m 27s), the two specialists that
travel *degraded* into the Claude App setting, and the fact that this release has not been published to
the organisation, because publishing is a separate decision that has not been asked for.

**Step 0a's first pass is a subtotal of 5m 12s to the pushed tag**, against `v4.9.0`'s 5m 36s and
`v4.8.0`'s 5m 02s -- three consecutive cuts within about thirty seconds of each other, which is the gates
being the floor. Roughly 41 seconds of it blocked a person, and it ended in the one question a script
cannot answer: what the release is called.

### Significance

#### Tier 0

The release procedure's own record of what this cut cost, written while the numbers still exist -- the
head is unrecoverable after the fact, which is why step 0a splits into two passes at all. It also leaves
the next person the three legs to add and says where.

**Score:** 3

#### Tier 2

This is the only document in the release that tells a consumer whether they must act, and for anyone
updating from 4.8.0 or earlier the answer is yes -- a required migration they would otherwise meet as a
session-start `[ERROR]` with no note in this release explaining it. For everyone else it is the plain
statement that nothing is asked of them, which is the answer they came for.

**Score:** 4

### Pull Request

[PR #687](https://github.com/DaveKJohn/claude-code-specialists/pull/687) · merged 2026-08-15

---

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

[PR #688](https://github.com/DaveKJohn/claude-code-specialists/pull/688) · merged 2026-08-15

---

