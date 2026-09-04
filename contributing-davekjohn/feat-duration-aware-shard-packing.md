## feat/duration-aware-shard-packing

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

[#1358](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1358) asked for per-suite
durations first and a file split second. The durations landed in PR #1364; this branch reads the first
real 4-lane tables they produced and finds the second half was aimed at the wrong thing.

**Three of four shards finish ABOVE their longest file**, by 41-95s on runs `33842129201` and
`33812817842`. A shard is bound by `max(its longest file, its lane-seconds / its lanes)` and only the
first term had ever been checked -- because it was measured on the four `check-plugin-integrity-*`
suites, which the stride happens to place in queue positions 3-4, the only positions where a duration
could be read off a log at all. So the evidence came entirely from the shards where the file *was*
binding, and was generalised to the ones where it is not.

Simulated over the measured 65-suite pool:

| | pool wall clock |
|---|---|
| stride + name order (what this was) | 305s |
| stride + longest-first | 266s |
| LPT bin-pack + name order | **307s -- worse than doing nothing** |
| LPT bin-pack + longest-first | **237s** |

Packing without reordering is a *loss*, which is why both halves land in one change: a balanced shard
whose heaviest file is dequeued last still ends on that file's tail, and balancing hands each shard a
heavier heaviest file than an unbalanced one did.

#### What this branch deliberately does NOT do

**Split any test file.** That was #1358's headline and it is now priced against real numbers rather
than reconstructions: at 237s the pool finally sits at its longest FILE, so a split buys the ~15s gap
to the 16-lane work bound, for the price of preserving 340 asserts across ~2,950 lines. Declined, and
written down in `ci.yml` and in the gate's own docstring so nobody re-derives it.

### CREATE

- [x] `Get-TestSuiteCostHints` in `scripts/lib/native-capture-lib.ps1` -- reads the optional
      `suite-durations.json` beside a test directory. Missing, unparseable, or holding no usable
      number all return `$null` with a warning, never a throw: the worst a bad hints file can do is a
      worse partition of the same suites, so refusing to run the tests over it would trade a real gate
      for a cosmetic one.
- [x] `Get-TestSuiteShardOrder` in the same lib -- LPT bin-pack into shards, and the same
      longest-first sequence as the dequeue order within one. No hints, or an empty table, is the
      stride byte for byte, which is what every consuming repo without the file gets.
- [x] The gate calls both in place of its inline stride. An untimed suite is charged the **maximum**
      recorded value, so a new suite opens in the first lanes and can never be the tail behind sixteen
      others; a new suite that turns out to be trivial pays nothing for starting early.
- [x] `scripts/tests/suite-durations.json` -- the committed CI reading, 65 suites, averaged over the
      two runs it names in its own `recordedFrom` block.
- [x] `scripts/maintenance/record-suite-durations.ps1` -- regenerates that file from a CI run's own
      tables. Done by hand twice on September 4 before it was written, which is this house's trigger
      for automating rather than documenting a procedure. It also fixes a failure the hand method has:
      `test-suite-gate.tests.ps1` prints a duration table over its own fixture, so a naive grep mixes
      1.4s fixtures into a table of real suites. Every row is checked against the suites that exist.
- [x] The falsified claims corrected where they live -- the `SHARDING` docstring paragraph in the gate
      (which travels to consumers through two plugin mirrors) and the shard-matrix comment in
      `.github/workflows/ci.yml`. Both said a sharded job is `max(longest file) + provisioning` and
      that a duration-aware bin-pack "would reach that same wall, so recording durations to feed one
      buys nothing here."
- [x] Mirrors regenerated via `scripts/sync/build-shared-scripts.ps1` -- two copies of
      `native-capture-lib.ps1`.

### TEST

- [x] `scripts/tests/ci-shard.tests.ps1` extended from 46 to **74 asserts**, all passing. The new ones
      are mostly direct calls on `Get-TestSuiteShardOrder` rather than gate runs, deliberately: the
      claim here is about ORDER as well as membership, and twelve trivial fixtures all finish in
      milliseconds, so their completion order is a race rather than a reading.
- [x] The property that must hold whatever the numbers say is asserted through a **real gate run**:
      with a hints file present the four shards still run all twelve fixture suites, exactly once each,
      and no longer in the stride's arrangement -- which is also the proof the gate reads the file.
- [x] Degradation asserted in every direction a hints file can be wrong: absent, unparseable JSON, no
      `seconds` map, non-numeric, zero, and negative. Zero is called out on its own because it is the
      one bad value that would *sort a suite to the very back of the queue* instead of dropping it.
- [x] Determinism and the tie-break asserted, because a red shard has to stay re-runnable by hand from
      two integers: equal costs fall back to the name sort, so the key is a total order.
- [x] This repo's own `suite-durations.json` asserted for **format only, never freshness** -- a stale
      entry is ignored and a missing one is charged the maximum, so gating on either would break the
      trunk the moment somebody adds a suite, to protect against a cost the design already absorbs.
- [x] The regeneration script was **run against the two runs it names**, and reproduced the committed
      file exactly (65 rows from each, pool total 3552s). Running it rather than shipping it found
      three defects a review would not have:
      - a bare `gh ... 2>&1`, which `shared-scripts.tests.ps1` catches for the whole tree -- under
        `$ErrorActionPreference = 'Stop'` a native command's redirected stderr arrives as an
        ErrorRecord and kills the script on a progress line. Replaced with `Invoke-NativeCapture`;
      - `powershell -File` does **not** split a comma-separated argument into an array, so
        `-RunId a,b` bound one string and gh 404'd on a run id nobody typed. The script splits the
        ids itself, so the `-File` and `-Command` forms agree;
      - `-f` formats with the current culture, so the pool's heaviest suite printed as `236,8s` on
        this machine -- a figure that reads as wrong everywhere it is pasted, out of a script whose
        whole job is producing figures. Invariant culture now.
- [x] Lint gate green (`check-plugin-integrity.ps1`, 0 errors over 31 checks), full suite gate green
      via `open-pr.ps1`.

### DEPLOY: feat/duration-aware-shard-packing

`Invoke-TestSuiteGate` now packs its shards and orders each shard's queue from recorded per-suite CI
durations, instead of striding over a list sorted by filename. On the measured 65-suite pool that is
**305s -> 237s**, and it touches no test, no assert and no scenario.

**It closes a claim this repo made three times and never tested where it mattered.** `ci.yml`, the
gate's own docstring and the entry directly above this one all said a sharded job is
`max(longest file) + provisioning`, and drew from it that a duration-aware bin-pack "would reach that
same wall -- which is why neither was built." Read off the first real per-suite tables (#1364), **three
of four shards finished 41-95s above their longest file**: shard 3 ran 317s with a 221.8s heaviest
file. The bound is `max(longest file, lane-seconds / lanes)` and only the first term had ever been
checked, because the only durations anybody could read off a log came from queue positions 3-4 -- the
shards where the file genuinely is binding.

**Both halves were needed, and that is the result worth keeping.** Simulated over the pool: stride +
name order 305s, stride + longest-first 266s, **LPT pack + name order 307s -- worse than doing
nothing** -- and LPT pack + longest-first 237s. A balanced shard whose heaviest file is dequeued last
still ends on that file's tail, so packing alone hands each shard a heavier heaviest file for no gain.
Measured instance of the cost of the old order: `new-branch.tests.ps1` is alphabetically late, drew a
lane at +40.9s, ran 249.2s, and set its shard's 290s makespan single-handedly.

**The durations are a HINT and never a contract**, which is the whole safety argument for persisting
anything at all. Every `*.tests.ps1` in the directory runs exactly once across the shards whether or
not it appears in the file; a listed suite that no longer exists is ignored; an untimed suite is
charged the maximum, so it opens in the first lanes rather than trailing sixteen others; and a missing,
unparseable or empty file falls back to the stride. Stale data can cost wall clock, never coverage.

**And the file is committed rather than written by the gate**, because the only durations worth packing
a hosted runner from are a hosted runner's -- these suites run 3.6-4.0x faster on a workstation and the
ratio is *not* uniform (`entry-scaffold` is ~11x). A gate that refreshed the file from whatever machine
last ran it would pack CI off workstation figures and land worse than no data at all.
`scripts/maintenance/record-suite-durations.ps1` regenerates it from a CI run's own tables and names
those runs in the file.

**#1358's headline is declined on the strength of this, not deferred.** At 237s the pool is finally at
its longest file, so splitting that file buys the ~15s gap to the 16-lane work bound -- for the price
of preserving 340 asserts across ~2,950 lines, which is the trade #714 refused. The arithmetic is now
in `ci.yml` and in the gate docstring rather than in an issue thread, including why the shard count
still does not go up: another runner lowers only the second term.

**Score:** 3

#### What makes this deploy extra special

A subscriber gets the packing itself through the two plugin mirrors of `native-capture-lib.ps1`, and
gets it **inert**: with no `suite-durations.json` beside their suites the gate strides exactly as
before, same files, same order, same coverage. What they gain is the option -- drop a durations file in
and their own sharded gate packs and orders itself -- plus a docstring that no longer tells them a
duration-aware assignment cannot help, and now carries the arithmetic for when another shard stops
paying.

**Score:** 3

#### Pull Request

Pack and order the test shards by recorded duration
