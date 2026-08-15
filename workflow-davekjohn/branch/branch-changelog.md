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

