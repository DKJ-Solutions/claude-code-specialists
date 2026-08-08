## `fix/changelog-intro-in-the-shape-gate` changelog

### Branch title

The changelog intro rejoins the shape gate

### Branch ID

20260808-175617

### Branch type

fix

### What does the change on this branch bring to main?

`CHANGELOG.md`'s introduction told four things that had stopped being true, and check 20 — the gate built
two days earlier for exactly this class — could not see any of them. Both halves are repaired here.

**The four claims.** The intro promised *three named sections* per entry where the scaffolder writes
**six**; an *impact table under "Who is this for"*, which became `#### Tier N` sub-sections under
`### Significance` on August 6; that *a release needs at least one tier-1 entry*, where tier 0 alone has
earned a patch since August 7; and that *a minor needs a tier-2 one*, where tier 1 or higher now earns it.
The last sentence followed from those rules and inverted the answer: a changelog holding nothing but tier 0
was called a changelog with no release in it, and it is a patch waiting to be cut.

**Why nobody caught it.** A cut empties this document down to its intro and carries that intro through
**verbatim**, so it is the one piece of prose in the repo that no release rewrites and no reviewer opens.
The repo had already written this lesson down — `release-lib.ps1` records being bitten by exactly it on the
per-plugin CHANGELOGs: *"the entries below the intro were history, the intro was a live statement about the
present mechanism."* Check 20 nevertheless excluded `CHANGELOG.md` whole, on the history grounds it shares
with checks 11 and 12, the day after that note was written.

**Two independent things held the intro out of reach, and repairing either alone changes nothing.** The
file was excluded, so nothing read the intro — and the pattern would have walked past the sentence anyway:
it carried no `###` marker, and it ran across a line break. So the head gets its own pass with the level
marker optional, and matching moves from per-line to whole-text.

**Both relaxations were chosen by measuring rather than by arguing**, which is what keeps the marker rule
intact where it earns its place:

| pattern, scope | claims found |
|---|---|
| strict, per line, over the scanned tree | 4 — what the check did |
| strict, whole text, over the scanned tree | **4 — identical**; the 3 extra sit in history it already excludes |
| loose, whole text, over the whole tree | 50 — the documented noise, 46 of them |
| loose, whole text, over the intro alone | **1** — the real claim, before and after the repair |

So the marker still guards ~200 files against 46 false hits and is dropped only across a dozen lines this
repo owns, where it was the whole difference between catching the drift and not. Whole-text matching
changes nothing about what the tree pass reports; it closes the blind spot where a reflowed sentence hides
a claim. Five new asserts pin both directions, including the one that matters most: the same markerless
claim **inside an entry** stays silent, because entries are history and are full of prose that was true
when it was written.

One stale comment in the same file went with it: the import header named `Build-PluginChangelogIntro` and
check 17 as the reason `release-lib` is dot-sourced, and both were retired with the per-plugin CHANGELOGs on
August 8 — a comment naming a deleted function, one day old, in the file this branch was already opening.

Plugins: none

### Significance

#### Tier 0

The intro is the first thing anyone opening `CHANGELOG.md` reads, and it was wrong about the entry's shape
*and* about what may be released — a developer following it would have expected any release to need a
tier-1 entry. It is correct now, and the gate that should have caught it does. Noticed the moment somebody
touches that file, which is every branch.

**Score:** 3

#### Tier 1

N/A — nothing here reaches beyond this repo's own developers. The document is this repo's pending list and
the gate is this repo's own lint, which is deliberately not among the scripts mirrored into the workflow
plugin.

**Score:** N/A

#### Tier 2

N/A — a consumer receives `CHANGELOG.md` in the marketplace clone, but what they read there is our pending
changes; the entry format they work from is `CONTRIBUTING.md` and the templates, both of which were measured
correct and are unchanged.

**Score:** N/A

### Pull Request

