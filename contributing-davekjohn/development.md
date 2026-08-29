## Development: `fix/red-check-names-its-reason-in-the-transcript-v1` · 20260829-201917

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

#### Where this came from

Issue [#1103](https://github.com/DaveKJohn/claude-code-specialists/issues/1103), taken over from
`davekokbwj` at Dave's request. It reports `claude-review` red on every PR today and says plainly what it
did **not** measure: the cause. Verified first, before anything was repaired.

**The cause was already printed, in the run the issue cites.** Run `33262872631`'s own **Why the review
failed** step reads `api_error_status: 429` and `You've hit your weekly limit - resets Aug 31, 7am (UTC)`.
So the symptom stands, the reasoning does not: the report points at the marketplace step, which is where
the run happened to be when the error surfaced and not where it came from. There is nothing in any diff to
repair and no re-run that helps -- the allowance comes back on the clock.

**What IS repairable is the eighth filing.** #891, #913, #942, #962, #966, #974, #1055 and now #1103, all
about this check red on every PR; every one since #966 the same quota state, and #966 itself was filed
against a log already reading `429` and concluded that a secret needed rotating. The reason has been
reachable since then. The reader was not: `ship-pr` merges past the advisory check, says *"the failing
check is still failing; nothing here fixes it"*, and the chaser meets `is_error:true`, which names nothing.

### CREATE

- [x] `Get-FailedCheckRunRefs` in `../scripts/lib/pr-issues-lib.ps1`: one parse of the `link` field
      yielding `{ Name; RunId; JobId }`, so the run question (#1044) and the annotation question (#1103)
      stop being two parsers of the same string. `Get-FailedCheckRunIds` delegates to it and still owns
      the dedupe.
- [x] `Get-AuthoredFailureNote`: the sentence a failing workflow wrote about itself, selected by
      **titled failure annotation** -- the runner's own failures carry an empty title, an authored
      `::error title=X::Y` does not. No check name is hard-coded, so it works in a consumer repo whose
      workflows this repo has never seen.
- [x] `../scripts/release/ship-pr.ps1`: on the not-blocked path, fetch the failing check's annotations
      and print that sentence under the warning. Best-effort throughout, like the stalled-run note on the
      refusal path; only the not-required failures are asked about.
- [x] `CONTRIBUTING.md` and `../.claude/specialists/lenses/05-15-extension.md`: what a red
      `claude-review` means, that `out of quota` is not a defect, and the eight threads that read it wrong.
- [~] The workflow itself is untouched. Its 429 diagnostic is complete and its decision to stay RED is
      recorded in the file with its reason -- a green tick would hide that the PR got no review. What was
      wrong was the legibility, not the colour.

### TEST

- [x] `../scripts/tests/pr-issues.tests.ps1`: 321 asserts green, 21 of them new -- the refs shape, the
      titled-failure selection, warnings and untitled runner noise excluded, the first-titled-wins order,
      the caps, and the call site in `ship-pr.ps1`.
- [x] Two corrections the real payload forced, both now pinned: the note stuttered
      (`claude-review: claude-review -- ...`) because this repo titles its own annotation with the job
      name, and a 300-character cap cut the message exactly where `resets Aug 31` sits -- the only
      actionable word in it.
- [x] Run end to end against the live payload of run `33267175141`: the printed line names the check
      once, carries the headline and reaches the reset time.
- [x] `build-shared-scripts.ps1` re-mirrored both scripts into the plugin.

### DEPLOY: `fix/red-check-names-its-reason-in-the-transcript-v1`

A failing check that does not block the merge now says **why** it failed, in the same transcript that
reports it. `ship-pr` reads the failing check's annotations and prints the sentence that workflow wrote
about itself -- so a red `claude-review` arrives as *"out of quota -- the review did not run ... resets
Aug 31, 7am (UTC)"* instead of as a red mark with a log to go hunting through.

The rule is generic on purpose: **a failure annotation carrying a title** was written by a workflow
author, while the Actions runner emits its own untitled (*"Process completed with exit code 1"*). Nothing
is keyed on a check name, so a consuming repo gets the same relay for workflows this repo has never seen.

Filed as [#1103](https://github.com/DaveKJohn/claude-code-specialists/issues/1103) and, before it, seven
more threads about the same red check -- one of which concluded that a secret needed rotating, against a
log already reading `429`. The reason had been printed in the run since #966; what was missing was a
reader standing where it was printed.

**Score:** 3

#### What makes this deploy extra special

It repairs a reporting loop rather than a bug: the eighth issue about a check whose own diagnostic had
already answered the question. The measurement is the eight threads, and the repair is not a ninth
explanation but moving the existing one to where the reader lands.

**Score:** 2

#### Pull Request

a failing non-required check names its own reason where ship-pr's operator reads it
