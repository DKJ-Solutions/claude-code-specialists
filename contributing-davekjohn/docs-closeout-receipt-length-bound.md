## docs/closeout-receipt-length-bound

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

Dave asked a second time for Chris's close-out to be shorter, so this is a rule that keeps losing rather
than a missing rule — it is already in the persona body three ways. #1402 names the two seams where the
wording gives way. Both are tightened in place, line-count neutral, because this is always-on text.

### CREATE

- [x] Bound the filing line in `plugins/teams/team-alpha/personas/01-01-persona.md` step 6: the number
      and at most a short clause, never a sentence of finding
- [x] Put a blunt length ceiling beside the "test is duplication, not length" rule, which was being used
      to justify length — a session can always find something non-duplicative to add
- [x] Give an unfileable finding a home inside shape A: filed inward, into the nearest issue this session
      can file, rather than carried into the reply as a fourth shape
- [x] Keep the example portable — `#<n>` rather than this repo's own issue numbers, which would point a
      consumer at their own tracker

### TEST

- [x] No shared-block markers in the persona, so the generator does not own step 6 and nothing needs
      regenerating; the `[shared]` and `[persona]` lint checks confirm it
- [x] Step 6 is the same length before and after — 18 insertions against 18 deletions, +91 bytes

### DEPLOY: docs/closeout-receipt-length-bound

Chris's close-out had three permitted shapes and a receipt-not-report rule, and still grew back into a
report. Two seams are tightened in his persona body. The instruction to "name what it filed, with
numbers" is now bounded by length — the number and at most a short clause, never a sentence of finding —
because that instruction was the one doing the expanding: a close-out that obeys the filing rule and then
writes a paragraph per issue asks the reader to read everything twice. And "the test is duplication, not
length" now has a cruder rule beside it, since a session can always find something non-duplicative to
add.

The second seam was a missing home rather than a missing bound. A finding that cannot be filed from the
current checkout — one belonging on another repo, where filing needs the owner's word — had no shape, so
it arrived as a fourth one, the *"this waits on you"* the page explicitly forbids. It is now filed
inward, into the nearest issue this session can already file, and cited like any other number.

Line-count neutral: the two clauses are paid for by cutting restatement, because this text loads on
every turn in every consuming repo.

**Score:** 3

#### What makes this deploy extra special

Every consumer's orchestrator gets the same bound, which matters because the failure it fixes is one a
consumer cannot see: a close-out that reads as thorough is exactly the one that costs its reader the
session. A repo adopting the specialists inherits the tightened rule rather than the wording that kept
giving way.

**Score:** 2

#### Pull Request

Chris's close-out receipt gets a length bound and a home for an unfileable finding
