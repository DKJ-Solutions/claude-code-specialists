## fix/1564-fold-stale-offset-after-tally

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

Issue #1564, verified against the tree:

- `fold-changelog-entry.ps1` takes `$insertPos`/`$listStart` as byte offsets into the pre-tally
  `$changelogContent`, then reassigns that variable from `Set-ChangelogPendingSummary`, which rebuilds
  the whole document from its lines and returns a **new** string (`entry-scaffold-lib.ps1` line ~3830
  onward -- every one of its four return paths does `$lines -join $nl`).
- The console-line block one step later (`$tailFromEntry = ...Substring($insertPos + $entryBlock.Length)`
  and `...Substring($listStart, $insertPos - $listStart)`) then reads those stale offsets.
- It only throws on the **first fold after a cut**: the empty-list sentinel is the longest tally this
  repo writes, so a counted one replacing it *shortens* the document, while `$insertPos` sits at the
  old end (no entry to insert above) -- so `$insertPos + $entryBlock.Length` points past the new length.
  The issue comment confirms line 1006 is the same defect, not a second one.
- It throws after `Write-Utf8NoBom` and `Remove-Item` and before the commit block, so `-Commit -Push`
  silently does neither and the fold is left uncommitted with the entry file already gone.

### CREATE

- [x] Move the `$placedNote` computation (the `$aheadOf`/`$behind` counts and the note string) to
  **before** the `Set-ChangelogPendingSummary` call in `fold-changelog-entry.ps1`, where `$insertPos`,
  `$listStart` and `$entryBlock` are still consistent with `$changelogContent`. The counts are position
  facts about the list and the tally line is not an entry heading, so reading them earlier changes
  neither number. Fixes both Substring calls at once (the issue's second suggested repair).
- [x] Leave `$rankNote` where it is (depends only on `$filed.RankScore`, not on content); trim the
  now-duplicated "WHERE it landed" comment down to a pointer.

### TEST

- [x] Add to `scripts/tests/fold-changelog.tests.ps1`: fold one entry into a fixture whose `CHANGELOG.md`
  carries `## [Unreleased]` + the post-cut sentinel tally (composed from `Format-ChangelogPendingSummary`
  so it cannot drift), with `-Commit`. Assert exit 0, no `startIndex`/`Substring` in the output, the
  entry landed under the surviving heading, the sentinel was replaced by a marked tally, the position
  line prints, and -- the half that matters -- the fold was actually committed with a clean tree behind
  it. The suite had no case folding into an empty `## [Unreleased]`.
- [x] Verified the new assertions fail on the unpatched script (crash) and pass on the patched one;
  full suite 251 pass / 0 fail.

### DEPLOY: fix/1564-fold-stale-offset-after-tally

`fold-changelog-entry.ps1` crashed on the first fold after every release cut -- folding into an empty
`## [Unreleased]` -- because it read byte offsets against the changelog *before* the pending-tally
rewrite replaced that string with a shorter one, then used them in the "placed above N" console line.
The crash landed between the changelog write and the commit, so `-Commit -Push` silently did neither
and left the fold uncommitted on the trunk with the entry file already deleted. The offset-dependent
counts now run before the tally rewrite, while the offsets are still valid; a regression test folds
into a freshly-cut `## [Unreleased]` and checks the fold is committed.

**Score:** 4

Every first fold after a release cut hit this; recovering it meant a hand-typed commit of the two
bounded paths, twice in one day per the issue. Not a 5 only because that recovery was known and
in-bounds.

#### What makes this deploy extra special

A consumer running the `dkj-policy` workflow hits the same crash on their first fold after their own
release cut -- a shipped script broken on a guaranteed code path, leaving their trunk in a silent
half-state (`-Commit -Push` doing neither, entry file gone so `check-unfolded-entry.ps1` sees nothing).

**Score:** 4

#### Pull Request

fold-changelog-entry.ps1 no longer crashes on the first fold after a release cut

