## fix/1602-merge-on-required-green

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

#### What Dave decided, and what was measured before he decided it

#1602 filed four options and said the choice was not the reporter's. The lap-level measurement
this branch carries was taken first, because the issue itself names it as the number that would
size option 2 and it does not depend on which option is picked. Dave then chose **option 2**:
merge as soon as every REQUIRED check is green, and report the non-required ones afterwards.

- [x] Claim #1602 and verify it against the tree -- symptom, reason and the cited instance all hold.
- [x] Measure the number #1602 names as unmeasured: how often the voiding commit lands in the
      non-required tail rather than anywhere in the window. n=99 laps; posted on the issue.
- [x] Put the decision to Dave with that number in hand, rather than picking for him.

### CREATE

- [x] `Get-RequiredCheckNames` in `pr-issues-lib.ps1` -- the walk over the required payload that
      was written out three times inline, shared so the 5.1 collapse cannot be reintroduced in a
      copy this repo's one-required-check ruleset can never test.
- [x] `ship-pr.ps1` step 3 blocks on the required checks only (`--watch --required`), decided from
      the repo's own ruleset answer and falling back to watching every check when it names none.
- [x] The mode may narrow mid-run but never widen -- a required workflow that had not registered
      when the probe asked is found one watch later.
- [x] The pre-merge wait report is handed the REQUIRED payload, so it no longer calls a check
      "governed the merge" while more checks are still to come.
- [x] New step 8, after the fold: wait for the non-required checks and print #831's own report over
      the full payload, with #1103's authored-failure relay. Never fails the ship.
- [x] The enqueue exit names the report it cannot give, since under a queue there is no fold here.
- [x] Step 3b uses the shared walk instead of its own copy.
- [x] Plugin mirrors regenerated (`build-shared-scripts.ps1`).

### TEST

- [x] `pr-issues.tests.ps1`: `Get-RequiredCheckNames` covered, every fixture including the
      two-required-check shape this repo cannot produce, plus the empty-is-a-state cases.
- [x] Source-text asserts for the orchestration a suite cannot drive live: the conditional
      `--required`, the fail-open branch, narrow-never-widen, and step 8 sitting BELOW the fold and
      below the resolved-issues check (asserted by offset, since that is the actual claim).
- [x] The one pre-existing assert that pinned step 3b's inline parse now pins the shared call and
      the absence of the old copy -- the claim it was written to make is unchanged.
- [x] Full suite run and `check-plugin-integrity.ps1`: 0 errors.


#### What the first live ship taught, and why the design changed (PR #1614)

The first `ship-pr` run of this change refused at step 3b -- correctly, on `8cfcd4f2` (PR #1613,
carrying a new test suite), which is the ordinary 25.3% case this branch does not claim to fix. But
its transcript showed something worse than the refusal:

```
  No required check is known, so this waits on EVERY check, exactly as before ...
  ...
ship-pr: every REQUIRED check is green. The rest are still watched, and reported at step 8.
```

Both lines, one run. The probe asked `gh pr checks --required` seconds after the push and got nothing
-- `branch-entry` and `claude-review` are separate workflows and register before ci.yml's jobs -- so
the watch fell open and covered everything, which is correct. But `--watch` picks up checks that
register after it starts, so that full watch ran to completion, the #1549 re-entry was never reached,
and the narrowing never happened. **The change was inert on the first lap it ran, and said otherwise.**

- [x] Read the mode from the trunk's BRANCH RULES instead (`Get-RequiredCheckContexts`), off the
      payload step 0b already fetches -- no registration race, no extra call, and it can say
      "requires nothing" definitively where the probe never could. The probe stays as the fall-back.
- [x] Separate `$watchNarrowed` from `$requiredWaitNames`: the first records what the watch DID, the
      second what the ruleset SAYS. Every claim after the wait now reads the first. Asking one
      variable both questions is exactly what produced the two contradictory lines above.
- [x] Two distinct fall-back sentences, since the ruleset can now tell "requires nothing" from
      "could not be read".
- [x] `Get-RequiredCheckContexts` covered, including readable-and-empty as a positive answer and the
      two-context shape this repo's own ruleset cannot produce.
- [x] Branch brought forward onto `origin/main` (the gate's own remedy), not shipped with
      `-SkipStaleCheck`: the voiding commit added `scripts/tests/cycle-autopark.tests.ps1`, which is
      precisely the hazard #1292 exists for.

#### And the SECOND live ship found the other half (PR #1614, attempt 2)

With the mode now read from the ruleset, the run correctly printed
`Blocking on the REQUIRED check(s) only: 'lint-en-tests'` -- and then refused after three watch
attempts, saying CI was still running. It was not:

```
  Blocking on the REQUIRED check(s) only: 'lint-en-tests'. ...
no required checks reported on the 'fix/1602-merge-on-required-green' branch
ship-pr: the WATCH dropped, not the run -- re-entering the wait (attempt 2 of 3).
```

Two defects, both mine, both only reachable on a real lap:

- `gh pr checks --watch --required` does **not** wait for a required check to appear. It reports
  `no required checks reported` and exits non-zero the moment it finds none registered.
- The registration wait polled `gh pr checks`, satisfied by ANY check -- and `branch-entry` and
  `claude-review` are separate workflows that register before ci.yml's jobs. So it returned happy
  while the required check was still absent. The loop's #1350 branch then matched only the wording
  `no checks reported`, so this arrived as a dropped socket rather than as a registration race.

- [x] `Wait-CheckRegistration` takes `-RequiredNames` and polls `--required` when given any, so it
      waits for the check the watch will actually block on. Empty leaves it byte-for-byte the old wait.
- [x] Both of gh's wordings matched, in the poll AND in the loop's #1350 branch (`no (required )?checks
      reported`). The two pre-existing asserts that pinned the narrow spelling now pin the wide one.
- [x] The mode is decided BEFORE the registration wait, since the wait cannot wait for the right
      thing before it knows what that is. Asserted by offset, because that is the actual claim.
- [x] The wait names its own subject, so a timeout on a narrowed wait does not read as "no CI at all"
      while the advisory checks were running the whole time.
- [x] One assert of my own was passing vacuously: `-like '*[string[]]$RequiredNames*'` opens a
      character class on `[`, so it matched a single character and never the type accelerator. Now
      `.Contains`, which is the trap this repo already documents from the other side.
#### The contradictions this change created, both repaired here

- [x] Nolan's lens recorded option C as DECLINED, and named a cost that does not exist: the merge
      has never been blocked by a red non-required check (#943), so the pre-merge wait decided when
      a sentence was printed. Updated with the reversal, the lap-level table, and the reason the
      August decision expired -- the staleness gate (#1292) did not exist when it was taken.
- [x] The `ship-pr` skill said step 3 "watches every check the PR has". Corrected, and the
      no-ruleset bullet now states explicitly that the fall-back keeps the old behaviour for it.

### DEPLOY: fix/1602-merge-on-required-green

`ship-pr` no longer holds the merge behind checks the ruleset does not require. Step 3 blocks on the
required checks only; the rest are waited for and reported at a new step 8, after the fold. That
stops the trunk from voiding a valid certificate during a wait nothing was gated on -- measured at
5.1% of 99 laps, and 62.5% of the tail-governed laps on the busiest day in the sample, each one
costing a whole further CI cycle. With no required check known the wait is byte-for-byte the old
one, so a repo without a ruleset is untouched.

**Score:** 4

#### What makes this deploy extra special

N/A -- `ship-pr` is the maintainer's shipping tool. No subscriber of anything reaches it, and the
consuming repos that do run it meet it as the same command with a shorter path to the merge.

**Score:** N/A

#### Pull Request

ship-pr merges as soon as every required check is green
