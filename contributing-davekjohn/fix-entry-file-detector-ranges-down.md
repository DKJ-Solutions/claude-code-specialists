## fix/entry-file-detector-ranges-down

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### The defect (issue #1344)

Both copies of `Test-IsChangelogEntryFile` build their level range as `entry level .. entry level + 1`.
Since the August 26, 2026 shift `Get-EntryHeadingLevel` is 3, so that range is `^#{3,4}\s` -- it
recognises the current H3 shape and an H4 nothing has ever written, and misses the **flat-window H2**
shape every entry written between August 5 and 26, 2026 carries. `Test-BranchChangelogIsFilled` took the
other direction on that same day (`entry level - 1 .. entry level`, `^#{2,3}\s`), so two functions
answering "is this an entry file" disagree. Cost: fold-all mode skips an H2 entry file silently, and
check 13 (`[entry-heading]`) plus the unfolded-entry count in `check-plugin-integrity.ps1` do not see it.

#### Scope boundary

The stale PROSE about these levels is #1341's (parked on `fix/stale-heading-facts-in-scripts`). This
branch is the behaviour half only: the range direction, the comments that state it, and the test
fixtures that pinned the phantom H4.

### CREATE

- [x] `Test-IsChangelogEntryFile` in `scripts/release/fold-changelog-entry.ps1`: range down (`$entryLevel - 1 .. $entryLevel`) and rewrite the stale H2/H3 comment -- mirror rebuilt with `scripts/sync/build-shared-scripts.ps1`
- [x] `Test-IsChangelogEntryFile` in `scripts/lint/check-plugin-integrity.ps1`: the same one-line range change and comment fix

### TEST

- [x] `scripts/tests/fold-changelog.tests.ps1` -- `New-LegacyEntryFile` writes the flat-window H2 level (`(Get-EntryHeadingLevel) - 1`); the legacy-fold asserts follow
- [x] `scripts/tests/check-plugin-integrity-entries.tests.ps1` -- the "pre-format entry file" fixture writes H2, and the label stops saying "H3"
- [x] a fold-all run recognises a flat-window entry file (new assert block, `fold-changelog.tests.ps1`)
- [x] `scripts/tests/*.tests.ps1` all green locally -- `test gate: all 63 suites passed in 351s`; lint gate 0 errors

### DEPLOY: fix/entry-file-detector-ranges-down

Both copies of `Test-IsChangelogEntryFile` -- in `fold-changelog-entry.ps1` and in
`check-plugin-integrity.ps1` -- built their level range as `entry level .. entry level + 1`. After the
August 26, 2026 shift that resolved to `^#{3,4}\s`: it matched the current H3 shape and an H4 no entry
has ever opened with, and missed the flat-window H2 (`## <title>`) that every entry written between
August 5 and 26, 2026 carries. `Test-BranchChangelogIsFilled` took the other direction on that same
day, so two predicates answering "is this an entry file" disagreed. The range now runs down
(`entry level - 1 .. entry level`, `^#{2,3}\s`), matching `Test-BranchChangelogIsFilled`. Fold-all mode
and check 13 (`[entry-heading]`) now recognise a flat-window entry file instead of skipping it
silently. Test fixtures that pinned the phantom H4 (`New-LegacyEntryFile`, the check-13 "pre-format"
fixture) now write the flat-window H2 that actually sits on parked branches. Comments-only prose about
these levels stays with #1341.

**Score:** 2

#### What makes this deploy extra special

N/A -- a fold-all recognition fix in the release tooling. A subscriber of a consuming service never
sees it.

**Score:** N/A

#### Pull Request

range the entry-file detector down from the entry level so a flat-window H2 entry is recognised

