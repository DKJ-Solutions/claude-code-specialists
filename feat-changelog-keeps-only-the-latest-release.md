### The changelog keeps the latest release, not all seventy-two · Feat · 2026-08-04

**`CHANGELOG.md` went from 1,112 to 686 lines.** The accumulating `## Releases` section held **434 of
1,062 lines — 41%** across 72 blocks that each said no more than "see the notes", and it sat on top of
the file's actual subject: what changed since the last release.

**It was not a long list but a poorer copy of a better one.** Every one of those 72 versions was already
in `releases/README.md`, with a date, a **type** and a descriptive title. Checked in both directions
before removing anything: 72 versions in each, zero in one but not the other. That measurement is the
precondition for this change — dropping blocks is only safe while the history genuinely lives elsewhere,
which is why `Get-ReleaseHistoryMode`'s own contract line says so in as many words.

**`## Latest Release` now sits ABOVE `## Pull Requests`** (Dave, during the work). When that section was
a 434-line archive, the bottom was right; holding one block, it answers "which version is current?", and
that belongs at the top with everything merged since queued beneath it. The old code **threw** unless the
release heading came second, so `Split-Changelog` was rewritten to compute both sections from their own
indices — **either order is now valid and a cut preserves the one it finds**, because no consumer's
document should be silently reordered by a release.

**The heading is recognised in both spellings, everywhere it is read.** `Split-Changelog` and the lint
gate's entry-heading scan accept `## Releases` and `## Latest Release` alike. That is a migration
guarantee rather than leniency: a repo that flips the switch still has the old heading until its next cut
rewrites it, and the throw is fatal — a reader that knew only the new spelling would break every consumer
at the least debuggable moment.

**Two new seams, both optional, both defaulting to today's behaviour:** `Get-ReleaseHistoryMode`
(`all` | `latest`) and `Get-ReleaseHistoryPath`. A consumer that sets neither gets output byte-identical
to before — asserted directly, by comparing an explicit `all` against omitting the parameter, so a later
change to the default cannot silently rewrite someone else's changelog.

**The internal-note link is a separate step, and that ordering is the whole design.** The internal note
does not exist when `cut-release.ps1` writes the changelog: that script commits **and tags** in one
motion, while the note needs the developer notes as input and lands afterwards through a PR. Linking
straight to it at cut time would put a **dead relative link inside an immutable tag** — caught by the
dead-link scan, uncorrectable after the fact. So the cut writes the developer link, which always exists,
and `new-internal-note.ps1` calls the new `Set-ReleaseInternalNoteLink` the moment the real note is
created, in the same PR that adds it. Best-effort and idempotent: a release that already succeeded must
not read as failed over a link.

**Two regressions I introduced and the suites caught, both worth naming.** The contract-completeness
guard failed on 25-where-23-was-expected — working exactly as built, so the three counts were updated
rather than loosened. And `internal-note.tests.ps1` broke because its fixture copies the script without
libs, while the script now dot-sources `release-lib.ps1`. Fixed by copying the lib into the fixture, not
by making the dot-source optional: a missing lib must fail loudly instead of silently skipping the
changelog update and leaving the release pointed at the developer notes forever.

**23 new asserts (203 → 226), and both halves shown to fail.** Disabling the order logic reddens exactly
the releases-first assert; disabling the `latest` heading reddens three. Coverage: both modes, both
orders, the pointer, and `Set-ReleaseInternalNoteLink`'s replace / idempotence / unknown-version /
leave-the-other-block-alone behaviour.

**One thing measured and deliberately not "fixed":** the migrated file showed `â€"` where em-dashes
belong. That was the console rendering of `Get-Content`, not the file — verified at 98 real em-dashes
and **zero** mojibake sequences. Repairing on the strength of the terminal would have corrupted a clean
document.
