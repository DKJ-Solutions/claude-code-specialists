## Development cycle: `fix/ci-concurrency-supersedes-pr-runs-v1` · 20260826-173933

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Every push to a PR branch starts a full CI run while the previous one is still going, because `ci.yml`
declares no `concurrency` group. `on: pull_request` fires on `synchronize`, so a branch that is pushed
three times holds three concurrent runs of the same job -- each one a full lint gate plus every test
suite on `windows-latest`, where minutes bill double.

- [x] Measured the pressure rather than taking it on the report. `ci.yml` had no `concurrency` key at
      any level, and the repo-wide queue at the time held 2 runs with 0 in progress -- so the backlog is
      self-inflicted by redundant runs, not by a runner shortage.
- [x] Established that `cancel-in-progress` must NOT be a plain `true`, and found the concrete reason in
      this repo rather than in general advice. A PR run and a push-to-`main` run can never share a group
      -- `github.ref` is `refs/pull/N/merge` against `refs/heads/main` -- so the condition is not what
      keeps them apart. What it protects is the trunk: `ship-pr.ps1` pushes to `main` twice per branch,
      the merge commit and then the fold commit, and under `true` the second would cancel the first.
- [x] Measured that gap on the real history: 6 seconds on #932 (16:38:05 -> 16:38:11) and 7 minutes on
      #933 (17:01:37 -> 17:08:33). At 6 seconds the merge commit's run would be cancelled essentially
      every time, leaving the commit the `main` ruleset gates on with a check that never reported.

#### Not in scope on this branch

Whether `lint-en-tests` genuinely needs `windows-latest` was asked as ANALYSIS only and is deliberately
not implemented here. It is reported in the session, not built.

### CREATE

- [x] A top-level `concurrency` block in `.github/workflows/ci.yml`, keyed on the workflow and the ref,
      with `cancel-in-progress` conditional on `github.event_name == 'pull_request'`. Placed directly
      under `on:`, which is what it governs.
- [x] The comment above it says WHY and not WHAT, matching the file's existing style: it carries the
      measured merge-to-fold gap and names the failure a plain `true` would cause, rather than
      explaining what `concurrency` is.

### TEST

- [x] Lint gate green and every test suite green -- see the DEPLOY section for the counts.
- [~] No new automated assert. Dropped with the reason: nothing in `scripts/tests/` reads
      `.github/workflows/*.yml`, and an assert that re-states the YAML it guards would go red on every
      legitimate edit without proving GitHub honours the key. The behaviour is only observable on
      GitHub, so the real verification is the next PR that gets pushed twice.

### DEPLOY: `fix/ci-concurrency-supersedes-pr-runs-v1`

`.github/workflows/ci.yml` now declares a `concurrency` group keyed on the workflow and the ref, so one
run per ref supersedes the last instead of queueing beside it. `on: pull_request` fires on `synchronize`,
which meant every push to an open branch started a second full run of `lint-en-tests` -- the lint gate
plus all 52 suites on `windows-latest` -- while the previous one was still going; PR #933 held three
consecutive runs of one branch at ~7m40s each, on a runner whose minutes bill double. Superseded PR runs
are cancelled now. Runs for a push to `main` are not: `cancel-in-progress` is conditional on the event
being a pull request, because `ship-pr.ps1` pushes to the trunk twice per branch -- the merge commit and
then the fold commit, measured 6s apart on #932 -- and a plain `true` would have the fold cancel the
merge commit's own run, leaving the commit the `main` ruleset gates on with a check that never reported.

**Score:** 2

#### What makes this deploy extra special

The interesting half is not the `concurrency` key, which is ordinary. It is that the obvious value for
`cancel-in-progress` is wrong here for a reason that cannot be read off the workflow file. `true` looks
safe because a PR run and a push-to-`main` run can never collide -- `github.ref` is `refs/pull/N/merge`
against `refs/heads/main`, so they are always in different groups. That reasoning is correct and still
leads to the wrong setting, because the collision that matters is `main` against `main`: this repo pushes
to its own trunk twice per branch, and the second push is the fold. Measured on the real history, that
gap was 6 seconds on #932 and 7 minutes on #933 -- at 6 seconds the merge commit's gate would be
cancelled essentially every time.

So the comment above the block carries that measurement rather than an explanation of what `concurrency`
does, which is the house style in that file and the only part of this change a later reader cannot
reconstruct. A cancelled check is not a passing check, and the failure would have been silent: green
everywhere, with the one commit the ruleset actually guards never having been gated.

**Score:** 2

#### Pull Request

every PR push starts a full CI run while the previous one is still going