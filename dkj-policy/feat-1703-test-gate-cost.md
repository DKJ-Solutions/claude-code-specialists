## feat/1703-test-gate-cost

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Answering #1703: run the test gate unpiped, keep the full 84-suite table, and take the narrow
fix question 1 admits. The issue reserves the gate-SCOPE question for Dave and this branch does not
touch it.

#### What the measurement overturned

The obvious first hypothesis -- that `suite-durations.json` going stale (65 of 84 suites listed, 19
charged the 236.8s maximum) had wrecked the queue order -- is **true as a fact and worth ~13s of 1,806**.
The scheduler runs at **99.2% of its theoretical lower bound**, so neither the order nor the pack is the
lever. Recorded rather than quietly dropped, because it is the repair a reader would reach for first.

### CREATE

- [x] Run the gate unpiped and keep the whole per-suite table -- TWICE, 12 and 16 lanes, both 84/84 green
- [x] Refresh `scripts/tests/suite-durations.json` from CI runs 34345773827 / 34345361764 / 34334137051
      via the shipped `record-suite-durations.ps1` -- 65 -> 84 suites listed, pool 4,661s
- [x] Record the measurement in Nolan's lens, this repo's home for one
- [x] File the inverted local-to-CI ratio (#1713) and the missing progress index (#1717) rather than
      widening this branch into plugin payload
- [~] No scheduler change: measured at 99.2% and 100.0% of its floor, so there is nothing to win
- [~] No orphan-reaper: the 40/36 resident counts were mid-drain readings, retracted before they became
      a finding (quiet machine shows 4, all parented by Code.exe/claude.exe)


### TEST

- [x] Full gate unpiped, n=2: **84/84 in 1,806s (12 lanes)** and **84/84 in 1,021s (16 lanes)**
- [x] Third reading from open-pr's own gate: 84/84 in 923s (16 lanes) -- the ~10% noise band
- [x] `ci-shard.tests.ps1` green (74 asserts) against the refreshed hints file -- it is the suite that
      asserts the real `suite-durations.json` parses and holds usable durations
- [x] `check-plugin-integrity-links.tests.ps1` solo: 141 asserts, 759.1s -- the contention/machine split
- [x] Both hint sets simulated through the real `Get-TestSuiteShardOrder` pack and scored on today's
      durations: 374s either way, so the refresh is recorded as a 0s change

### DEPLOY: feat/1703-test-gate-cost

[#1703](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1703) reported the `open-pr` test
gate at *"~9 hours of CPU per PR"* and said plainly that everything in it was inference until somebody ran
the gate **unpiped** and kept the full table — the caller had piped through `Select-Object -Last 40`, which
truncated exactly the rows above 55.8s. Two full tables now exist, both green, both on the 18-thread
workstation:

| | lanes | makespan | lane-seconds | longest file | lower bound | makespan ÷ bound |
|---|---|---|---|---|---|---|
| reading 1 | 12 | 1,806s | 21,512s | 1,617.1s | 1,793s | 100.8% |
| reading 2 | 16 | 1,021s | 16,008s | 1,020.7s | 1,021s | 100.0% |

**The scheduler is at its floor — 99.2% and 100.0% of the theoretical minimum — so the queue order is not
the lever and neither is the pack.** That is the half worth carrying, because everything visible points the
other way. `scripts/tests/suite-durations.json` genuinely had gone stale: 65 of 84 suites listed, so the
charge-the-maximum rule priced 19 of them at 236.8s each — **4,499s of phantom weight against a 3,552s real
pool**. Trivial suites bought the opening lanes on it (`claim-issue` 21.0s dequeued at +0.9s) while
`teardown` (582.9s) waited until +1,175.1s. All true, and together worth **at most 13s of 1,806**. The
repair a reader reaches for first would have satisfied the report and returned nothing.

**The two readings sit in different regimes, which is why one would have been the wrong evidence.** At 12
lanes the pool is work-bound; at 16 it is critical-path-bound and simply **is**
`check-plugin-integrity-links.tests.ps1` — 1,020.7s against a 1,021s makespan. Past ~16 lanes this machine
gains nothing at all.

The hints file was refreshed anyway, from CI runs 34345773827 / 34345361764 / 34334137051 (3-run mean, 84 of
84, pool 4,661s), **and the commit says 0s**: both hint sets were put through the real
`Get-TestSuiteShardOrder` pack and scored against today's durations, and both give a 374s binding shard,
because `new-branch.tests.ps1` alone is 373.8s against a 291s work bound. **CI is critical-path-bound on one
file too, and no partition beats a file.** That prices what
[#1358](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1358) left open — it asked for a
4-lane CI table before anyone costed the split, and the gap a split of `new-branch` could buy is **83s, 22%
of the shard**. Note the two machines disagree about *which* file to split — CI says `new-branch`, this
workstation says `check-plugin-integrity-links` — and CI is the one that blocks a merge. A truthful table is
what the next simulation reads, which is the only reason this one could be run.

**Where the work is**, the issue's question 1: six files carry **8,140s of reading 1's 21,512 lane-seconds,
37.8%**, all of it cold `powershell` children each running a full lint over a fixture —
`check-plugin-integrity-links` 66 invocations, `new-branch` 56, `fold-changelog` 54, 44 each for the other
three.

**And lane-seconds are not CPU.** `wall × lanes` charges a blocked lane as though it were working. The proof
is in the pair above: lane-seconds **fell** from 21,512 to 16,008 when lanes went **up** from 12 to 16, on
one machine, one day, one tree. Work does not do that; queueing does. On the heaviest file: **290.9s on CI**,
**759.1s alone here**, 1,020.7s at 16 lanes, 1,617.1s at 12 on a busier machine — so 2.61× is the machine and
the rest is contention. The same 84 suites are 4,661 lane-seconds on CI and 16,008-21,512 here.

Three things measured and deliberately not repaired here. The local-to-CI ratio is stated **backwards** in
three copies of a shipped lib (*"3.6-4.0x faster on a developer machine"* against 2.61× slower measured) —
[#1713](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1713), because it is plugin payload
under the shared-scripts drift lint and replacing one wrong constant with another off n=1 is the error it
describes. The gate prints no progress index, so a 15-30 minute run cannot be told from a wedged one —
[#1717](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1717). And a resident-interpreter
count taken mid-drain is not an orphan count: reading 1 opened at 40 and 36 were still up seconds after it
returned, which reads exactly like [#1464](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1464)
and is not it — quiet, the machine holds four, all parented by `Code.exe` or `claude.exe`. Both runs exited
0; #1464 is about a killed one. Retracted before it became a finding.

The gate's scope — why 84 suites run for a one-section README diff — is untouched. #1703 reserves it for
Dave, correctly: it asks what the gate is *for*, and changing it changes a safety guard.

**Score:** 3

#### What makes this deploy extra special

N/A — this reaches no subscriber. The measurement lives in this repo's own lens, and
`scripts/tests/suite-durations.json` is a local hint file the gate reads here; a consumer who copies the lib
and has no such file gets the stride, unchanged. Nothing in any plugin moves, and the gate behaves
identically — measured at 374s either way. The two consumer-facing threads, the backwards ratio in the two
plugin mirrors and the missing progress index, are #1713 and #1717 and not this branch.

**Score:** N/A

#### Pull Request

The test gate's nine hours, measured twice: the scheduler is at its floor and the lever is one file
