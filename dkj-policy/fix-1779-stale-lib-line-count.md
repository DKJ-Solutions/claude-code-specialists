## fix/1779-stale-lib-line-count

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### What #1779 reported, and what it left unchecked

`scripts/lib/release-lib.ps1:701` sized `entry-scaffold-lib.ps1` at "three thousand lines" in the
sentence that is the whole argument for `Get-TouchedPlugins` having moved down a layer. Verified in this
checkout on September 10, 2026: the file measures **8,289** lines (`wc -l`), so the figure was 2.7x under,
and the dot-source it argues about is real and unconditional (`release-lib.ps1:113`). The argument is
strengthened by the correction, not weakened -- reaching `release-lib` from a script that runs immediately
after a merge costs nearly three times what the sentence claimed.

The issue's "Not checked" section named the open question: whether any other prose cites a line count for
this or another lib. It does. **Seven sites carried the same stale figure**, not one.

- [x] Verify the reported symptom against the tree -- 8,289 lines measured; the dot-source read at line 113
- [x] Sweep the tree for the same claim elsewhere -- six more sites found, in four more files

### CREATE

- [x] Correct the four sites sizing `entry-scaffold-lib` directly -- `release-lib.ps1:701`,
      `plugin-tree-lib.ps1:51`, `plugin-tree-lib.ps1:207`, `fold-changelog-entry.ps1:235`
- [x] Correct the two sites sizing the load of `release-lib` -- `release-lib.ps1:405` and
      `entry-scaffold-lib.ps1:3546` said "three thousand lines of release machinery", which understates
      either reading: loading `release-lib` pulls 10,056 lines (1,767 + 8,289), and `release-lib` alone is
      1,767. Both now name the chain instead of a number.
- [x] Correct `script-contract-lib.ps1:584` -- "over three thousand lines" was true as a lower bound but
      understates by 2.7x in a sentence whose whole subject is parse cost
- [x] Record at the primary site WHY there is no number, so it does not come back a third time
- [x] Rebuild the plugin mirror (`build-shared-scripts.ps1`) -- five mirror pairs updated
- [~] Leave the two intra-file distance claims alone, both measured first:
      `entry-scaffold-lib.ps1:1035` ("some two thousand lines ABOVE") measures 2,418 and is hedged, and its
      argument -- reading a variable declared later yields nothing -- does not turn on the magnitude at all;
      the "thirty-three hundred lines apart" pair (`:1523`, `:6305`) is a dated historical measurement of two
      loops that #941 merged, so correcting it would falsify a recorded measurement rather than repair one.

### TEST

- [x] Confirm no test or CI workflow reads the phrase -- `grep` over `scripts/tests/` and `.github/`: none
- [x] Confirm the touched files stay pure ASCII (repo convention for `.ps1`)
- [x] Lint gate + all suites green
- [x] Confirm no `three thousand` remains outside the archived release notes and the note's own quotation

### DEPLOY: fix/1779-stale-lib-line-count

Seven docstring sentences across five libs sized `entry-scaffold-lib.ps1` at "three thousand lines" where it
measures 8,289 -- each of them in the sentence carrying a layer or dependency decision, so the stale figure
argued for the decision at a third of its real strength. They now say "thousands", which cannot go stale
upward, and `release-lib.ps1` records why the number is deliberately absent. The two sites that sized the
load of `release-lib` rather than the lib itself named a figure that understated either reading; both now
name the dependency chain instead.

The defect class is the point rather than the arithmetic: a size written into prose drifts with every commit
to the file it describes, and it gets copied rather than re-measured -- `check-connectors.ps1` declined to
call into `release-lib` and cited this docstring as its evidence (#1775), which is how one stale number
became two.

**Score:** 2

#### What makes this deploy extra special

N/A -- comments inside this repo's own script layer. No behaviour changes, no consumer-facing text moves,
and nothing a subscriber of a service could notice.

**Score:** N/A

#### Pull Request

Correct the stale entry-scaffold-lib line count in the layer-decision docstrings
