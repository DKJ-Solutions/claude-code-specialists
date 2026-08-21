## `feat/release-page-second-pass` deployment

### What does the change on this branch deploy to main?

The release-notes page gets its second editorial pass. It began as the four inbound issues one consumer
filed after reading the deployed page --
[#809](https://github.com/DaveKJohn/claude-code-specialists/issues/809),
[#811](https://github.com/DaveKJohn/claude-code-specialists/issues/811),
[#813](https://github.com/DaveKJohn/claude-code-specialists/issues/813),
[#816](https://github.com/DaveKJohn/claude-code-specialists/issues/816) -- taken as **one pass and not
four**, because #816 says so itself: dropping the type chip from the row and `**Type:**` from the note
independently would leave the newest release with no type anywhere. It then went through eight rounds of
Dave reading the built page, and two of those **replaced** an answer rather than adding one, which is the
part worth keeping.

**The masthead says one thing per line.** The eyebrow carries the product name and the heading says
`Release notes` -- the other way round from how it shipped, where the product name was the `h1` over a
hardcoded eyebrow, so a repo whose title said what the page was printed those words twice. This repo's own
answer did exactly that. `Get-ReleasePageTitle` therefore answers **whose** releases the page carries, not
what it is, and all four layers that document it now say so. The window title joins the two, where a tab
has no duplication to make because it shows one line.

**The row carries only what differs between releases**: the version, the date, and at most one chip. The
title left the summary and lives in the note, which retired two things the first draft carried -- the
three-row phone layout #811 asked for existed *because* the title was the longest field, and the chip had
to be written as two spans with one hidden by CSS *because* a grid cannot move an inline child of one cell
into another. With no title cell the row fits on one line at every width. The title still travels as the
row's accessible name, where it costs no width.

**The chevron moved to the trailing edge** and stopped reserving a gutter -- `1rem` plus a `.9rem` gap
ahead of every row, which the narrow query kept, so a phone spent 9.4% of its usable text width on a glyph
where space is scarcest. **The version column hugs its content** rather than carrying a stated width: it
was `4.25rem`, then `6.5rem` once the label became `Version 2.39`, and a number that has to be raised
whenever the label grows is one that will one day be too small without saying so. That removed the last
magic number with it -- the note used to be indented to line up with a title column that no longer exists,
so it starts at the row's own left edge now, with its breathing room as padding on the article rather than
as the first paragraph's margin, so it does not depend on whether a note opens with a paragraph, a heading
or a list. **And `.sheet`'s top margin is gone rather than made responsive**, which is how #811's ask 6 was
answered in the end: `2rem` over the masthead's own `1.5rem` of bottom padding was 3.5rem of air above a
list, and that padding is the separation.

**The version reads `Version 4.17`** rather than `v4.17`: the short form is developer shorthand and this
page's reader is management and the commissioner, for whom a lone `v` is a convention they have no reason
to know. It still drops a trailing `.0` where every release on the page has one (#813) -- a patch gets no
hand-written note, so the third digit is a constant -- derived from the data rather than from
`Get-ReleaseConsumerBumps`, because that seam is overridable and a repo writing notes for patches
genuinely needs three digits. **The `id` keeps the full semver**, since it is the target of links people
already hold, and the deep-link handler accepts the short spelling too.

**The chip marks what is UNUSUAL, and the first version of this rule shipped nothing.** It was built as
"render it where the type varies", which is #811's own wording -- and that page has two distinct types, so
a variance test answers *varies* and leaves all 39 chips exactly where they were. The report's figure was
**38 of 40**, not "two values". Caught by Dave asking why the label was still there. The rule now
suppresses the chip on every row carrying the page's most common type and keeps it where a row differs,
which is the rule the `live` chip already follows -- its absence meaning "not live". Measured here:
**27 chips became 2**, one `LIVE` and one `Major`.

**`LIVE` falls back to the newest release** where the history table marks none, and the marker still wins
where there is one -- in a Shopify repo the live theme is genuinely not always the latest cut, which is
why that marker exists. Derived rather than marked because a marker has to be moved by hand at every cut,
in a file the cut itself writes into: right on the day it is set, silently wrong at the next release. The
cost is stated in the code: a repo whose live version is older and which never marked it now gets a label
that is wrong where before it got none, and marking the row is the override that stops the derivation.

**Both halves of reading a note work on a phone now.** An open row's summary is `position: sticky`, so the
one control that closes a `<details>` stays in reach -- median note 317 words, longest 1,018, which is one
to six phone screens between a reader and their way out. And **closing puts the reader back on the row they
opened**: without it the document has just got several screens shorter and they land in the middle of the
index with no idea which row was theirs. Only when the row has scrolled off the top, and instantly, because
this restores a position rather than travelling to a new one. The sticky half is pure CSS so the index keeps
reading with JavaScript off; the scroll half is an enhancement in a script that already renders the bodies.

**The note stops restating the row it is inside** (#816). Every note opens with `# Release notes vX.Y.Z`,
the date in a second format, the type, and a `**For whom:**` sentence -- measured across 40 notes, that
last one had exactly **two** distinct strings whose only difference was `--` versus an em dash. It is
dropped **on render**, not in the document: the note is read in two places and the block is redundant in
only one, so the markdown in the repository keeps it and the page does not. That is also the only version
of this fix that reaches the notes **already published**, which are records and are not rewritten.
Conservative by construction -- nothing is stripped unless the body opens with an H1 naming its own version
-- and it takes forty `article h1` elements and a rocket off a page that goes to a commissioner.

**`## For consumers` became `## What changed`, at both tiers.** A heading that names its reader tells that
reader nothing they do not already know, and the section *below* it does name a reader -- on purpose,
because that one is the half the audience section may not contain. This finishes
[#747](https://github.com/DaveKJohn/claude-code-specialists/issues/747) rather than undoing it: that
finding was that `For consumers` names the wrong reader in a tier-1 repo, and both tiers answering the same
thing is what lets the key stop being tier-dependent at all. **Notes already published keep the heading
they were written with**, so the page shows the new wording from the next cut onward and the old wording
above it. Renaming a generated heading at render time was considered and left out of this branch.

**`Get-ReleasePageMasthead`** is the new seam (#809), so a consumer can keep its own wordmark(s) above the
title. Data-URIs and base64 only -- the page is self-contained because a request to a third party leaks who
is reading it, and a raw svg payload is markup inside an attribute. Three documented ceilings, each
enforced with a **warning and never a build failure**: two marks, 32 KB each, 64 KB in total. Two rather
than five is a measurement: the consumer's own editorial round tried five and cut back, because five read
as a page about the brands rather than about the releases.

The page suite went from 87 to **143 asserts**, including every way the masthead seam can be answered
wrongly and a pin on the chip rule that the retired variance test would fail -- so the version that fixed
nothing cannot come back looking like a simplification.

**Score:** 3

#### What makes this change extra special

This page is what management and the commissioner read, and since 2026-08-21 it is the **only**
release-notes page that consumer has: the hand-edited edition that used to carry these editorial decisions
was deleted, deliberately, because a fork of the shared template in one repo is drift -- that copy had
already served pre-renumbering version numbers to management for five days. Having ended the fork, every
one of these adjustments has exactly one correct home, and this is it.

So the reader gets a row that carries only what differs between releases, a version number written the way
somebody who is not a developer reads one, a masthead where each line says one thing, a way out of a note
they have finished, and a page that puts them back where they were when they close it. **Most of the pass
was subtractive** -- a word that repeated 38 times, a tenth of a phone's line, 3.5rem of air, a title
printed twice, three magic numbers -- which is the shape of an editorial round rather than a feature.

**Score:** 4

### Pull Request

The release-notes page: a leaner index row, a masthead seam, and notes that stop restating their row
