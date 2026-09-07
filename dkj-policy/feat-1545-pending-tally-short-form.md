## feat/1545-pending-tally-short-form

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

Dave chose reach/total + the earned bump word. The bump rule must move to entry-scaffold-lib as ONE copy that release-lib calls, not a second copy of Test-ReleaseBumpEarned's arithmetic.

#### The decision, and the design constraint it had to clear

Dave was offered three shapes and picked **reach / total + the bump word**, knowing what it cost: the
tally's own comment block stated `NO BUMP IS NAMED HERE, deliberately`, because the rule lived in
`Test-ReleaseBumpEarned` in `release-lib`, which the fold does not load and must not start loading for a
console nicety -- and a second copy of a release gate's arithmetic, inside the document that gate then
reads, is a shape this repo has scar tissue from.

That reasoning was right about the copy and wrong about the conclusion. `release-lib.ps1:113`
dot-sources `entry-scaffold-lib.ps1` and never the reverse, so the lower lib is a layer **both** callers
already share. Defining the rule there gives one copy, not two.

### CREATE

- [x] `Get-EntryEarnedBump` in `entry-scaffold-lib.ps1` -- the rule as one function (Notable + Bump)
- [x] `Test-ReleaseBumpEarned` calls it instead of keeping its own inline loop and `minor`/`patch` choice
- [x] `Format-ChangelogPendingSummary` rewritten to the short form; buckets and the audience sentence gone
- [x] Wording seam: `Lead`/`Bucket`/`AudienceShare` retired, `Share`/`NoShare`/`Minor`/`Patch` added
- [x] The no-audience fallback drops the fraction rather than printing `0 / N`
- [x] The comment block rewritten -- it stated the decision this branch reverses, so leaving it would
      have left the file arguing against its own code
- [x] Prose: `CONTRIBUTING-portable.md`, `dkj-policy/CONTRIBUTING.md`, `CHANGELOG.md`'s intro, and the
      illustrative old form in `cut-release.ps1`'s reset comment
- [x] Mirrored to `plugins/dkj-policy/scripts/lib/` via `build-shared-scripts.ps1`

### TEST

- [x] `entry-scaffold.tests.ps1`: 5 asserts pinned to the old shape updated, 17 added -- 746 pass
- [x] The divergence case pinned deliberately (`0 / 2 minor entries`), so nobody "fixes" it away
- [x] `Get-EntryEarnedBump` unit asserts, empty map included
- [x] `release-lib.tests.ps1` green on the extracted rule -- 471 pass
- [x] Lint gate green, including `[script-ascii]` and `[shared-script]`

### DEPLOY: feat/1545-pending-tally-short-form

The changelog's pending tally is one short line again. It read
`**9 entries pending** -- 5 at tier 0, 4 at tier 2. Tier 2 is this repo's audience: 4 of 9 reach it.`
and now reads `**4 / 9 minor entries**`: how many pending entries reach this repo's audience, out of how
many are waiting, and which bump that work has earned. The per-tier buckets are gone -- they are one
`grep` away in the entries the line sits directly above, so the sentence was spending its length on the
one thing the document below it already spells out per entry.

**The bump is named there for the first time, and it is one rule rather than two.** It used to live only
in `Test-ReleaseBumpEarned`, in `release-lib`, which the fold never loads -- so the tally could not reach
it and the comment block chose silence over a copy. `Get-EntryEarnedBump` now holds it in
`entry-scaffold-lib`, the layer `release-lib` already dot-sources, and `Test-ReleaseBumpEarned` calls it.
The gate and the line it summarises can no longer disagree about what a minor is.

**Two numbers, two questions, and they may differ by design.** The fraction counts entries at or above
the repo's audience tier; the bump follows tier 1 or higher. So `**0 / 8 minor entries**` is correct and
precise -- nothing reaches a subscriber, and the version still owes a minor for what reaches management.
A test pins that case so it is not later mistaken for a bug and "repaired". Where a repo has stated no
audience tier the fraction is dropped rather than shown as `0 / 8`, which would report an unanswered seam
as an absence of reach.

**Score:** 3

#### What makes this deploy extra special

A consumer sees the shorter line on their next fold, with no action needed -- and the two numbers are
explained in `CONTRIBUTING-portable.md` before anyone reads `0 / 8 minor` as a contradiction.

**One thing does need a consumer's attention, and only if they translated the tally.** Three keys of
`Get-ChangelogPendingSummaryOverrides` are retired: `Lead`, `Bucket` and `AudienceShare`. Only keys the
defaults carry are read, so an answer for a retired key is silently **inert** rather than an error -- the
line simply comes back in English. `Share` and `NoShare` replaced them, and the bump word is seamed too
(`Minor`/`Patch`), with reorderable placeholders because a translation rarely wants them in English
order. A repo that translated nothing is unaffected.

**Score:** 2

#### Pull Request

The pending tally reads as one short reach-over-total line

