## feat/gate-records-per-suite-durations

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

Issue [#1358](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1358)'s **retitled**
prerequisite: *"first make the gate record per-suite durations."* @maikel-bwj renamed the issue to ask for
this after PR #1362 showed that the per-suite figures everyone had been quoting about this pool were
reconstructions.

`Invoke-TestSuiteGate` timed only the whole pool. It also buffers each suite's output until that suite
exits -- so the only per-suite signal a log carried was the timestamp of a completed suite's first line,
i.e. a **finish** time. Subtracting the pool's start from it yields a duration only for a suite that
started at `t0`, meaning one of the first `-MaxParallel` dequeued, and nothing in the arithmetic says so.

Measured cost of leaving that implicit: #1358 reported a five-file plateau that has four members. The
method was applied correctly to the four `check-plugin-integrity-*` suites, which really do sit in the
opening lanes, and then extended to two suites sitting 5th and 9th in a 4-lane queue -- reading their lane
wait as runtime. `entry-scaffold` was reported at 189s and runs 17.0s standalone.

#### Why this lands before any split, not after

The split is priced off per-suite durations. While those durations are reconstructions, the price is a
guess -- and the first real recording (below) already moves the target set. So this is the prerequisite in
the literal sense: it is not worth arguing about which files to split until the gate says which files are
expensive.

### CREATE

- [x] `../scripts/lib/native-capture-lib.ps1`: `$suiteTimings` records, per suite, the **duration** and
      the **offset at which its lane opened**. Both, deliberately -- a duration alone still cannot be
      checked against the pool's makespan by a reader who does not know when the suite began, and the
      offset is what makes "this suite waited for a lane" visible instead of inferable.
- [x] Recorded at the reap, which is the only moment the loop holds a suite's start and its finish at
      once; after `$running.Remove` the start offset is gone.
- [x] A table after the pool, **slowest first**, marking the one suite that **set the makespan** -- the
      only suite whose shortening moves the total, which is #714's finding. Printed before the verdict so
      the verdict stays the last line a session copies.
- [x] The header states the trap in place: *"'started' is when a LANE OPENED, not when the suite was
      queued: a late start is lane wait, not runtime."*
- [x] `Format-GateSeconds` gains an optional `-Decimals` (default **0**, unchanged for every existing
      caller -- a test pins `0.4 -> '0'`). The table passes 1: most suites here finish under a second and
      a column of `0s` rows records nothing. Still routed through the invariant culture, because that is
      the entire purpose of that function (#1159).
- [x] The `== name ==` per-suite header is deliberately **untouched**. Three asserts match it exactly to
      prove a suite's output stays grouped with its own header; appending a figure there would have
      required loosening the asserts that guard the grouping, for no gain the table does not already give.
- [x] Both plugin mirrors regenerated with `../scripts/sync/build-shared-scripts.ps1` -- this lib is
      registered twice (`native-capture-lib`, `native-capture-lib-shopify`) and check 8 holds all three
      byte-identical.

### TEST

- [x] Scenario 4b in `../scripts/tests/test-suite-gate.tests.ps1`, riding scenario 4's existing six-suite
      fixture rather than building its own, because **the serial run is the perfect discriminator**: with
      `-MaxParallel 1`, the last suite's lane opens around +7s and it runs ~1.2s. A duration column
      holding finish times would read ~8.5s for it. Measured in the run: **largest offset +7.3s, largest
      duration 1.4s** -- a 6x separation no timing noise can bridge. That is the assert that would have
      caught the original defect.
- [x] Plus: one row per suite, ordered slowest first, **exactly one** makespan marker, and the three
      pieces of prose a reader needs (what the table is, that it is recorded rather than reconstructed,
      and what the offset means).
- [x] `Format-GateSeconds -Decimals 1` asserted **under nl-NL**, where the decimal separator is a comma --
      a culture leak would print `1,2` and hand an English reader a thousands separator instead of a
      decimal point, which is #1159's defect one digit further down. The default's `0.4 -> '0'` is
      re-asserted alongside it.
- [x] `test-suite-gate.tests.ps1`: **67 pass, 0 fail.**
- [x] Full local gate (lint + all 65 suites) via `open-pr.ps1`, then the same gate as CI.

#### The first real recording, and it already moves the target

All 65 suites, **30 lanes on a 32-core workstation**, total 91s. Stated because a duration from this pool
is a draw from a distribution that depends on the lane count, which is this document's own standing rule:

| suite | duration | lane opened |
|---|---|---|
| `new-branch.tests.ps1` | **89.7s** | +1.1s **<-- set the makespan** |
| `check-plugin-integrity-links.tests.ps1` | 83.8s | +0.2s |
| `check-plugin-integrity-docs.tests.ps1` | 82.8s | +0.2s |
| `fold-changelog.tests.ps1` | 78.2s | +0.3s |
| `check-plugin-integrity-entries.tests.ps1` | 78.1s | +0.2s |
| `sync-main.tests.ps1` | 69.4s | +13.8s |
| `prune-merged.tests.ps1` | 65.1s | +2.8s |
| `check-plugin-integrity-commands.tests.ps1` | 61.1s | +0.2s |
| `bootstrap-drift.tests.ps1` | 58.8s | +0.1s |
| `roster-sync.tests.ps1` | 57.7s | +6.4s |
| `shared-scripts.tests.ps1` | 54.3s | +12.5s |
| `script-contract.tests.ps1` | 53.7s | +8.9s |

Two things fall out of it immediately, and neither was visible before:

1. **`new-branch` sets the makespan, not `check-plugin-integrity-links`.** #1358 named links as the top
   file with new-branch "right behind it"; recorded, the order is the other way round.
2. **The band is at least a dozen files, not five.** `fold-changelog`, `sync-main`, `prune-merged`,
   `bootstrap-drift`, `roster-sync`, `shared-scripts` and `script-contract` are all in it and appear
   nowhere in #1358's list -- which is exactly why the retitle says *"the band of heavy suite files"*
   rather than naming five.

This is a 30-lane workstation reading and **not** the 4-lane CI shape the required check runs; the two are
different regimes (#1351 measured 3.7x between them). CI now prints its own table per shard, so the
comparison is a log read rather than an exercise.

### DEPLOY: feat/gate-records-per-suite-durations

The test gate now reports **how long each suite took**, not just the pool total. After the suites finish it
prints a table sorted slowest first, and marks the one suite that set the run's wall clock -- the only one
whose shortening moves the total.

Each row carries a second figure that matters more than it looks: **when that suite's lane opened**. The
gate runs suites in parallel and holds each one's output until it exits, so a log timestamp has always been
a *finish* time. Reading a duration out of it silently assumes the suite started when the run did, which is
only true for the first few. That assumption produced a real error: a five-file "plateau" reported against
this pool had four members, because two of the five were 5th and 9th in a four-lane queue and their lane
wait was being read as runtime. One of them was reported at 189s and takes 17s.

The header says so where it can be seen -- *"a late start is lane wait, not runtime"* -- and the numbers no
longer need reconstructing. The first recorded run already reorders the top of the list and shows the
expensive band is around a dozen suites rather than five.

**Score:** 3

#### What makes this deploy extra special

It is a measuring instrument shipped *because* a measurement went wrong, and it was asked for by the person
whose issue the measurement contradicted -- @maikel-bwj retitled #1358 to put this first rather than
defending the original numbers. The test for it is the nice part: the serial six-suite run separates a
recorded duration from a reconstructed one by 6x (largest lane offset +7.3s against a largest duration of
1.4s), so the assert fails loudly if anyone ever reintroduces the finish-time reading.

**Score:** N/A

#### Pull Request

Record per-suite durations in the test gate
