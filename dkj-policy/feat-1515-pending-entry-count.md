## feat/1515-pending-entry-count

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

Add a machine-maintained pending-entry tally under `## [Unreleased]`: total plus the per-tier
breakdown, written by the fold and reset by the cut.

#### What the issue asked for

[#1515](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1515), in Dave's own words:
how many entries are waiting in the changelog for a new release, so he has a sense of how big that
release will be -- and, beside it, how many of them are tier 1 or tier 2 (whichever the repo's kind
makes it) against the total, since every entry is at minimum a tier 0.

#### The one design decision worth stating up front

The tally is **derived, never accumulated**. Both numbers already exist in the document --
`Get-ChangelogEntryBlocks` knows how many entries are pending and `Resolve-EntryImpact` knows each
one's reach -- so the line is a rendering of the list rather than a record kept beside it. Nothing
increments a counter, so nothing can drift, and a hand-edited changelog is simply re-measured on the
next fold. That is also what makes it safe to run from the fold, which pushes straight to the trunk
under one of this repo's named exceptions: a derived line can be wrong for exactly as long as it
takes the next fold to run.

### CREATE

- [x] `entry-scaffold-lib.ps1`: `Get-ChangelogPendingCounts`, `Format-ChangelogPendingSummary`,
      `Set-ChangelogPendingSummary`, plus the marker, the overridable wording map and
      `Test-ChangelogTallyIsQuoted`. Placed beside the pending-heading block, whose readers they
      reuse.
- [x] `fold-changelog-entry.ps1`: refresh the tally between the insert and the write, so each pass of
      the fold loop leaves the line correct rather than only the last one.
- [x] `cut-release.ps1`: rewrite it on the emptied document. The line sits in the changelog's HEAD,
      which is exactly what `Convert-ChangelogForRelease` keeps -- so without this a freshly cut
      changelog would carry an intact "37 entries pending" over an empty list.
- [x] The consumer shape is covered: a changelog scaffolded by `adopt-workflow-folder.ps1` has no
      `## [Unreleased]` heading at all, so the tally anchors on the first entry there instead of
      silently never appearing.
- [x] Docs: the changelog's own intro, `dkj-policy/CONTRIBUTING.md` at the fold step, and the
      portable `CONTRIBUTING-portable.md` so every consumer receives it. No lens entry -- nothing
      here is repo-specific, and the source is the default destination.
- [x] `build-shared-scripts.ps1` re-run, so the three plugin mirrors match their source.

### TEST

- [x] 21 asserts added to `entry-scaffold.tests.ps1`: the counts against all three declaration
      shapes, the empty document, the audience seam present and absent, at-or-above rather than
      equal-to, placement, idempotence, the correction of a hand-edited count, the consumer shape
      with no pending heading, both quoting hazards, the wording override and its
      empty-is-ignored fail-safe.
- [x] Both call sites asserted from the scripts' own source, in order -- the fold's call must sit
      between its insert and its write, the cut's after it empties the list. A correct formatter
      nobody calls is what a reverted wiring would otherwise leave green.
- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] Every suite under `scripts/tests/`: green.

### DEPLOY: feat/1515-pending-entry-count

`CHANGELOG.md` could not say how much was waiting for the next release without somebody counting the
entries by hand. It now carries one machine-written line directly under `## [Unreleased]`: how many
entries are pending, how they split by tier, and how many of them reach the audience tier the repo
publishes to -- which is the number that decides whether there is a release here at all or only a
patch. The fold rewrites it after every merge and the release cut rewrites it on the emptied
document.

It holds no state. The line is recounted from the entries in the document about to be written, using
the same reader the cut uses and the same disjoint highest-tier grouping, so the tally cannot
disagree with what the release is about to do -- and an entry edited in or out by hand is corrected
by the next fold rather than left to rot. It deliberately does not name the bump the pending work
earns: that rule lives in `Test-ReleaseBumpEarned`, in a lib the fold does not load, and a second
copy of a release gate's arithmetic inside the document that gate reads is the shape this repo keeps
getting bitten by.

**Score:** 3

#### What makes this deploy extra special

Every consuming repo gets this through the plugin, and gets it without doing anything: no heading to
add, no configuration to answer. The tally anchors on the pending heading where a repo has one and on
the first entry where it does not -- which is the shape `adopt-workflow-folder.ps1` scaffolds, so the
repos most likely to have been missed are the ones explicitly covered. Every word of the line is
overridable through `Get-ChangelogPendingSummaryOverrides`, so a changelog kept in another language
stays in it, and the count reads correctly whether a repo answered tier 1 or tier 2 as its audience.

The one thing a consumer could lose is a note of their own in that space, and that is what the line's
trailing HTML comment prevents: only a line carrying that marker is ever replaced, and a marker
quoted in their intro -- in a fence or in inline backticks -- is read as a quotation rather than as
the line itself. That second guard is the one a fence check cannot give, and the intro is exactly
where somebody will write it.

**Score:** 3

#### Pull Request

Count the pending entries under [Unreleased] in the changelog
