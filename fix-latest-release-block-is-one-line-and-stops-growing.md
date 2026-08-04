### The latest-release block loses its redundant heading and stops accumulating blank lines · Fix · 2026-08-04

**Both defects came out of a `-NoPush` cut of v3.4.0 and were repaired before anything was tagged** —
which is the entire argument for that flag. The release was assembled, inspected, discarded locally
(nothing had been pushed), and cut again after the fix.

**A `###` heading under `## Latest Release` names what the heading above it already said.** The section
holds exactly one release by construction, so a per-version heading is an empty level of structure. The
version moves onto a bold line — `**v3.4.0** — 2026-08-04 — Minor` — which reads the same and drops the
level. In `all` mode the heading stays, because there the blocks genuinely stack and each one needs its
own.

**`Set-ReleaseInternalNoteLink` now matches both shapes**, and that is not defensive coding. It is the
function that repoints the changelog at the internal note, and if it and `Convert-ChangelogForRelease`
ever disagree about where a block starts, **it fails silently**: the cut succeeds, the note is written,
and the link simply never moves. Asserted against the real generator output rather than a hand-typed
block, so the two cannot drift apart on paper either.

**The blank line above the first section grew by one at every cut.** Measured over three consecutive
cuts: **2, 3, 4.** `Split-Changelog` returns a head that already ends with the blank separating it from
the first heading, and the builder added its own. It renders identically in markdown, which is precisely
why it would have gone on growing — nothing looks wrong until someone opens the raw file years later.
The head is now trimmed of trailing blanks before the sections are joined.

**The negative control is why this entry can claim anything.** Run with the trim disabled, the new
assertion **passed** — it was measuring the gap above `## Latest Release` while the fixture is PR-first,
so it was watching a gap the builder never touches. A test that only ever ran green would have shipped
looking like coverage. It now measures above whichever section comes first, and with the fix disabled it
goes red; disabling the heading change reddens four more.

**231 asserts, up from 226.**
