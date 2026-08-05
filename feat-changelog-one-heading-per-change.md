## Every change is an H2 with named sections, and the tier sections are gone

### What does this change do?

**To do / where I left off:**

CHANGELOG.md drops every `##` section heading. `## Latest Release` and the three
`## Tier N - Pull Requests` sections are gone; a change **is** the `##` heading now
(`## #475 · A significance score per entry`), and inside it three `###` sections answer the
questions a reader arrives with. Dave, August 5, 2026.

**The four design decisions are settled** (Dave, August 5, 2026) and must not be re-litigated:

1. **The release block goes entirely.** `releases/README.md` is the only list of releases; the
   intro paragraph carries a one-line pointer to it. The measured reason it can go: the
   accumulating section was 434 of 1,062 lines and every row said no more than "see the notes",
   while `releases/README.md` already had the same coverage and richer rows.
2. **One flat list, ordered tier desc -> significance desc -> newest first.** That keeps what the
   three tier sections communicated visually -- consumer-facing work leads, repo-internal sinks --
   as an ordering rather than as structure.
3. **Three `###` sections**: `What does this change do?`, `Who is this for` (the impact table --
   it *is* the answer, not prose beside it), `Type of change`. `Plugins:` and the
   `[PR #NN](url) · merged <date>` line stay **plain lines**, because a heading around one fact is
   more structure than content, and `Plugins:` is machine-read by the cut.
4. **The release documents follow the same flat shape.** The category grouping goes, and with it
   most of `Format-CategorizedEntries`, `Get-ReleaseCategories` and the
   `Get-ReleaseCategoryTitles` seam. That is a large deletion, and it is intended.

**And one decision taken while building, which follows a rule this repo already has:** the parser
recognises **both** shapes while the writer only writes the new one. These are *shared* scripts, so
a consumer who adopted the tier sections would otherwise get a plugin update whose scripts cannot
read the consumer's own changelog. Recognise both, write one.

**Done and committed (`4932f37`), verified by hand:**

- `entry-scaffold-lib.ps1` -- the H2/H3 levels, the three repo-owned section headings (seam
  `Get-EntrySectionHeadingOverrides`), `Get-EntrySectionBody`, `Resolve-EntryType`,
  `Format-EntryBlock`.
- `Resolve-EntryType` falls back to the type as a middot field in the heading, so every entry
  already written stays readable.
- `new-changelog-entry.ps1` writes the new shape. The section structure is **unconditional** now;
  `Test-EntrySignificanceActive` governs only the gates, because two entry shapes in one system
  would need both paths in every reader forever.
- `Get-ImpactInsertOffset` ranks on (tier, significance), with `-Undeclared` kept separate from a
  declared tier 0.

**Still to do, in this order:**

1. `fold-changelog-entry.ps1` -- entry files open with `##` now (recognise `###` too), insert into
   the flat list via `Get-ImpactInsertOffset`, drop the tier-section lookup entirely. The table is
   no longer stripped when unscored: `### Who is this for` demands content, so a tier-0 entry keeps
   its `| 0 | - | - |` row. The `#NN · ` prepend moves from `^### ` to `^## `.
2. `release-lib.ps1` -- `Split-Changelog` (no sections; entries are the `##` blocks below the
   intro), `Get-PullRequestEntriesByTier` (the tier comes from each entry's impact table, not from
   a section heading), `Convert-ChangelogForRelease` (remove the entry blocks, keep the intro,
   write no release reference), a flat ranked renderer replacing `Format-CategorizedEntries`, the
   four `Build-*` functions, and `Convert-EntryHeadingToTitle` (drop only the `#NN` field).
3. `cut-release.ps1`, `scripts/repo-config.ps1` (`Get-ChangelogTierHeadings` retires),
   `check-script-contract.ps1`, and the `[entry-heading]` + `[changelog-intro]` lint checks.
4. Migrate this repo's own `CHANGELOG.md` -- roughly 25 pending entries. Structural only: headings,
   the type section, and the tier taken from the section each entry currently sits in. **Leave the
   significance cells empty.** Filling them in would be exactly the guessed ranking #467 removed;
   the next cut will ask, and `-SkipSignificanceGate` is the escape valve if a release is wanted
   before then.
5. `CLAUDE.md`, `CONTRIBUTING.md` and the `new-branch` / `open-pr` / `cut-release` skills.
6. Tests: seven suites are red on this branch **by construction** (`agent-shared`,
   `bootstrap-drift`, `entry-scaffold`, `fix-mojibake`, `fold-changelog`, `new-branch`,
   `shared-scripts`), because the writer produces the new shape while the fold and the renderers
   still expect the old one. Plus new coverage for the section parser and the flat renderer.

**Two bugs already made here, both now commented at the site -- do not reintroduce them.** The
comma operator binds looser than string concatenation, so `@('## ' + $title, '')` concatenates the
string with an *array* and joins it with a space: a heading with a trailing space and no blank line
after it, which is well-formed markdown and therefore invisible. And treating a declared tier 0 as
"declared nothing" sent repo-internal work to the **top** of the list.

**Before the PR:** replace this whole block with what the change does, and confirm the impact table
below -- the tier is certain, the scores are this note's author's estimate and the finisher owns them.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | a consumer's newly written entries get the new shape while their existing document still has tier sections, so they have a mixed document to resolve -- nothing breaks, because the parser reads both, but the resolving is theirs to do |
| 1 | 4 | every entry this team writes changes shape, and the changelog stops being three sections to scan -- noticed the same day, without being told |

### Type of change

Feat
