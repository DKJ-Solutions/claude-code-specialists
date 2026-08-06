## The v3.6.0 release documents: the internal note and the edited highlights

### What does this change do?

**The two hand-written documents of the v3.6.0 cut**, landing the ordinary way because the release commit
was tagged before either existed: the internal note written from its generated skeleton, and the highlights
draft rewritten for the reader it is actually for.

**The highlights went from 1,132 lines to about 110, and that is a rewrite rather than a trim.** The draft
is the seventeen tier-2 entries in the words their authors wrote for someone reviewing a diff; a consumer
is deciding whether to update. The structural decision was to promote the **three items that ask something
of the reader** — stripping the scaffold marker from filled lens titles, migrating a changelog that still
has section headings, and the moved documentation URLs — out of the body and into a numbered block at the
top, with everything else stated as "nothing else requires action". That is the tier model applied to the
document's own layout: two of those three are the release's only significance-5 rows, and burying a
required migration two thirds of the way down is the failure the ranking exists to prevent.

**The internal note names two things it deliberately did not fix**, because this tier is where an
organisation reads what a release was worth and an unstated known defect is worth less than a stated one:
the mojibake check cannot tell a quoted example from a real occurrence — it flagged the entry that
described the problem, the fifth instance of that shape here — and 7 of 326 dated headings in the published
history are a day or two out, left alone because they sit in records that already travelled. Both are
recorded as Dave's call rather than as open work anybody has taken.

**One line in the note is about this release's own near miss**, and it is phrased as a question rather than
a finding: the empty-section defect was caught by `-NoPush`, the one step where a person sees the assembled
document before it is public, and that step is optional. Whether it should stay optional was not decided
here.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

### Type of change

Docs
