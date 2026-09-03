## feat/shard-ci-suites

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

Issue #1351. Add a suite-subset parameter to Invoke-TestSuiteGate, then shard ci.yml into a matrix with lint-en-tests kept as a fail-closed summary job.

#### Why this and not the merge queue first

The convergence problem on [#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325)
is a geometric series in (CI duration / trunk cadence). Its denominator has been measured repeatedly;
its numerator never was. This branch attacks the numerator, needs no repo settings and nobody's
permission, and is a prerequisite for a queue rather than an alternative to it -- a queue at 15-minute
CI has a serial throughput of ~4 merges/hour against an observed trunk cadence of ~2.4-4/hour.

### CREATE

- [x] `Invoke-TestSuiteGate` takes `-Shard`/`-ShardCount`, partitions its own glob by a stride, and
      refuses a nonsensical pair instead of selecting nothing
- [x] `Get-TestCommands` entries run in shard 1 only, and an empty slice reports "more shards than
      suites" rather than "no suites found"
- [x] The opening line and the verdict line both name the slice, so a quoted figure carries its scope
- [x] `ci.yml` splits into `lint` + a 4-entry `suites` matrix + a `lint-en-tests` summary that fails
      closed; the required check name and the ruleset are untouched
- [x] Both plugin mirrors of the lib regenerated via `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `scripts/tests/ci-shard.tests.ps1` -- 46 asserts, green
- [x] The partition is asserted as a property over real gate runs (clean cover, balance, stride vs
      block, determinism), not as a text match on the lib
- [x] Negative-tested, six mutations, each producing exactly the targeted failure: `-ShardCount` 4->5,
      `if: always()` removed, the suites leg judged by `== "failure"`, the fold skip moved to job level,
      the range validation dropped, and the stride replaced by a contiguous block
- [x] Measured on this repo's own 64-suite pool: 16/16/16/16, one of the four heavy
      check-plugin-integrity suites per shard

### DEPLOY: feat/shard-ci-suites

The required `lint-en-tests` check spent 95% of its wall clock in one step, and that step was starved of
lanes rather than bound by its slowest file. Measured on run 33798952362: 12m23s of the check's 13m03s
was the test-suite step, which reported itself as `all 64 suites passed in 742s (4 lanes)`, while the
same pool takes ~200s on 16-18 lanes on a workstation. Normalised that is 2968 lane-seconds against
~3400 -- comparable total work, so the 3.7x difference is lane count, and `windows-latest` has four
cores. The [#714](https://github.com/DKJ-Solutions/claude-code-specialists/issues/714) regime, where the
gate's total equalled its slowest single file to a tenth of a second, does not hold on a hosted runner;
there it is contention-bound, which is the one regime where adding lanes is close to linear.

`Invoke-TestSuiteGate` therefore takes `-Shard`/`-ShardCount` and runs one slice of its own glob, and
`.github/workflows/ci.yml` splits into three jobs: `lint`, a four-entry `suites` matrix, and a
`lint-en-tests` summary. **The name is load-bearing** -- `main-ci-gate` requires a check called
`lint-en-tests` and GitHub names a check after the job reporting it, so keeping a job by that exact name
means this needs no ruleset edit and no repo-settings change. That is why it could land while the
merge-queue decision on [#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325) is
still open, and it is a prerequisite for that queue rather than an alternative to it: a queue at
15-minute CI has a serial throughput of about four merges an hour against an observed trunk cadence of
2.4-4.

The partition is a **stride, not a contiguous block**, and that is the design rather than a detail. The
pool's expensive suites are expensive because they share a subject, suites that share a subject share a
name prefix, and a name prefix sorts adjacently -- so a contiguous split puts all four
`check-plugin-integrity-*` suites in one shard while another runs sixteen cheap ones. A stride puts them
in four different shards without the gate having to know or store what anything costs; measured on the
real pool, 16/16/16/16 with one heavy suite each. It pays #714's fixture bill only once, because those
four build a fixture each in a per-process directory. Two integers rather than a list of suite names,
for the reason [#512](https://github.com/DKJ-Solutions/claude-code-specialists/issues/512) deleted the
inline loop this step used to hold: a list in the workflow drifts from the folder, two integers cannot.

**The hazard sharding adds is the summary job, and it is guarded in both directions.** A job that
`needs:` a failed job is *skipped*, not failed, and a skipped required check is not a reported failure --
so without `if: always()` a red shard produces no verdict at all, and without an explicit result
comparison `always()` produces a green one. Every leg is required to be `success`, so `skipped`,
`cancelled` and `neutral` all refuse, which is also why #1300's fold-commit shortcut stays on the step
rather than moving up to the job: a job-level condition would make a skipped leg legitimate, one
accepted non-success away from accepting the one that matters. `fail-fast` is false, because these
suites have a measured history of red-under-the-gate/green-alone
([#1033](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1033)) and losing three shards'
verdicts to learn one failed turns one re-run into four.

Pinned by `scripts/tests/ci-shard.tests.ps1` (46 asserts), which tests the partition as a property over
real gate runs -- a clean cover, balance, stride versus block, determinism -- rather than grepping the
lib for a modulo, and reads the matrix length and `-ShardCount` out of the workflow so the one mismatch
nothing else would notice fails here instead of quietly running four fifths of the pool for ever.

**Score:** 3

#### What makes this deploy extra special

N/A -- CI wall-clock in the source repo. A subscriber of a consuming service never sees it, and the
`-Shard`/`-ShardCount` parameter is inert for every caller that does not pass it.

**Score:** N/A

#### Pull Request

Shard the CI test suites across a matrix so the required check stops being lane-starved
