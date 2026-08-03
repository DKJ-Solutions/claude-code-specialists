### The internal summary for v3.2.0 · Docs · 2026-08-03

**The first document in the third tier, and it is written rather than generated.** `v3.2.0` was cut before
`new-internal-note.ps1` existed, so it was the one release the "at every release" rule could not cover.
This closes that gap: the skeleton was generated from the release's own 21 entries and then filled in.

**Written to the tier's own constraints, which are stricter than they look.** The skeleton states them —
one page at most, 1-3 lines per subject, no file names, no code, and remove anything that means nothing
outside the team. Verified rather than assumed: 56 lines, zero file names, zero code fences, zero issue
numbers, and no skeleton comment blocks left behind. Those constraints are the tier: without them it grows
back into the developer notes it exists to avoid.

**What the release turned out to be about, once translated out of 21 technical titles.** Two halves. The
visible one is the rename and reorganisation, which every existing user has to act on once. The quieter and
more valuable one: work that was maintained three times is now maintained once, and four checks that
reported success without checking have been repaired — including one whose silence could switch off the
entire specialist layer without erroring.

**"What it is worth" is the middle heading and the only part no script could produce.** Four items, each in
terms of what it saves rather than what changed: maintenance paid once instead of three times; less false
confidence, which is the expensive kind, because nobody looks behind a green result; someone can now start
without help, after three separate people got stuck in the same place; and one working rule written down
that had already cost real repairs — verify a report's stated *reason* before building the fix on it.

**The open list names what a release cannot do.** The rename means every existing installation points at a
name that no longer exists, and nothing errors — it simply stops loading. That is documented rather than
fixable from this side, and it is stated as such instead of being left out because it is unflattering.
