## Branch `docs/v4-13-0-timing-total` changelog - 20260816-210952

### What does the change on this branch bring to main?

#### Tier 0

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.13.0`'s note was frozen at a **6m 15s** head; the remaining legs -- writing the document
(2m 40s), its own gates (2m 50s), CI and the merge (8m 07s), the fold and the publish (46s) -- are added,
giving a **total of 20m 38s** from clock start to a published Release with its attachments. The legs are
given as measured rather than reconciled to the total.

**The head and the total moved in opposite directions, and the note reports them together rather than
picking the flattering one.** The head is a minute above the five-release band because the ordinary,
pushing form of the cut was refused by the session's permission classifier and had to be re-run in its
`-NoPush` form with the push issued by hand. The total came in three seconds *below* `v4.12.0`'s 20m 41s
anyway, because the tail was 14m 23s against 15m 44s -- one CI run finishing faster, not a repair. Reporting
only the head would have said the release got slower; reporting only the total would have hidden a
harness-level cost worth watching if it recurs.

**Neither number is offered as a trend**, and the note says so in those words. What the pair does support is
the older claim they were taken against: the tail is a property of the procedure rather than a run of
coincidences, and the procedure did not change between these two releases.

**The bullet promising this edit is replaced rather than ticked**, following the rule `v4.7.0` set: an
attachment is what was published at the moment of publication, so the note now states that the attached copy
carries the head only and stays frozen. A promise written into a published record becomes false the moment it
is kept, which is why it becomes a condition instead.

**Score:** 2

#### Higher than tier 0?

A two-paragraph edit to a page a consumer may already have read, in the organisation's section rather than
theirs. Nothing they do changes.

**Score:** 1

### Pull Request

The v4.13.0 release note gains its end-to-end total
