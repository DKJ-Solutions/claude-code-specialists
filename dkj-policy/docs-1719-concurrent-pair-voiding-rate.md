## docs/1719-concurrent-pair-voiding-rate

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

Recording the #1719 close-out measurement in ship-pr.ps1's step-3b block: the per-lap refusal tracks concurrent branches in flight, not trunk busyness. Edit the root copy, then mirror via build-shared-scripts.ps1.

### CREATE

- [x] Extend `ship-pr.ps1`'s step-3b comment block with the #1719 close-out measurement, beside the
      predicate #1750 put there: the per-lap refusal tracks CONCURRENT CERTIFYING LAPS, not the
      trunk's own rate, and shipping one branch at a time zeroes it.
- [x] Correct the count while writing it -- the first draft said `0 of 15` serially shipped PRs; the
      sample has 20 PRs, of which 10 sit in the 5 tight concurrent pairs, so it is `0 of 10`.
- [x] Add the counter-reading that a `gh pr list` would suggest and the data refutes: #1733 overlapped
      14 of the other 19 PRs for 285 minutes and voided none, because it was parked.
- [x] Mirror to `plugins/dkj-policy/scripts/release/ship-pr.ps1` via `scripts/sync/build-shared-scripts.ps1`
      rather than by hand -- the root copy is canonical and the drift lint gates the pair.

### TEST

- [x] `build-shared-scripts.ps1` reports the mirror updated, then `-Check` clean.
- [x] Lint gate + all suites via `open-pr.ps1` (comment-only change to a script, so the suites are
      the regression proof that nothing executable moved).

### DEPLOY: docs/1719-concurrent-pair-voiding-rate

Anyone changing `ship-pr.ps1`'s staleness gate now reads why it refuses, not just how often. The
block already carried the rate and (since #1750) its predicate; what it did not carry is the driver.
Issue #1719 measured it while being closed: the refusal tracks two branches CERTIFYING at the same
time -- 2 of 5 tight concurrent pairs lost a lap against 0 of 10 PRs outside such a pair -- and not
the trunk's own commit rate, which the paragraph above it had reached for. The practical consequence
is recorded with it: shipping one branch at a time drives the row to zero at no cost, which is why
#1719 closed against its own ranked converger options instead of building one. The measurement's
window, population and discount are stated, so the next reader can compare rather than re-argue.

**Score:** 3

#### What makes this deploy extra special

N/A -- a comment block inside a maintenance script. No consumer of this repo's plugins reads it and
no released behaviour changes; the mirror moves only so the drift lint stays green.

**Score:** N/A

#### Pull Request

Record the concurrent-pair voiding rate beside the step-3b predicate
