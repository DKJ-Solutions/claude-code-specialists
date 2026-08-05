## Every change is an H2 with three named sections, and the tier sections are gone

### What does this change do?

`CHANGELOG.md` drops every `##` section heading. `## Latest Release` and the three
`## Tier N - Pull Requests` sections are gone; a change **is** the `##` heading now, and inside it three
`###` sections answer the questions a reader arrives with:

```text
## #475 · A significance score per entry, and the order follows it

### What does this change do?

…the description…

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 4 | … |
| 1 | 4 | … |

### Type of change

Feat

Plugins: specialists

[PR #475](https://github.com/DaveKJohn/claude-code-specialists/pull/475) · merged 2026-08-05
```

`Plugins:` and the PR line stay **plain lines**: a heading around one fact is more structure than content,
and `Plugins:` is machine-read by the cut. Dave, August 5, 2026.

**The three tier sections lasted one day, and removing them takes nothing away.** They said exactly one
thing — how far each change reaches — and since [#467](https://github.com/DaveKJohn/claude-code-specialists/issues/467)
the entries say that themselves, in a table that also carries what the change is *worth*. So what the
headings did visually is kept as the **ordering**: furthest reach first, and within a tier the highest
significance first. The fold is the only moment that order can be decided, because the cut empties the
list — whatever order the fold leaves is what the release documents inherit, with nothing re-estimated
days later.

**The release block goes entirely**, and the reason is measured rather than aesthetic. It had grown to
**434 of the changelog's 1,062 lines** across 72 blocks that each said no more than "see the notes", while
[`releases/README.md`](releases/README.md) already listed every one of those 72 versions with a date, a
type and a descriptive title — the same coverage, verified in both directions, and richer per row. The
intro now carries a one-line pointer to that page, and a cut writes nothing at all: it empties the document
down to its intro, which passes through verbatim, so whatever a repo says about itself up there survives
every cut in whatever language it wrote it.

**The release documents follow the same flat shape, and that deletion is the point.** The category grouping
is gone, with `Format-CategorizedEntries`, the category labels and the `Get-ReleaseCategoryTitles` seam. It
grouped on the **branch prefix**, which this repo has measured does not predict impact — at v3.2.0 the
single most consequential change for a consumer arrived on a `chore/` branch — so a document's most
important change was filed third under whichever label its prefix produced, and #467's ranking could only
reorder the categories, not escape them. Each change states its own type inside itself now.

Six seams retire: `Get-ChangelogTierHeadings` and the legacy `Get-ChangelogHeading` (#178) named section
headings the document no longer has; `Get-ReleaseCategoryTitles` labelled the categories;
`Get-ReleaseLiveMarker`, `Get-ReleaseHistoryMode` and `Get-ChangelogReleaseWording` (#462) all described the
release block. A consumer that still defines one is unaffected — nothing calls them. **What #462's
non-English consumer loses is stated rather than glossed over:** the capability is not withdrawn, the
*output* is gone, and what replaced it is hand-written prose in a file they own outright.

#### The two defects this found, both silent and neither reported by a test

**A consumer's release history would have been published as a "change" and then deleted.** Found by probing
a synthetic consumer while scoring this entry, not by a failing suite. Every `##` below the intro is read as
one change now, and a document still carrying the pre-flat shape has headings at exactly that level —
reached through a plugin update rather than by that repo's choosing. Measured: `## Pull Requests` parsed as
ONE entry swallowing every real entry and `## Releases` as a second, so the whole release history went
outward into the notes and the per-plugin CHANGELOGs and was then removed from `CHANGELOG.md`, because the
cut keeps only the intro. **And nothing refused** — blocks like that declare no impact, so the bump gate
read the repo as never having adopted the model and reported itself inactive, correctly by its own rule.
`Split-Changelog` now refuses before returning anything, naming each block and the migration. The
discriminator is exact rather than a heuristic: the format has two legitimate shapes and both declare
something — the three named sections, or a pre-format entry's type in its heading — while a section heading
carries neither and cannot. Deliberately not keyed on the `#NN` the fold prepends, because the fold writes a
legitimate numberless entry when `gh` is unreachable.

**The lint gate had stopped recognising entry files at all.** `Test-IsChangelogEntryFile` in
`check-plugin-integrity.ps1` still looked for `^###\s`, with a comment explaining that restating the level
rather than importing it was deliberate — importing meant dot-sourcing the fold script, which would run a
release action to answer a lint question. Sound reasoning whose conclusion went stale the moment the entry
format moved into `entry-scaffold-lib.ps1`, a pure lib that file already loads. So since the format landed,
check 13 silently judged nothing and reported clean, and check 11 stopped excluding entry files from its
scan set.

#### Five reversals the plan did not carry, all for one reason

The section heading was the thing that used to state an entry's reach.

- **The `Tier: N` line is KEPT, not consumed.** With no heading above the entry, stripping it leaves the
  entry declaring nothing, and every downstream reader takes that as tier 0 — silent, correct-looking, and
  wrong in the direction that empties a release document. `Remove-EntryTierLine`'s caller moved to the
  outward renderers instead, beside `Remove-EntryImpactTable`: the line now reaches `CHANGELOG.md`, which
  puts a self-assigned tier on the path to a consumer's plugin cache unless it is dropped there.
- **A pre-format `###` entry file is PROMOTED to `##` as it folds**, outside the PR block. An `###` in a
  flat list of `##`s is not an entry boundary, so it would be absorbed into the block above and inherit that
  block's PR link. Doing it inside the PR block — where the `#NN` prepend lives — would have skipped it
  silently for a manual merge or an unreachable `gh`. Not hypothetical: a branch parked on the remote
  carried exactly such a file.
- **`Test-EntrySignificanceActive` had to be repaired in the same commit, and this was a landmine.** It
  answered "off where there is no tier split" by counting the changelog's sections. With no sections that
  read returns one section in *every* repo, so the scaffold's table, both validators and the cut's
  significance gate would all have switched themselves **off**, without erroring, in the same commit that
  made the ranking the document's only ordering. It defaults **on** now, with `Get-EntrySignificanceEnabled`
  as the opt-out. `Test-ReleaseBumpEarned`'s `Active` flag had the same defect and now keys on whether any
  pending entry **declared** its impact — a measurement rather than a flag, and one that keeps "declared
  tier 0" distinct from "declared nothing".
- **An unscored entry sinks to the BOTTOM of its tier**, not the top. The plan and two comments said the
  top; the code was right. The loop reads an entry already in the changelog with no score as 0 and sorts it
  below everything scored at its tier, so a top-insert would rank the same entry differently on either side
  of the fold.
- **`Get-ImpactInsertOffset`'s `-Undeclared` switch is gone.** In a flat list there is no unplaced entry:
  declaring nothing is tier 0, which the loop already lands correctly.

Two refusals disappeared, both structurally rather than by relaxation: **"could not find the heading"**
(there is no heading name left to mismatch) and **"this repo declares no section for tier N"** (a tier the
repo does not use is a position, not an error).

#### And the parser recognises both shapes while the writer only writes one

These are *shared* scripts, so a consumer who adopted the tier sections would otherwise get a plugin update
whose scripts cannot read their own changelog. The **declaration** is read in both shapes (table or
`Tier: N`) and a pre-format heading's type is still recognised, because every entry in this repo's history
and in every consumer's tree predates the table and the release notes are regenerated from that history.
The **structure** is deliberately read in the new shape only: an entry's own `###` sections and a pre-format
`###` entry heading are indistinguishable, so a parser accepting both would read every entry as four. That
is what the new refusal exists to say out loud instead of guessing.

#### What was measured, not assumed

- All **26 suites** and all four gates green. `release-lib.tests.ps1` was **rewritten rather than patched**
  (353 asserts): every fixture in it was the old document shape, and the machinery varying which sections a
  repo declared tested a seam that is gone. Patching would have left a suite whose fixtures nothing writes,
  passing by looking at a document that cannot occur. Its `New-FlatEntry` helper has its own shape asserted
  before the suite uses it — this file has already paid once for a fixture that did not contain what it was
  written to contain.
- This repo's own `CHANGELOG.md` is migrated: **6 entries, not the ~25 this branch's own note predicted** —
  v3.5.0 had already been cut, which is why the repo is read rather than the note. Structural only, with
  significance cells left **empty**, because filling them in would be exactly the guessed ranking #467
  removed. Verified with the real parsers: 6 entries read back, the scored one leads, the unscored sink below
  it in arrival order, and the bump gate reports itself active.
- Two things that looked like leaks in the outward documents were a **fence-blind probe**: the only
  survivors sit inside code fences, in the entries that document the format itself, while every real
  declaration is stripped.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | a consumer whose `CHANGELOG.md` still has section headings must migrate it: measured, their release history would otherwise be published as a change and then deleted, with nothing refusing. The cut now refuses instead and names the migration, so the action is required but the failure is loud |
| 1 | 4 | every entry this team writes changes shape, and the changelog stops being three sections to scan -- noticed the same day, without being told |

### Type of change

Feat
