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

**Step 1 done -- `fold-changelog-entry.ps1` is flat.** All 26 suites and the lint gate are green; the
fold suite was rewritten rather than patched, because its fixture machinery existed to model which
sections a consumer had declared. Five things the plan above did not say, four of them reversals:

- **The `Tier: N` line is now KEPT, not consumed.** The plan only covered the table. But the reason the
  line was ever stripped is that the *section heading* stated the tier; with no heading above the entry,
  consuming it leaves the entry declaring nothing, so every downstream reader takes it as tier 0 --
  silent, correct-looking, and wrong in the direction that empties a release document. `Remove-EntryTierLine`
  is therefore not dead: its caller **moves to the outward renderers** in step 2, alongside
  `Remove-EntryImpactTable`, because a self-assigned tier printed at a consumer is a marketing claim for
  the same reason a score is -- and the line now reaches `CHANGELOG.md`, where it never used to.
- **A pre-format `###` entry file is PROMOTED to `##` as it folds**, and the promotion happens *outside*
  the PR block. An H3 in a flat list of H2s is not an entry boundary to any reader of it, so it would be
  absorbed into the block above and inherit that block's PR link. Doing it inside the PR block -- where
  the `#NN · ` prepend lives -- would have silently skipped it for a manual merge or an unreachable `gh`.
  Not hypothetical: `docs/split-quickstart-and-adoption` is parked on the remote carrying exactly such a file.
- **`Test-EntrySignificanceActive` had to be repaired in the same commit, and this was a landmine.** It
  answered "off where there is no tier split" by counting the changelog's sections. With no sections that
  read returns a single built-in section in *every* repo -- so the scaffold's table, both validators and
  the cut's significance gate would all have switched themselves **off**, in the same commit that made the
  ranking the document's only ordering, without erroring. It now defaults **on** with
  `Get-EntrySignificanceEnabled` as the opt-out. **`Test-ReleaseBumpEarned`'s `Active` flag in
  `release-lib.ps1` has the same defect and is step 2's** -- it keys off the same retired map.
- **An unscored entry sinks to the BOTTOM of its tier**, not the top. The plan's wording and two comments
  said the top; the code was right. The loop already reads an entry *already in* the changelog with no
  score as 0 and sorts it below everything scored at its tier, so a top-insert would rank the same entry
  differently on either side of the fold. Nothing is buried: `open-pr` reports it and the cut refuses by name.
- **`Get-ImpactInsertOffset`'s `-Undeclared` switch is gone.** In a flat list there is no unplaced entry:
  declaring nothing is tier 0, which the loop already lands correctly. Keeping a switch no caller passes
  would have preserved the wrong answer for whoever reached for it next.

Two refusals also disappeared, and both are structural rather than relaxed: **"could not find the
heading -- stopping"** (there is no heading name left to mismatch) and **"this repo declares no section
for tier N"** (a tier the repo does not use is a position, not an error).

**Known intermediate state, deliberately not guarded:** this repo's own `CHANGELOG.md` still has
`## Latest Release` and the three tier sections until step 4, so a fold run right now would place the
entry above `## Latest Release`. That is contained by the branch -- nothing is folded mid-development,
and steps 2-4 land in the same PR -- so it needs no code, only that step 4 is not skipped.

**Still to do, in this order:**

1. `release-lib.ps1` -- `Split-Changelog` (no sections; entries are the `##` blocks below the
   intro), `Get-PullRequestEntriesByTier` (the tier comes from each entry's impact table, not from
   a section heading), `Convert-ChangelogForRelease` (remove the entry blocks, keep the intro,
   write no release reference), a flat ranked renderer replacing `Format-CategorizedEntries`, the
   four `Build-*` functions, and `Convert-EntryHeadingToTitle` (drop only the `#NN` field).
2. `cut-release.ps1`, `scripts/repo-config.ps1` (`Get-ChangelogTierHeadings` retires),
   `check-script-contract.ps1`, and the `[entry-heading]` + `[changelog-intro]` lint checks.
3. Migrate this repo's own `CHANGELOG.md` -- roughly 25 pending entries. Structural only: headings,
   the type section, and the tier taken from the section each entry currently sits in. **Leave the
   significance cells empty.** Filling them in would be exactly the guessed ranking #467 removed;
   the next cut will ask, and `-SkipSignificanceGate` is the escape valve if a release is wanted
   before then. **Dave sees this one before it runs** (his instruction, August 5, 2026).
4. `CLAUDE.md`, `CONTRIBUTING.md` and the `new-branch` / `open-pr` / `cut-release` skills.
5. Tests: `agent-shared`, `bootstrap-drift`, `entry-scaffold`, `fix-mojibake`, `fold-changelog`,
   `new-branch` and `shared-scripts` were red by construction and are green again as of step 1. The
   remaining coverage is for the flat renderer and `Split-Changelog`'s section-less parse.

**Three bugs already made here, all now commented at the site -- do not reintroduce them.** The
comma operator binds looser than string concatenation, so `@('## ' + $title, '')` concatenates the
string with an *array* and joins it with a space: a heading with a trailing space and no blank line
after it, which is well-formed markdown and therefore invisible. Treating a declared tier 0 as
"declared nothing" sent repo-internal work to the **top** of the list. And the insert-offset test
fixture was left at `###` after the function's `$EntryPattern` default moved to `##`, so it had no
entry boundaries at all and every offset silently became "the end" -- four asserts went red at once,
which is the loud version of a failure that in the real document is one entry quietly appended at
the bottom.

**Before the PR:** replace this whole block with what the change does, and confirm the impact table
below -- the tier is certain, the scores are this note's author's estimate and the finisher owns them.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | a consumer's newly written entries get the new shape while their existing document still has tier sections, so they have a mixed document to resolve -- nothing breaks, because the parser reads both, but the resolving is theirs to do |
| 1 | 4 | every entry this team writes changes shape, and the changelog stops being three sections to scan -- noticed the same day, without being told |

### Type of change

Feat
