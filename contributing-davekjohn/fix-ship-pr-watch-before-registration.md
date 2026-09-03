## fix/ship-pr-watch-before-registration

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

Issue #1350. On PR #1348 (September 3, 2026) `ship-pr.ps1`'s step-3 registration probe broke out on
its first pass -- it saw checks, or a gh error it could not tell from checks -- and the `--watch`
call moments later reported `no checks reported` and exited non-zero, seconds after `open-pr` pushed
a new head onto a busy Actions queue. None of the three wording guards on the refusal path
(`Get-LostWatchNote`, `Get-FailedCheckRunIds`, the `else` arm) covers "nothing is registered yet", so
the run fell through to `CI did not pass ... Fix CI and re-run` -- a CI verdict about a state where
no check had failed because no check yet existed.

The fix is cause-independent, which is what #1350 asked for: whatever made the probe and the watch
disagree (a head race, a probe that broke out on a transient gh error), a `--watch` that comes back
saying `no checks reported` means the checks are not registered, and the answer to that is step 3's
own registration wait -- not the merge verdict.

### CREATE

- [x] Extract step 3's inline probe loop into `Wait-CheckRegistration` (script-local function,
      defined before step 3), so the wait -- and its #1234/#1247 timeout diagnostic -- has one home
      that the watch loop can re-enter. It takes `-AlreadyWaited` so the 180s budget is shared.
- [x] In the watch loop, before the fact-pair reads, add a guard: a non-zero `--watch` exit whose
      output matches `no checks reported` sleeps one poll interval and re-enters `Wait-CheckRegistration`,
      then `continue`s. A real red check (a table, not that phrase) still falls through untouched.
- [x] Update step 3's descriptive comment to point at the function and the #1350 re-entry.
- [x] Mirror the change into `plugins/workflows/contributing-davekjohn/scripts/release/ship-pr.ps1`
      byte-for-byte.

### TEST

- [x] Added a `#1350` block to `scripts/tests/pr-issues.tests.ps1`: the wait is a function, step 3
      calls it before `--watch`, the watch loop re-enters it after `--watch` guarded by the
      `no checks reported` text, the fallback shares the budget (`-AlreadyWaited $waited`), and the
      missing-suite diagnostic appears exactly once. Text/call-site asserts, matching the existing
      #1044 and #1219 pins -- the function is script-local and dot-sourcing the script would run the ship.
- [x] `scripts/tests/pr-issues.tests.ps1` -- all 619 asserts pass.
- [x] `scripts/tests/shared-scripts.tests.ps1` (mirror drift) -- all 492 asserts pass.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors.
- [x] Full suite gate (`Invoke-TestSuiteGate`) -- 64 suites pass.

### DEPLOY: fix/ship-pr-watch-before-registration

`ship-pr` no longer mistakes a `gh pr checks --watch` that started before the CI checks registered
for a CI failure. Where the watch comes back saying `no checks reported` and exits non-zero -- seen
right after a push onto a busy Actions queue -- the run now falls back into the same registration
wait step 3 already runs, instead of refusing with `Fix CI and re-run` about a check that had not
failed because it did not yet exist. The 180s budget is shared across the probe and the fallback, so
a race that never settles still ends in the existing `#1234` refusal. No behaviour changes on a
healthy run or on a genuine red check.

**Score:** 3

#### What makes this deploy extra special

A consumer running `ship-pr` immediately after a push, on a busy Actions queue, could lose the ship
attempt to this transient and read a misleading "Fix CI and re-run" telling them to go look at CI
that was in fact fine. It is non-deterministic and the workaround was to re-run `ship-pr`, so the
cost was a wasted CI window rather than a broken merge.

**Score:** 2

#### Pull Request

ship-pr falls back to the registration wait when --watch starts before the checks exist

