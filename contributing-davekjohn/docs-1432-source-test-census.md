## docs/1432-source-test-census

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

Issue #1432. Re-verified on main at 1ade961a AFTER #1422 landed (#1431): the tree now holds exactly FIVE inline sites, matching the bullets, and the two prose checks plus adopt-workflow-folder all call the function. #1422 also added the 'evidence of a distinction rather than a current inventory' closing paragraph. So the stale figure really is all that is left -- and the choice is settled by that new paragraph: a count IS an inventory claim, so drop the number rather than setting it to five. Historic: 'six' was wrong the day it was written (census was 5 at c898d9f3), drifted to 7, back to 5.

### CREATE

- [x] Verify all six ways the report could fail before repairing anything. Symptom stands. Reason
      stands -- `git grep` at `c898d9f3`, the commit that wrote "six", returns five inline sites, so
      the figure was wrong on the day it was written and #1422 did not introduce it. Two things the
      report got wrong in the reporter's favour, both found by checking rather than by reading it:
      the rewording it credits to #1422 did **not** exist when it was filed (not on `main`, not on
      the in-flight branch), and the two prose checks asked an unlisted FOURTH question rather than
      merely being two uncounted sites.
- [x] Re-take the census after #1422 landed mid-verification (#1431, commit `9335f404`). It repaired
      the larger half itself: the two prose checks and `adopt-workflow-folder.ps1` all call the
      function now, and the "evidence of a distinction rather than a current inventory" paragraph is
      in. Tree is back to exactly five inline sites, matching the bullets -- so the stale figure is
      genuinely all that was left, which is what the report predicted.
- [x] Drop the count from the opening sentence: it points at the bullets now instead of totalling
      them.
- [x] Record why no number replaced it, placed under the inventory paragraph it follows from -- the
      three values the figure held in nine days, and `grep` as the inventory.
- [~] Set the figure to five instead. Dropped, and it is the option the issue offered first: #1422's
      new closing paragraph tells the reader this list is not a current inventory, and a count is an
      inventory claim, so five would be correct today and contradict the paragraph three lines below
      it. It has already gone stale twice.
- [x] Regenerate the plugin mirror -- `seam-lib` is a shared script, so
      `build-shared-scripts.ps1` carries the docstring into
      `plugins/workflows/contributing-davekjohn/`.

### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors, mirror in sync, check 27 (`[script-ascii]`) green on
      the added prose.
- [x] No other file asserted the count. `grep` for `further sites` across the tree returns only the
      two copies of the new note that quote the retired wording, source and mirror.
- [~] A test for the docstring. Dropped: nothing reads this prose, and the suites already pin the
      function's behaviour, which this branch does not touch.

### DEPLOY: docs/1432-source-test-census

`Test-IsWorkflowSourceRepo`'s docstring no longer opens its inline-site list with a count. The figure
said six while both the census and the bullets stood at five -- wrong on the day it was written, the
intended sixth being `adopt-workflow-folder.ps1`, which the same docstring already describes as
having *stopped* being an inline site. It then drifted to seven as the two consumer-prose checks
arrived and back to five when #1422 pointed them at the function: three values in nine days, while
the bullets stayed correct throughout.

That list exists to arbitrate which question a new site should ask -- the broad "does this repo
publish plugins" or this function's "is this repo the source of this workflow" -- and #1422 had
already added the paragraph telling the reader to take it as evidence of a distinction rather than as
a current inventory. A count is an inventory claim, so it is gone rather than corrected to five,
which is why the figure cannot go stale a fourth time. A note in its place records the three values
and points at `grep` as the inventory that is always current.

**Score:** 2

#### What makes this deploy extra special

N/A. The docstring travels to consumers in the plugin mirror, but it documents how *this* repo's own
call sites are written and no consumer adds one; nothing a consumer runs changes behaviour.

**Score:** N/A

#### Pull Request

The source test's inline-site census drops a count that contradicts its own closing paragraph

