## An entry heading is just the title -- the PR number lives on the closing line

### What does this change do?

**This entry's own heading is the specimen: it carries no `#NN`.** The fold used to prepend `#NN · ` to the
title; it no longer writes into the heading at all. Dave, August 5, 2026.

**Nothing is lost, which is why it could go.** The number is still in the entry, on the closing
`[PR #NN](url) · merged <date>` line, where the url makes it clickable rather than merely printed. The two
facts the merge owns already had a home together at the end of the block — the number was the last one still
stated twice. What the heading gains is being readable as a sentence, and it is the one line every reader of
`CHANGELOG.md` and of all three release documents scans.

The ten entries already folded are migrated in the same change, by a script that skips fenced illustrations
so the entry documenting the older shape keeps its example intact.

#### The number was load-bearing in one reader, and that reader was already broken

**`new-internal-note.ps1` recognised an entry by counting middot fields in its heading** — `≥ 3`, with the
type taken from the second-to-last. The flat format had already taken those fields away one at a time (the
merge date to the closing line, then the type into its own section), so at two fields **every real entry
fell below the threshold**. Removing the number would have made it one field, but the damage predates this
change.

**Measured against a note generated from the live changelog, before rewriting anything: 46 headings skipped,
all ten entries among them — and the one heading that still matched the old shape was a QUOTED example
inside a fenced code block in an entry body,** which became the note's only bullet, with the illustration's
own words as its type. A document written for colleagues, listing one line that describes nothing. No error,
plausible output, and a warning that said the opposite of what had happened.

**So the recogniser is structural now:** a heading is an entry when the headings **one level below it**,
inside its own block, include one of the format's named sections. That is level-independent by construction,
which matters because the level genuinely differs per document — entries sit at H3 under the tier headings
and at H2 in the untiered shape — and it cannot confuse a heading with its container, since one level below
a tier heading are entry headings and one level below the H1 are tier headings. The type comes from
`Resolve-EntryType`, the title from `Convert-EntryHeadingToTitle`, and the walk is fence-aware — which is
what stops a quoted example from ever becoming a bullet again.

**The pre-format shape is still recognised**, by the metadata triple, because this script takes a *version*
and reads that release's notes off disk: it can be run against any release ever cut, and every note written
before the named sections existed has entries without them. Two independent guards keep the fabricated
bullet from coming back — the fence awareness, and a requirement that the type field be a type the branch
table actually produces (the illustration's second-to-last field was a *title*, so it fails that test even
without the fence).

#### Two latent defects the work surfaced, both silent

**`Set-EntryHeadingLevel` computed its shift as `$EntryLevel - <canonical>`** — the shift a block *already*
at the canonical level needs, which is true of every caller that reads entries straight out of
`CHANGELOG.md`, and false for the one that reads them back out of a rendered document. Normalising a deeper
block **to** canonical therefore computed a delta of zero and returned it untouched. Its own docstring
promises "so the entry's own heading sits at `$EntryLevel`", which is what it now does: the delta is
measured from the block. The visible symptom was every internal-note bullet losing its type, because the
block handed to the type reader had never been shifted and its sections were still one level below where
that reader looks.

**`Resolve-EntryType` conflated recognition with validation.** Both used `Get-BranchTypes` and nothing else,
so where that function is absent the known-type list was **empty** — right for validation (a repo with no
table of its own has nothing to judge a type against) and wrong for recognition (with no list, no heading
field can be identified as the type at all). `branch-info.ps1` is repo-owned and deliberately does not
travel into the plugin mirror, so **the absent case is the ordinary one in a consumer**: every bullet taken
from a historical heading lost its type there, silently. Recognition now uses `Get-ReleaseChangeTypes`,
which probes the repo's table and falls back to the canonical four; validation still only fires where the
repo's own table is reachable.

`Get-ReleaseChangeTypes` moved down into `entry-scaffold-lib.ps1` for that, the same way and for the same
reason the fence reader did one PR earlier: two of its readers live there and the dependency can only run
downward. It kept its name, so no call site changed.

#### What was measured, not assumed

- All **26 suites** and all four gates green.
- **The internal-note suite had no fixture in the current format** — every one of its scenarios was the
  pre-flat shape, and they all passed, which is exactly why nobody noticed the recogniser had stopped
  finding anything. One was added, built to match what the real renderer writes, and it asserts the
  fabricated bullet cannot return.
- The `Set-EntryHeadingLevel` repair is asserted as a **lossless round trip** (canonical → deeper →
  canonical), because the read-back direction is the one that silently did nothing.
- The migration was verified with the real parsers: 10 entries, ranking unchanged, every type still read,
  and **11 closing lines still carrying a PR link** — the ten entries plus the fenced illustration.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 4 | a consumer's next internal note stops silently losing its bullets, and where it found any it stopped losing their type -- both were broken before this and neither reported anything; their changelog headings also get shorter, which they see the first time they fold |
| 1 | 3 | the one line everybody scans in four documents now says what changed and nothing else -- a clear improvement, noticed the moment you open the changelog |

### Type of change

Feat
