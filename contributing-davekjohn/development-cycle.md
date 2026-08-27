## Development cycle: `fix/fold-legacy-entry-level-v1` · 20260827-095755

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Repair inbound #953: `fold-changelog-entry.ps1`'s heading promotion derives its legacy range from today's
level, so it misses the flat-window H2 -- and even where it matches, it shifts one line.

#### What the report got right, and the half it did not have

The symptom stands and the mechanism it names is the real one: the range is built as
`'#{' + level + ',' + (level + 1) + '} '`, which reads as H3-or-H4 now that `Get-EntryHeadingLevel` is 3.
H4 is a level no entry has ever opened with; H2 -- the level every entry written in the flat window
(August 5-26, 2026) carries -- falls outside it. It was correct while the level was 2 and stopped being
correct the day the level moved, silently, because it was derived rather than stated.

The report left the repair open ("widen to `{2,4}`, or detect the format"). **Widening would have been
worse than the defect.** A flat-window entry is an H2 heading with H3 sections; lifting only its heading to
H3 puts that heading and its own sections at one level, and `Split-EntryBlocks` then reads one entry as
four. The promotion's own comment argued for `count 1` so a body section would keep its level -- true while
the delta is 0 and nothing needs to move, and exactly backwards for the case the promotion exists for.

**The answer already existed.** `Set-EntryHeadingLevel` measures a block's own level and shifts every
non-fenced heading by that delta -- the repair the release renderers got on August 5, 2026 for this
identical reason. The fold could not call it: it lived in `release-lib.ps1`, and the fold's dot-source was
deliberately narrowed to the small libs on August 9, 2026. Two answers to one question, and the unreachable
one was the right one.

#### Why the suite was green through all of it

`New-LegacyEntryFile` models the legacy entry one level *deeper* than the current one
(`(Get-EntryHeadingLevel) + 1`), rewritten that way on August 26, 2026 when the level moved and the literal
`###` fixture "quietly became a CURRENT-shape entry". That block is a heading plus prose, so re-levelling
its first line was always enough -- the fixture cannot reach the defect, and it was itself repaired by
deriving from today's level. The suite needed a fixture for the shape a consumer actually carries.

### CREATE

- [x] Verify the report against the tree before scoping: the range, the level, and `Get-EntrySectionLevelRange`'s precedent for stating a historical level rather than deriving one
- [x] Move `Set-EntryHeadingLevel` down into `scripts/lib/entry-scaffold-lib.ps1`, where the entry format is defined and the fold can reach it; leave a pointer in `scripts/lib/release-lib.ps1`, which dot-sources it so every existing caller is unchanged
- [x] Add `Get-EntryBlockHeadingLevel` beside it -- the fence-aware reader that MEASURES a block's own level, replacing the inline walk `Set-EntryHeadingLevel` carried
- [x] Replace the fold's first-line regex with a whole-block re-level, and report the level the author actually wrote instead of testing string inequality
- [x] Re-apply the document's newline after the re-leveller, which returns pure LF while the fold assembles in `$nl`
- [~] Widen the legacy range to `{2,4}` as the report proposed: dropped, and the reason is above -- it turns a stray-heading defect into a split-entry one
- [x] Mirror the three changed scripts into the plugin (`scripts/sync/build-shared-scripts.ps1`)

### TEST

- [x] `New-FlatWindowEntryFile`: a fixture in the shape a consumer carries -- entry one level shallower, sections at the current entry level -- expressed as that relationship rather than as a literal `##`
- [x] Regression test in `scripts/tests/fold-changelog.tests.ps1`: the folded entry is ONE entry and not four, nothing is left at the written level, and its sections land at the section level
- [x] Falsify it against the pre-fix fold: 6 of the 7 asserts go red on `main`'s version, so the test tests something
- [x] And falsify the first draft of it, which PASSED on the broken code -- a bare `-match` for a section heading was satisfied by the fixture's OTHER entry; it is a count now
- [x] One-owner asserts in `scripts/tests/entry-scaffold.tests.ps1`, on the pattern the fence reader's move already set: `release-lib` no longer defines the re-leveller but still calls it, and the fold derives no legacy range from the current level
- [x] The existing legacy-entry assert updated -- the message it matched (`pre-flat entry format`) no longer exists, and the new one names the level that was written
- [x] All suites green (`scripts/tests/*.tests.ps1`)
- [x] `check-plugin-integrity.ps1` green, mirror in sync

### DEPLOY: `fix/fold-legacy-entry-level-v1`

The fold brought a legacy entry to the current heading level by rewriting its first line, and it found that
line with a range derived from today's level -- `#{level,level+1}`, which has read as H3-or-H4 since the
entry level moved to 3 on August 26, 2026. H4 is a level no entry has ever opened with, and H2 -- what
every entry written in the flat window (August 5-26, 2026) carries -- fell outside it, so such an entry
folded unpromoted and landed as a sibling of `## [Unreleased]` rather than a child of it. Widening the
range would have made it worse: a flat-window entry has H3 sections under its H2 heading, so lifting the
heading alone leaves entry and sections at one level and `Split-EntryBlocks` reads one entry as four.

It now calls `Set-EntryHeadingLevel`, which measures the block's own level and shifts every non-fenced
heading by that delta -- the repair the release renderers got on August 5, 2026 for the identical reason.
That function moved down from `scripts/lib/release-lib.ps1` into
`scripts/lib/entry-scaffold-lib.ps1`, where the entry format is defined and the fold can reach it, because
the fold's dependencies were narrowed to the small libs on purpose. Its inline level walk became
`Get-EntryBlockHeadingLevel`, so the shift and the fold's report of it read the level once.

Filed as inbound [#953](https://github.com/DaveKJohn/claude-code-specialists/issues/953), measured in a
consumer. Both halves are now regression-tested against a fixture in the shape a consumer actually
carries -- the suite had none, because the one legacy fixture it did have was itself rewritten to derive
from today's level and models a block with no sections to move.

For the maintainers of this repo, the same defect class ends in two places at once: one re-leveller in the
system instead of two answers to one question, and a test fixture that no longer masks the bug it exists
to catch. The fold is this repo's own release machinery, and an entry that stops being an entry boundary is
the failure shape this repo keeps paying for -- the cut leaves it out of every release document after the
entry file has already been deleted.

**Score:** 4

#### What makes this deploy extra special

A consumer who folds a pending entry written before their v4.20.0 update meets this on their next merge:
the entry lands as a stray sibling of `## [Unreleased]` and has to be repaired by hand, which is exactly
what happened in `djcylow-react`. Nothing to migrate and nothing to act on -- the repair arrives with the
plugin -- but it is noticed the moment they touch a fold with a legacy entry pending.

**Score:** 3

#### Pull Request

The fold re-levels a legacy entry whole, so its sections move with its heading
