# Development cycle: `feat/ship-pr-names-the-governing-check-v1` · 20260824-092545

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

Make the merge wait legible without changing it: report which check finished last, its duration, whether the repo's ruleset requires it, and what the wait cost over the last required check.

Make the merge wait legible without changing it: report which check finished last, its duration, whether the repo's ruleset requires it, and what the wait cost over the last required check.

## PLAN

- [x] Verify the finding still stands: `ship-pr.ps1`'s step-3 comment still says it deliberately names
      no check, and the run still prints gh's own table and nothing about the ordering.
- [x] Check what `gh` can honestly answer before designing a line about it: `gh pr checks` (2.94.0)
      carries `--json name,startedAt,completedAt` **and** `--required`, so 'which check' and 'is it
      required' both come from the repo's own ruleset rather than from a name in this script.
- [x] Decide where the logic lives: the selection is pure and testable, the gh call is not -- so the
      same split `Get-ExistingPrRecord` already uses, in the same lib, with its own asserts.
- [x] Establish that option C was declined and B chosen, and that the measurement behind both had
      nowhere to live outside the issue -- so it is recorded in the wall-clock lens in this branch.

## CREATE

- [x] `Format-CheckDuration`, `ConvertTo-CheckTimestamp` and `Get-CheckWaitReport` in
      `scripts/lib/pr-issues-lib.ps1`, plus the lib header stating its second responsibility.
- [x] Wire it into `scripts/release/ship-pr.ps1` after the merge decision, best-effort, with the
      step-3 comment and the header's step list saying what the wait now reports.
- [x] Record the n=100 measurement, the declined option C and the unmeasured diff-size question in
      `.claude/specialists/lenses/06-25-extension.md`.
- [x] Regenerate the plugin mirror (`build-shared-scripts.ps1`): `ship-pr.ps1` and `pr-issues-lib.ps1`.

## TEST

- [x] 31 asserts in `scripts/tests/pr-issues.tests.ps1`, covering both orderings, both timestamp
      shapes, an absent and an unparseable ruleset payload, an unmeasured wait, a single check, and
      every payload that must return `$null` rather than invent an ordering.
- [~] No suite for the gh calls themselves: they need a live PR mid-merge, which is the test gap this
      script already declares for its other post-merge read. The selection they feed is covered above.

## DEPLOY: `feat/ship-pr-names-the-governing-check-v1`

`ship-pr` waits for every check a PR has, and used to say nothing about which one had held it up -- so the
only way to learn it was the Actions page, afterwards. That invisibility is how two observations, both out
of the tail, became a policy question about whether to wait on non-required checks at all. Measured over
n=100 paired runs the non-required check governs 23% of the time at a median cost of 0s, so the wait is
unchanged and the run now reports it: which check finished last, its own duration, whether the repo's
ruleset requires it, and how much later it finished than the last required check. It still names no check
of its own -- the ordering comes from the payload and 'required' from `gh pr checks --required` -- so it
says nothing about a consumer's CI that it cannot read there. Best-effort by design: an unreadable payload
costs one line of detail and can never turn a green run red.

**Score:** 3

### What makes this deploy extra special

Every consumer running `ship-pr` gets the same line, and for them it is worth more than it is here: they
have never had a figure for what their own merge wait is made of, and this is the one that produces it
without asking them to measure anything. It is also what has to exist before the bigger question --
whether to merge on the required check alone -- can be asked honestly, since that trade was declined
precisely because nobody could say yet whether the long reviews are the large diffs.

**Score:** 3

### Pull Request

ship-pr says which check governed the merge wait, and for how long
