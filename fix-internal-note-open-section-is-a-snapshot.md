### The internal note's open section is a snapshot, because it is published · Fix · 2026-08-04

**Three instances in one day is a structural problem, not three editing mistakes.** Making the internal
note the GitHub Release body turned it from an archive document into published output — and its third
heading, *"What is still open"*, is written in the present tense about a moment that passes. All three
went stale within hours of being written:

1. A line saying the user-facing notes still needed an editorial pass — they were edited hours later.
2. A line pointing at "the notes **attached to** that release" — that release had no Release, so no
   attachment.
3. A line stating the previous release had no public page — published minutes before it got one, by the
   same session.

None were wrong when written. That is the whole point: a present-tense claim in an immutable document has a
shelf life measured in hours, and correcting each one as it surfaces is a treadmill.

**So the heading changed rather than the lines.** It now reads **"What was still open at this release"** —
past tense, naming the release. That makes the section a snapshot by construction, so the same sentences
stay true indefinitely. The skeleton hint says so explicitly and carries the measurement, because a writer
who does not know the document gets published will reach for the present tense every time.

**The default changed, not this repo's override.** The wording lives in `new-internal-note.ps1`'s defaults
and is overridable per repo through `Get-InternalNoteWording` — so this reaches every consumer, and a repo
that has translated the headings keeps its own. The script is mirrored, so both copies moved and were
verified byte-identical.

**Two existing notes were brought in line**, since both are now published Release bodies: `v3.2.0` (heading
only — its content was still accurate) and `v3.3.0` (heading plus the stale line about the previous
release, which now says it had none *at the moment this was written* and has one now).

**Tests: 54 asserts, up 2, and one of them is a negative on purpose.** The old present-tense heading must
**not** appear — it is the natural thing to type back in, and a positive assert alone would not notice.
The second checks the skeleton hint still tells the writer to write a snapshot. One thing learned while
writing them: `Test-Line` in that suite is a **whole-line** matcher (`(?m)^…\r?$`, built that way because
the skeleton is CRLF), so a mid-line substring assert must not use it — the first version of the hint
assert failed for that reason and not because of the code it was testing.

**The half that no rule can carry** is stated in the release manager's lens: re-read the *previous*
release's note whenever something it called open closes. The development notes and the highlights need no
such pass — they are written once and left alone. This tier is the only one that acquired a reason to be
revisited, and it acquired it yesterday.
