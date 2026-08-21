## `feat/release-page-second-pass` deployment

### What does the change on this branch deploy to main?

The release-notes page gets its second editorial pass, from the four inbound issues one consumer filed
after reading the deployed page:
[#809](https://github.com/DaveKJohn/claude-code-specialists/issues/809),
[#811](https://github.com/DaveKJohn/claude-code-specialists/issues/811),
[#813](https://github.com/DaveKJohn/claude-code-specialists/issues/813) and
[#816](https://github.com/DaveKJohn/claude-code-specialists/issues/816). **They are one pass and not
four**, because #816 says so itself: dropping the type chip from the row and `**Type:**` from the note
independently would leave the newest release with no type anywhere, since `live` takes the chip's cell.

**The row is now a version, a date, and at most one chip.** The title left the summary altogether and
lives in the note (Dave, reading the built page), which is what retired two things the first draft
carried: the three-row phone layout #811 asked for existed *because* the title was the longest field, and
the chip had to be written as two spans with one hidden by CSS *because* a grid cannot move an inline
child of one cell into another. With no title cell, the whole row is about 16rem of a 390px phone's
20rem, so it fits on one line at every width and the chip is one span in the flexible column. The title
still travels, as the row's `title` attribute -- a summary of a version and a date is thin for anyone
navigating by control, and there it costs no width.

The chevron moved to the trailing edge and stopped reserving a gutter -- `1rem` plus a `.9rem` gap ahead
of every row, which the narrow query kept, so a phone spent 9.4% of its usable text width on a glyph
where space is scarcest. `.sheet`'s top margin now shrinks with everything around it; its not doing so
was the one plain bug in that list. And the version reads **`Version 4.17`** rather than `v4.17`: the
short form is developer shorthand, and this page's reader is management and the commissioner, for whom a
lone `v` is a convention they have no reason to know. That costs width in the column that had just been
narrowed, so the column is a stated `6.5rem` the label cannot outgrow silently.

**The type chip marks what is UNUSUAL, and the first version of this rule shipped nothing.** It was built
as "render it where the type varies", which reads exactly like #811's wording -- and that page has two
distinct types, so a variance test answers *varies* and leaves all 39 chips where they were. The report's
figure was **38 of 40**, not "two values"; a boolean distinctness test is the wrong measurement of it.
Caught by Dave reading the built page and asking why the label was still there. The rule now suppresses
the chip on every row carrying the page's most common type and keeps it where a row differs -- which is
the rule the `live` chip already follows, its absence meaning "not live". One row in forty saying
`Baseline` tells a reader something; thirty-nine agreeing with each other do not. Measured on this repo's
own page: **27 chips became 1.**

**Both halves of reading a note now work on a phone.** An open row's summary is `position: sticky`, so the
one control that closes a `<details>` stays in reach -- median note 317 words, longest 1,018, which is one
to six phone screens between a reader and their way out. And **closing puts the reader back on the row
they opened**: without that, the document has just got several screens shorter and they land in the middle
of the index with no idea which row was theirs. Only when the row has scrolled off the top, and instantly,
because this restores a position rather than travelling to a new one. The sticky half is pure CSS so the
index keeps reading with JavaScript off; the scroll half is an enhancement in a script that already
renders the note bodies.

**The note stops restating the row it is inside.** Every note opens with `# Release notes vX.Y.Z`, the date
in a second format, the type, and a `**For whom:**` sentence -- measured across 40 notes, that last one had
exactly **two** distinct strings whose only difference was `--` versus an em dash. It is dropped **on
render**, not in the document: the note is read in two places and the block is redundant in only one, so
the markdown in the repository keeps it and the page does not. That is also the only version of this fix
that reaches the notes **already published**, which are records and are not rewritten. Conservative by
construction -- nothing is stripped unless the body opens with an H1 naming its own version -- and it takes
forty `article h1` elements and a rocket off a page that goes to a commissioner.

**`## For consumers` became `## What changed`, at both tiers** (Dave). A heading that names its reader
tells that reader nothing they do not already know, and the section *below* it does name a reader -- on
purpose, because that one is the half the audience section may not contain. This finishes
[#747](https://github.com/DaveKJohn/claude-code-specialists/issues/747) rather than undoing it: that
finding was that `For consumers` names the wrong reader in a tier-1 repo, and both tiers answering the
same thing is what lets the key stop being tier-dependent at all. **Notes already published keep the
heading they were written with.**

**The version label drops a trailing `.0`, and the id never does.** A patch gets no hand-written note, so
every version this page can display ends in `.0` and the third digit is a constant. Derived from the data
rather than from `Get-ReleaseConsumerBumps`, because that seam is overridable and a repo writing notes for
patches genuinely needs three digits. The `id` keeps the full semver, since it is the target of links
people already hold; the deep-link handler accepts the short spelling as well.

**`Get-ReleasePageMasthead`** is the new seam (#809), so a consumer can keep its own wordmark(s) above the
title. Data-URIs and base64 only -- the page is self-contained because a request to a third party leaks
who is reading it, and a raw svg payload is markup inside an attribute. Three documented ceilings, each
enforced with a **warning and never a build failure**: two marks, 32 KB each, 64 KB in total. Two rather
than five is a measurement: the consumer's own editorial round tried five and cut back, because five read
as a page about the brands rather than about the releases.

The page suite went from 87 to **134 asserts**, including every way the masthead seam can be answered
wrongly and a pin on the chip rule that the variance test would fail -- so the version that fixed nothing
cannot come back looking like a simplification.

**Score:** 3

#### What makes this change extra special

This page is what management and the commissioner read, and since 2026-08-21 it is the **only**
release-notes page that consumer has: the hand-edited edition that used to carry these editorial decisions
was deleted, deliberately, because a fork of the shared template in one repo is drift -- that copy had
already served pre-renumbering version numbers to management for five days. Having ended the fork, every
one of these adjustments has exactly one correct home, and this is it.

So the reader gets a row that carries only what differs between releases, a version number written the way
a non-developer reads one, a way out of a note they have finished, and a page that puts them back where
they were when they close it. **Most of the pass was subtractive** -- a word that repeated 38 times, a
tenth of a phone's line, 3.5rem of air, a title printed twice -- which is the shape of an editorial round
rather than a feature.

**Score:** 4

### Pull Request

The release-notes page: a leaner index row, a masthead seam, and notes that stop restating their row
