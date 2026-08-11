## `docs/v4-3-0-release-note` changelog

### Branch title

The v4.3.0 release note

### Branch ID

20260811-091913

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning — and the first one written under the model
it announces, which is why this entry is worth more than "the release note, as usual".

**The mechanism was proven by a real run rather than by the suite.** Every claim the previous branch could
only assert now has a measurement behind it: `releases/notes/4.x/4.3.0.md` was drafted by the cut with a
consumer section and two empty organisation sections; all **seven** strings that should not survive the
strip — `Branch title`, `Branch ID`, `Branch type`, `Pull Request`, `Plugins:`, the score, and the retired
`What is different now` heading — appeared **zero** times; the history row pointed at
`notes/4.x/4.3.0.md` on the first write, with nothing repointing it afterwards; and no
`releases/consumer/4.3.0.md` was written. The generated Release body came to **11 lines** listing all five
changes with their PR links.

**Writing it confirmed the measurement that chose the shape.** The two organisation sections took the
material that a consumer section is not allowed to carry — how the decisions were made, what the thirty-minute
release cost, that four changes this cycle were measured before being built and two of those measurements
reversed the plan — and none of it needed restating in the consumer half. The overlap the merge was supposed
to remove genuinely did not reappear.

**One defect found by writing, and reported rather than repaired.** The draft still carries
`#### What does the change on this branch bring to main?` once per change: branch language inside the section
written for a consumer. It cannot be handled the way the rest of the administration was, because
`Remove-EntryAdminSections` drops a section's **body** with its heading and here the body is the substance.
Closing it needs a heading-only remover. Left unbuilt: it is draft noise the writer deletes in the same pass
that rewrites the prose, and nobody has asked for it.

**And the consumer section names the migration, per the convention that a disappearing thing must be
stated.** A written convention moved — the directory a hand-written document lives in, and the fact that a
patch now writes none — so the section says what appears, what stops being written, that every existing file
and seam keeps working, and that `new-internal-note.ps1` remains available for a repo that prefers the
two-document flow.

### Significance

#### Tier 0

The model has now run once end to end, and the seven-strings check and the history-row behaviour are recorded
as measurements rather than as expectations.

**Score:** 3

#### Tier 1

The organisation's half of a release reads as one argument instead of being assembled beside a consumer
document, and this is the first release whose cost story has an owner.

**Score:** 3

#### Tier 2

This is the document a consumer receives, and it carries the migration for a convention that moved
underneath them — including the explicit statement that nothing they have breaks.

**Score:** 4

### Pull Request

