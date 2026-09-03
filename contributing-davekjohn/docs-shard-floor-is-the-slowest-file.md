## docs/shard-floor-is-the-slowest-file

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

Answer [#1354](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1354) with measurement.
It reports a real mechanism — the stride balances suite COUNT, not COST — and asks that the spread be
read over several runs before either of its two repairs is built. Read: **both are floored by the
slowest FILE, so neither can pay.** This branch therefore builds neither, corrects the stale figure that
made them look affordable, and records the measurement.

#### What the measurement said

The four `check-plugin-integrity-*` suites sit at queue positions 3-4 of their shards, so they start at
`t0` and their durations are exact rather than reconstructed. The heaviest,
`check-plugin-integrity-links.tests.ps1`, is **213-251s** on the runner and **237.0s standalone on an
18-core workstation with the whole box to itself** — the two agreeing is the finding, because its 52
invocations of the real lint are a serial chain of child processes that no lane count, shard count or
faster machine reaches. Simulated over per-suite durations reconstructed from both runs, the max shard is
263s at four shards and **232s at six, eight, ten and twelve — flat, because 232s IS the longest file**.
A duration-aware bin-pack reaches the same 232s. Five shards is *worse* than four.

**The simulation is directional only** — the reconstruction behind it is sound just for the four suites
that start at `t0`, and the branch withdraws the rest rather than shipping it (see TEST). The decision
needs only that exact half: max shard measured 283s and 286s against a 232s longest file, so at most
~50s is available to either proposal.

### CREATE

- [x] Correct the floor claim in `.github/workflows/ci.yml`. It read `~51s for the heaviest of the
      check-plugin-integrity-* four`, which mis-read #714 — ~51s was all four **together across four
      lanes on a workstation** in August 2026 — and has since gone stale in both directions. Replaced
      with the measured figure, the simulation that declines both of #1354's options, and the plateau.
- [x] Correct the `~35s` per-runner provisioning assumption in the same block to the measured **~20s**
      (job duration minus the gate's own reported seconds, eight shard jobs across two runs).
- [x] Add the portable half to `Invoke-TestSuiteGate`'s SHARDING docstring in
      `scripts/lib/native-capture-lib.ps1`: sharding hands the gate straight back to the #714
      critical-path regime, so adding lanes pays only while a shard's lane-seconds exceed its longest
      file and stops dead at that file. Written as a scale question so the two paragraphs do not read as
      contradicting each other.
- [x] Mirror it into the two plugins via `scripts/sync/build-shared-scripts.ps1`.
- [x] Record the repo-specific measurement in `.claude/specialists/lenses/06-25-extension.md` — the
      exact per-file table, the reconstruction and its validation, the shard-count simulation, and the
      plateau — beside the August 16 finding it is the recurrence of.
- [~] Do NOT sweep the same `~51s` in `04-18-extension.md`, `05-15-extension.md`,
      `native-capture-lib.ps1` and `check-plugin-integrity.ps1`. Dropped deliberately: there the figure
      is **correct as history**, recording what the #714 split bought on the day. Only `ci.yml` was using
      it as a live floor for a decision.
- [~] Do NOT raise the shard count and do NOT build the bin-pack. Dropped as the measured answer, not as
      scope-trimming: six shards captures the entire available 31s of a ~298s check for +36% runner
      seconds, the bin-pack buys the same 232s plus new persisted state in a lib mirrored into two
      plugins, and the stride's max depends on which heavy files co-locate — it reshuffles whenever a
      suite is added, so a tuned number is luck with an expiry date.

### TEST

- [x] `check-plugin-integrity.ps1`: **0 errors**. Validates the new anchor cross-reference into the
      August 16 section and the two mirrors (`[shared-script] checked 49`).
- [x] Full suite pool green under `open-pr`'s gate — see the PR body for the figure and its lane count.
- [~] The reconstruction was NOT validated, and the branch says so rather than shipping the claim it
      started with. Its aggregate agreement (2840s and 2982s of lane-seconds against the 2968s measured
      independently on run 33798952362) is compensating error, not per-item accuracy: the inversion
      assumes a lane refills the instant a suite completes, and the gate prints the finished suite's
      captured output first. Measured counter-example, found by timing one standalone —
      `entry-scaffold.tests.ps1` reconstructs at 189s and runs in **32.2s**. Only the four suites at
      queue positions 3-4 are exact, because they start at `t0` and are not inferred at all; the
      decision rests on those and holds without the rest.
- [~] No new test. Dropped with the reason: every change here is comment, docstring and lens prose —
      `ci-shard.tests.ps1` already asserts the matrix length and `-ShardCount` agree, and neither number
      moved.

### DEPLOY: docs/shard-floor-is-the-slowest-file

[#1354](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1354) reported that the shard
stride balances suite **count** and not **cost**, so the required check's wall clock is set by one shard
— 5m01s against 2m42s on the first sharded run. The mechanism is right. **Both repairs it proposed were
declined, because both stop at the same wall: the slowest FILE.**

The floor was measured exactly rather than inferred. The four `check-plugin-integrity-*` suites sit at
queue positions 3-4, so they start at `t0` and their durations are read straight off the log: the
heaviest, `check-plugin-integrity-links.tests.ps1`, is **250.9s** and **212.5s** across the two runs —
and **237.0s standalone on an 18-core workstation with the whole box to itself**. Those two agreeing is
the finding: the file's 52 invocations of the real lint are a *serial* chain of child processes, so no
lane count, shard count or faster machine touches it. The shards say it directly too — a shard whose
longest file was 183s took **183s**, one whose longest was 206s took **207s**.

Per-suite durations were then reconstructed from both runs by inverting the gate's own schedule.
Simulated over that, the max shard is 263s at four shards and **232s at six, eight, ten and twelve —
flat, because 232s is the longest file**. A duration-aware bin-pack reaches the same 232s and not a
second better; it flattens the cheap shards *upward*, which cuts runner-seconds and not wall clock, so
it would buy new persisted state in a lib mirrored into two plugins for zero on the metric the issue is
about. Five shards comes out *worse* than four, because the stride's max depends on which heavy files
co-locate and the assignment reshuffles whenever a suite is added — so a tuned shard count is luck with
an expiry date.

**That simulation is reported for its shape and not for its digits, and the branch says so rather than
letting a later reader trust it.** The inversion assumes a lane refills the instant a suite completes;
it does not — the gate prints the finished suite's whole captured output first, so every *inferred* start
runs early and every inferred duration is inflated, worst where the suite is cheap. Caught by measuring
one standalone: `entry-scaffold.tests.ps1` reconstructs at 189s and takes **32.2s** alone. The aggregate
agreement that first looked like validation (2840s and 2982s of reconstructed lane-seconds against the
2968s measured independently on run 33798952362) is compensating error, not per-item accuracy.
**The decision survives because it needs only the exact half:** the longest file is 212.5-250.9s measured
at `t0`, the max shard measured 283s and 286s, and no partition of whole files beats its own longest
file — so the entire prize available to either proposal is **at most ~50s of a ~298s required check, for
+36% runner-seconds**.

**What #1354 got wrong was not the mechanism but the price, and the price came from this repo's own
comment.** `.github/workflows/ci.yml` claimed its floor was `~51s for the heaviest of the
check-plugin-integrity-* four`. That mis-read
[#714](https://github.com/DKJ-Solutions/claude-code-specialists/issues/714): **~51s was all four
together, across four lanes, on a workstation** in August 2026 — and it has since gone stale in both
directions, because those suites now run the lint **168** times where #714 measured 111 and the lint
itself grew checks 28, 29 and 30. Corrected here, together with the `~35s` per-runner provisioning
assumption in the same block, measured at **~20s**. The same figure elsewhere in the tree is
**correct as history** and deliberately untouched: only `ci.yml` was using it as a live floor.

`Invoke-TestSuiteGate`'s SHARDING docstring gains the portable half, mirrored into both plugins —
sharding hands the gate straight back to the #714 critical-path regime, so adding lanes pays only while
a shard's lane-seconds exceed its longest file and stops dead there. Written as a question of scale, so
the two paragraphs are not read as disagreeing: the trap is quoting the contention-bound one after the
shard count has already crossed over.

**The lever that would actually pay is filed rather than folded in**
([#1358](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1358))**.** Splitting the top
file alone only exposes whatever is behind it, so what moves the required check is splitting the *band*
of heavy files — #714's lever applying a second time to the files its own split created. **Three are
established and the rest of the list is not**: `links`, `docs` and `entries` are exact at `t0`, every
other candidate came from the rejected reconstruction, and the one checked standalone collapsed from
189s to 32.2s. So the first task in #1358 is to make the gate **record per-suite durations** — nothing in
the tree does today, which is why this measurement had to be inverted out of a log at all.

**Score:** 3

#### What makes this deploy extra special

A subscriber gets the corrected `Invoke-TestSuiteGate` docstring in the plugin mirror, which is the half
that tells them *when adding a shard stops paying* — the question a consumer staring at a slow required
check asks, and the one the old text answered in the wrong direction. Nothing they run changes.

**Score:** 2

#### Pull Request

Correct the shard floor: the required check is pinned to the slowest FILE, not to the partition
