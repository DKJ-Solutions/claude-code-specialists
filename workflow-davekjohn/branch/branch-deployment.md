## `feat/release-page-second-pass` deployment

### What does the change on this branch deploy to main?

The release-notes page gets its second editorial pass, from the four inbound issues one consumer filed
after reading the deployed page:
[#809](https://github.com/DaveKJohn/claude-code-specialists/issues/809),
[#811](https://github.com/DaveKJohn/claude-code-specialists/issues/811),
[#813](https://github.com/DaveKJohn/claude-code-specialists/issues/813) and
[#816](https://github.com/DaveKJohn/claude-code-specialists/issues/816). **They are one pass and not
four**, because #816 says so itself: dropping the type chip from the row and `**Type:**` from the note
independently would leave the newest release with no type anywhere, since `live` currently takes the
chip's cell. Every one of these interacts with at least one other.

**The index row.** The chevron moved to the trailing edge and stopped reserving a gutter -- it was `1rem`
plus a `.9rem` gap ahead of every row, and the narrow query kept both, so a 390px phone spent 9.4% of its
usable text width on a glyph where space is scarcest. The type chip now renders **only where the type
varies**, derived from the data rather than from a seam: on the reporting consumer's page it read `Minor`
38 times out of 40 and was missing from the newest row entirely. On a phone the row is three lines --
version with its chip hard right, then the title across the full width, then the date -- while **desktop
keeps one line**, which is the one judgement here rather than a request: three lines over forty releases
is a materially taller index and a 52rem measure is not short of room. And `.sheet`'s top margin now
shrinks with everything around it; its not doing so was the one plain bug in that list.

**An open note can be closed on a phone**, which was the only ask a reader could get *stuck* on rather
than merely be slowed by. An open row's summary is `position: sticky`, so the one control that closes a
`<details>` stays in reach -- median note 317 words, longest 1,018, which is one to six phone screens
between a reader and their way out. Pure CSS on purpose: the page's index reads with JavaScript off, and
the template treats that as load-bearing.

**The note stops restating the row it is inside.** Every note opens with `# Release notes vX.Y.Z`, the
date in a second format, the type, and a `**For whom:**` sentence -- measured across 40 notes, that last
one had exactly **two** distinct strings whose only difference was `--` versus an em dash. It is dropped
**on render**, not in the document: the note is read in two places and the block is only redundant in one
of them, so the markdown in the repository keeps it and the page does not. That is also the only version
of this fix that reaches the notes **already published**, which are records and are not rewritten. It is
conservative by construction -- nothing is stripped unless the body opens with an H1 naming its own
version -- and it takes the forty `article h1` elements and the rocket off a page that goes to a
commissioner.

**The version label drops a trailing `.0`, and the id never does.** A patch gets no hand-written note, so
every version this page can display ends in `.0` and the third digit is a constant. Derived from the data
rather than from `Get-ReleaseConsumerBumps`, because that seam is overridable and a repo that writes notes
for patches genuinely needs three digits -- hardcoding two would break exactly the consumer who configured
themselves differently. The `id` keeps the full semver, since it is the target of links people already
hold; the deep-link handler accepts the short spelling as well, for a reader who types what they see.

**`Get-ReleasePageMasthead`** is the new seam (#809), so a consumer can keep its own wordmark(s) above the
title. Data-URIs and base64 only -- the page is self-contained because a request to a third party leaks
who is reading it, and a raw svg payload is markup inside an attribute. Three documented ceilings, each
enforced with a **warning and never a build failure**: two marks, 32 KB each, 64 KB in total. Two rather
than five is a measurement, not a bound: the consumer's own editorial round tried five and cut back,
because five read as a page about the brands rather than about the releases.

**One thing was deliberately left alone, and it is worth naming because the suppression above walks right
past it.** With the metadata block gone, a note now opens with its own title -- the same sentence the row
above it carries. Nobody reported it, it is prose rather than a heading so it carries no visual weight,
and removing it would leave a note opening abruptly on `## What changed`. Named here rather than repaired.

The page suite went from 87 to **127 asserts**, including every way the masthead seam can be answered
wrongly, and the layout claims are asserted as CSS positions the way the palette-position assert already
was -- because what these issues are about is *where* things are, not that they exist.

**Score:** 3

#### What makes this change extra special

This page is what management and the commissioner read, and since 2026-08-21 it is the **only**
release-notes page that consumer has: the hand-edited edition that used to carry these editorial
decisions was deleted, deliberately, because a fork of the shared template in one repo is drift -- that
copy had already served pre-renumbering version numbers to management for five days. Having ended the
fork, every one of these adjustments has exactly one correct home, and this is it.

So the reader gets a shorter row to scan, a phone layout that puts the one field that differs on its own
line, a way out of a note they have finished reading, and their own wordmark back at the top. **Five of
the seven asks were subtractive** -- a word that repeated 38 times, a tenth of a phone's line, 3.5rem of
air -- which is the shape of an editorial pass rather than a feature.

**Score:** 4

### Pull Request

The release-notes page: a leaner index row, a masthead seam, and notes that stop restating their row
