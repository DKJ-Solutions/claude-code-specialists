## fix/1718-mentions-skip-guidance

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

The already-done check warned about `#1650` on every branch, because open-pr's mention scan read the
WHOLE development document and the scaffold's guidance block cites `#1650` in the line explaining the
preamble rule. The repair is the one #1718 asked for: read the branch's OWN content, from the first phase
heading, and reuse the split the shape gate already makes rather than filtering numbers.

### CREATE

- [x] `Get-DevelopmentBranchText` in `scripts/lib/entry-scaffold-lib.ps1`, reusing
      `Get-DevelopmentShapeFindings`' heading walk so the levels and the fence-awareness have one definition
- [x] `scripts/release/open-pr.ps1`: the mention scan reads that instead of the whole file
- [x] Mirror both into `plugins/dkj-policy/` via `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `entry-scaffold.tests.ps1`: the split, the round trip through `Get-IssueMentions`, a number written
      under each of the four headings, and the three no-phase fallbacks
- [x] `pr-issues.tests.ps1`: open-pr actually uses it, before the already-done check
- [x] Lint gate + all suites green

### DEPLOY: fix/1718-mentions-skip-guidance

open-pr's mention scan reads the branch's own content now -- everything from the first phase heading down --
instead of the whole development document. The scaffold's guidance block is where this workflow records why
its shape rules exist, so every issue it cites was being read as a mention of whatever branch happened to be
open: the already-done check reported `#1650 is already CLOSED, and it is already resolved by PR #1661` on a
branch with no connection to it, unconditionally, in this repo and in every consumer. That warning could not
be told apart from a real one in the same run, and it would have grown by one line every time a new rule was
cited. The new `Get-DevelopmentBranchText` reuses the heading walk `Get-DevelopmentShapeFindings` already
does, so the levels and the fence-awareness keep one definition; the region it drops is the one that gate
already refuses branch content in, which is what makes it safe to drop. No ignore-list of numbers.

**Score:** 3

#### What makes this deploy extra special

Every repo running this workflow gets its ship output back: the already-done check goes quiet unless it has
something to say, so the next warning it prints is worth reading.

**Score:** 3

#### Pull Request

The mention scan reads the branch's own content, not the scaffold's guidance block

