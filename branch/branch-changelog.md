## `docs/a-release-note-cannot-time-its-own-publication` changelog

### Branch title

The release note carries its own total, and step 0a says where each half goes

### Branch ID

20260811-105337

### Branch type

docs

### What does the change on this branch bring to main?

**Step 0a asked for a number the release note structurally cannot contain, and running it once was what
exposed that.** The instruction said: note the clock before the cut, note it again when the Release is
published, write the end-to-end duration into the release document's organisational section. All three
halves are right and the combination is impossible — the note is frozen for its own pull request at step 4,
and the Release is published at step 5, so while the timing section is being written its CI gate, its merge
and the publish are all still running on that very file.

**The size of the gap is the argument.** At `v4.4.0` the subtotal available at freeze was **9m 42s** of a
release that came to **28m 03s**: the unmeasurable tail was **two thirds**. A document carrying only the
first pass is not slightly incomplete, and the predictable failure is that whoever writes it fills the gap
with an estimate — in the one section whose entire point is that the figure was measured rather than felt.

**So the step is two passes now, and the second one is expected rather than exceptional.** At step 4 the
document gets the clock start, the legs already readable off timestamps, the subtotal to freeze, and which
of them blocked a person — the half that cannot be recovered later. After step 5 the total is added in its
own small pull request, together with the three legs the first pass could not see. This branch *is* that
second pass for `v4.4.0`, which is why the number it adds is a measurement and not a worked example.

**Two wrong repairs are refused by name, because both suggest themselves before the right one.** Publishing
the Release earlier would make the total writable in one pass and would put the page up before its
attachments exist, which is exactly what step 5's ordering is for — the tail of a release is cheap to
measure twice and expensive to publish twice. And letting the total live only in the closing report to the
requester is refused too: a chat message is not where the next person looks for what a release costs, which
is the whole reason the number was asked for in a document.

**The measurement itself lands in three places, each for a different reader.** The v4.4.0 note gets the full
leg table and the 56% gate share; [Nolan #25](.claude/specialists/lenses/06-25-extension.md)'s first
outstanding number is answered with both cautions attached — that release carried two entries against
`v4.2.0`'s seven, so it measures the clock well and the writing gain not at all, and 28m 03s **confirms** the
~30 min everyone had been reasoning about rather than improving on it; and
[Rendall #06](.claude/specialists/lenses/05-06-extension.md)'s clock paragraph learns that noting the time is
a two-pass job for him specifically.

### Significance

#### Tier 0

The repo's most-repeated expensive procedure has a complete measured duration for the first time — 28m 03s,
56% of it gates, all of it blocking — and the instruction that produces it no longer asks for something
impossible.

**Score:** 4

#### Tier 1

An improvement cycle that could not state its result in the asked-for unit now has a figure that can be
compared against the next one, with the two conclusions it does *not* license written down beside it.

**Score:** 3

#### Tier 2

The corrected step travels: a consuming repo following step 0a would have hit the same impossibility, filled
it with an estimate, and had no way to tell that two thirds of the number was guessed.

**Score:** 3

### Pull Request
