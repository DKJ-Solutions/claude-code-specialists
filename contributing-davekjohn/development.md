## Development: `fix/ship-pr-names-a-run-that-never-started-v1` · 20260828-220318

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

Inbound #1044, filed from a consumer repo. `ship-pr.ps1` refuses a merge with *"CI did not pass ...
Fix CI and re-run"* when GitHub Actions never started a job at all. The report's own direction: leave
the merge decision alone -- refusing on an unreadable required-check list is the conservative half of
#943 -- and repair the DIAGNOSIS handed to the operator.

#### What was verified before building anything

- The symptom stands: `scripts/release/ship-pr.ps1` still prints that sentence on every blocked
  verdict, and `Get-MergeBlockVerdict` has no state for *the check never executed*.
- The reason stands: with `--required` unreadable, `$requiredFactsJson` stays empty and the verdict
  returns its `$unreadable` branch, so an infrastructure stall and a red required check are
  indistinguishable from there.
- The proposed mechanism was checked against a live run rather than assumed:
  `gh run view <id> --json conclusion,status,url,jobs` returns each job with its `steps`, so
  "nothing executed" is one call away and not the two API levels the report expected.
- The report describes the empty state two ways -- an empty jobs array AND jobs with zero steps. Both
  are recognised, because the stall could not be reproduced here and picking one would have been a
  guess.

### CREATE

- [x] `Get-FailedCheckRunIds` in [`scripts/lib/pr-issues-lib.ps1`](../scripts/lib/pr-issues-lib.ps1):
      the Actions run ids behind the failing records of a `gh pr checks --json` payload, deduped, with
      non-Actions links skipped.
- [x] `Get-StalledRunNote` in the same lib: one sentence when no job in a run executed a step, `''`
      otherwise.
- [x] [`scripts/release/ship-pr.ps1`](../scripts/release/ship-pr.ps1) asks gh for `link` alongside the
      check facts, and on the blocked path resolves each failing run before wording the refusal.
- [x] Mirror regenerated via `scripts/sync/build-shared-scripts.ps1` -- both files are shared with the
      `contributing-davekjohn` plugin.

### TEST

- [x] 31 asserts added to [`scripts/tests/pr-issues.tests.ps1`](../scripts/tests/pr-issues.tests.ps1),
      including the one that keeps it from crying wolf: a job that executed even one step gets no note.
- [x] `pr-issues.tests.ps1` green -- 270 asserts; every suite green through the gate below.
- [x] `check-plugin-integrity.ps1`: 0 errors.

### DEPLOY: `fix/ship-pr-names-a-run-that-never-started-v1`

`ship-pr.ps1` now says *"CI never RAN"* when the workflow run failed to start, instead of reporting it
as a check that went red.

Measured August 28, 2026 in a consumer repo (inbound #1044): Actions stopped starting jobs because an
account payment had failed. Every run ended in about four seconds with zero steps, no logs, and no
annotation on the ordinary run page. `ship-pr` reported it as *"CI did not pass for PR #N (exit 1) --
NOT merged: the required-check list could not be read ... Fix CI and re-run, or merge manually once
green."* Every clause of that is literally true, and together they point the reader at their own code
for a state no branch can repair and no re-run will change. One PR was merged by hand as a result --
the habit the workflow exists to prevent.

**The merge decision does not move, and that is deliberate.** No state was added to
`Get-MergeBlockVerdict`: refusing on an unreadable required-check list is the conservative half of
#943 and it still refuses, on exactly the same payload. What changed is which sentence the operator
reads beside the refusal. Two pure functions carry it, in the lib where the rest of the check
reasoning already lives: `Get-FailedCheckRunIds` pulls the Actions run ids out of the failing checks'
`link` field -- the only place a `gh pr checks` payload names the run behind a check -- and
`Get-StalledRunNote` reads one `gh run view <id> --json conclusion,status,url,jobs` and answers
whether any job in it executed a step. Both are best-effort: an unreadable payload costs the note and
leaves the old wording, because a diagnostic must never be the reason a refusal cannot be printed.

**Why the step count and not the annotation.** The reason text the reporter eventually found
(*"recent account payments have failed or your spending limit needs to be increased"*) sits on a
check-run annotation, and going after it would have been building on the half of the report that could
not be verified here: it describes the empty state two ways -- an empty jobs array and jobs with zero
steps -- and the entry point to the annotation differs between them. Both shapes are recognised
instead, because *no step ran* is the fact that makes "fix your code" wrong under every cause of it: a
failed payment, a reached spending limit, Actions disabled for the org, no runner able to take the
job. The note names the single command that prints the reason, which the run page does not show.

The assert that keeps it from crying wolf is the negative one: a job that executed even one step is an
ordinary failure and keeps the wording that is correct for it. A run still in progress is not stalled
either -- `ship-pr` only reaches this after `--watch`, so that cannot happen, which is precisely why it
is asserted.

**Score:** 3

#### What makes this deploy extra special

The report proposed a direction rather than a patch, and two of its details did not survive contact
with the tree -- the signal turned out to be one API call deep rather than two, and its account of the
empty state was ambiguous between two shapes. Neither was a defect in the report; both would have
become defects in the repair if the reason had been transcribed instead of checked. The fix recognises
both shapes and reaches for the fact rather than the cause, so it holds for the three causes nobody
has hit yet as well as for the one that was measured.

**Score:** 2

#### Pull Request

ship-pr tells a stalled Actions run apart from a check that went red
