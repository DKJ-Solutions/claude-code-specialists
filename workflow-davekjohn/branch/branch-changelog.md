## `docs/v4-12-0-timing-total` changelog

### Branch title

The v4.12.0 release note gains its end-to-end total

### Branch ID

20260816-120443

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.12.0`'s note was frozen at a **4m 57s** head; the remaining legs -- writing the
document (4m 00s), its own gates (2m 43s), CI (7m 25s), the merge with the fold, and the publish
(34s) -- are added, giving a **total of 20m 41s** from clock start to a published Release with its
attachments. The legs are given as measured rather than reconciled to the total; the seconds between
them are the gaps between one command finishing and the next starting.

**The tail is 15m 44s, and it breaks a band that had held for five consecutive releases** -- 19m 26s,
18m 47s, 19m 55s, 19m 50s, 19m 42s, then 15m 44s. The previous note argued from four measurements that
the tail was stable and from the fifth that stability was *a property of the procedure* rather than a
run of coincidences. That claim survives intact: what moved the sixth is a change to the procedure, not
noise in it. The middle three legs ran as one uninterrupted motion of 10m 57s, where the five releases
before paid standalone gates, then CI, then a separate merge leg that re-ran those same gates.

**The four-minute drop matches the 249s duplicated gate run measured across 293 pull requests, and the
note deliberately refuses the obvious reading of that.** The saving was collected by shipping in one
motion, so the second gate run was never due; `#728`'s record makes a *split* ship cost nothing, which
is a different route to the same four minutes and is **not** what happened here. Reporting this as
evidence for the record would be exactly the error this release's own theme is about -- a real
measurement attached to the wrong cause, which is how a number that is true becomes a claim that is
false. So the note names both routes, says which one it demonstrates, and files the unmeasured one in
*what was still open* for the first release that splits the two steps.

**The bullet promising this edit is replaced rather than ticked**, following the rule `v4.7.0` set and
`v4.11.0` applied: an attachment is what was published at the moment of publication, so the note now
states that the attached copy carries the head only and stays frozen. A promise written into a published
record becomes false the moment it is kept, which is why it becomes a condition instead.

### Significance

#### Tier 0

Completes the release's own cost record, and marks the first tail movement in six releases with its
cause correctly attributed rather than assigned to the nearest plausible repair.

**Score:** 3

#### Tier 2

A two-line edit to a page a consumer may already have read; nothing they do changes.

**Score:** 1

### Pull Request

