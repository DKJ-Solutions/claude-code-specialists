## `fix/releases-reorg-residue` changelog

### Branch title

Point four history rows at the merged audience documents and drop a dead variable

### Branch ID

20260812-220847

### Branch type

fix

### What does the change on this branch bring to main?

Two things the `releases/` reorganisation left behind, both harmless to run and both misleading to read.

**The history table in `releases/README.md` sent four readers to the wrong document.** The rows for
`3.2.0`, `3.3.0`, `3.4.0` and `3.5.0` still pointed into `development/`, where they were written before the
twelve `consumer/` + `internal/` pairs were merged into `audience/`. The Version cell is the *only* inbound
link a hand-written document has, so for those four releases the reader-facing document was unreachable
from the one page that indexes it. Repointed, and checked in the other direction rather than only the
reported one: every version that has an `audience/` document is now linked to it, and the patch rows
correctly keep pointing at `development/` — a patch writes no hand-written document, so `development/` is
the right target there and was never part of this defect.

**`$consumerFacing` in `release-lib.ps1` was assigned and read nowhere.** It counted the pending tier-2
entries, which was load-bearing while a minor *required* a tier-2 entry; the rule became "tier 1 or higher
→ minor" on August 7, 2026 and the variable did not go with it. Removed, and the reason the surviving
`$notable` counts `>= 1` instead of keying on the audience tier is now written above it — that phrasing is
what lets the same line read correctly in a tier-1 repo and a tier-2 repo without either having to
translate it.

Neither had a failure mode: a stale link resolves to a real document that is simply the wrong register for
its reader, and a dead assignment costs nothing. What they cost is the next reader's confidence, which is
why they are repaired rather than left as known-and-harmless.

### Significance

#### Tier 0

Four of the release index's own rows pointed past the reorganisation this repo carried out yesterday, and
the dead variable is the kind of thing that makes a later reader wonder which of two counters is the real
one before touching the bump rule. Both are small; both are the sort of residue that reads as a defect in
the mechanism rather than as leftovers.

**Score:** 2

#### Tier 2

The four repointed rows are the only inbound route to the documents written **for** this reader, so for
those four releases the page they were meant to read was not reachable from the index. Nothing else changes
for them: the dead variable never affected a release they received, and the documents themselves are
untouched.

**Score:** 2

### Pull Request

