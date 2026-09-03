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
slowest FILE, so neither can pay.**

#### Most of what this branch set out to do landed on the trunk while it was open

`2bd31203` (#1358, September 3, 2026) reached the same conclusion independently and carried it further:
it corrected `ci.yml`'s stale `~51s` floor to the measured CI figure, documented the reconstruction
trap, corrected the plateau to four files, and took ~12.6% off the four heavy suites by removing a
duplicated AST walk from the lint they invoke. **The branch was reduced to what that commit did not
cover rather than rebased on top of it and re-asserted** — the whole `ci.yml` block and the whole lens
section were resolved to the trunk's version, because theirs is better sourced than what was here.

What was left is the **portable** half. #1358's work is entirely repo-local (`ci.yml`, a lens, the lint
script); `Invoke-TestSuiteGate`'s own SHARDING docstring is the shared source that ships to consumers
through two plugin mirrors, and it still told them the gate is *contention-bound* and that *"adding
lanes is close to linear"* — with nothing saying that reverses once the caller shards. That is the
default destination for a lesson learned here, per `CLAUDE.md`, and nobody had written it.

#### And one figure of this branch's own was wrong

This branch first reported the heaviest suite at **237.0s standalone on an 18-core workstation**, and
built its central claim on that figure agreeing with the ~232s CI reading — *"no faster machine touches
it."* **Both are withdrawn.** The reading was contaminated: it was taken while this same session ran
lint gates and git concurrently. #1358 measures that suite at **58.7s** on an idle box, and establishes
a local-to-CI ratio of **3.6-4.0x** — which reproduces the CI figure exactly (58.7 x 4 ≈ 235s) and means
the file *is* machine-sensitive. The decision is unaffected, because it only ever needed the exact CI
side; but the reasoning offered for it was wrong, and a corroborating measurement taken on a busy
machine is worse than none.

### CREATE

- [x] Add the portable half to `Invoke-TestSuiteGate`'s SHARDING docstring in
      `scripts/lib/native-capture-lib.ps1`: sharding hands the gate back to the #714 critical-path
      regime, so adding lanes pays only while a shard's lane-seconds exceed its longest file and stops
      dead there. Written as a question of scale, so the two paragraphs are not read as contradicting
      each other — the trap is quoting the contention-bound one after the shard count has crossed over.
- [x] Name the lever that is NOT another runner, in the same place: the heavy suites are ~100% their own
      lint invocations, and #1358 took ~12.6% off all four by fixing the script they invoke, touching
      neither this function nor any partition. `#714`'s "split the slowest file" is one answer, not the
      only one.
- [x] Carry #1358's reconstruction warning into the docstring, because **this function is what makes the
      mistake easy**: it records no per-suite duration and buffers output until a suite completes, so a
      log timestamp is a finish time and subtracting the shard start is valid only for queue positions
      1..MaxParallel. With the 3.6-4.0x local-to-CI ratio beside it, so a standalone reading is not
      quoted as a CI figure again.
- [x] Mirror all of it into the two plugins via `scripts/sync/build-shared-scripts.ps1`.
- [x] Correct `~35s` to `~20s` in `ci.yml`'s floor block. Not a duplicate: the trunk's own rewrite says
      `max(longest file) + ~20s` two paragraphs below a surviving `~35s of provisioning`, so the block
      contradicted itself.
- [~] Drop this branch's `ci.yml` rewrite and its Nolan lens section entirely. Resolved to the trunk's
      version — see PLAN. Re-asserting the same correction in different words is how two documents start
      disagreeing about one measurement.
- [~] Drop the shard-count simulation (263s at four shards, 232s flat from six, LPT no better, five worse
      than four). Its conclusion is already on the trunk in prose, and its inputs were the reconstruction
      #1358 discredited — so it would land numbers this branch cannot stand behind for a claim that is
      already made.

### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors, including the shared-script mirror check over all three
      copies of the lib.
- [x] Full suite pool green under `open-pr`'s gate — see the PR body for the figure and its lane count.
- [~] No new test. Every change here is docstring and comment prose; `ci-shard.tests.ps1` already pins
      the matrix length against `-ShardCount`, and neither number moved.

### DEPLOY: docs/shard-floor-is-the-slowest-file

[#1354](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1354) reported that the shard
stride balances suite **count** and not **cost**, so the required check's wall clock is set by one shard
— 5m01s against 2m42s on the first sharded run. The mechanism is right, and **both repairs it proposed
stop at the same wall: the slowest FILE.** A shard whose longest file was 183s took 183s; one whose
longest was 206s took 207s. Those are exact rather than reconstructed, because the stride puts the four
`check-plugin-integrity-*` suites in queue positions 3-4 where they start at `t0`. So a sharded job is
`max(longest file)` plus provisioning, no partition of whole files beats its own longest member, and a
duration-aware bin-pack would reach that same wall — which is why neither was built.

**The repo-local half of this answer landed independently while this branch was open**
([#1358](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1358), `2bd31203`): the stale
`~51s` floor in `ci.yml` corrected to the measured CI figure, the reconstruction trap written down, the
plateau corrected from five files to four, and ~12.6% taken off all four heavy suites by removing a
duplicated AST walk from the lint they invoke. This branch was **reduced to the residual** rather than
rebased on top and re-asserted; its own `ci.yml` rewrite and lens section were dropped in favour of the
trunk's, which is better sourced.

What remained was the **portable** half, and it is the reason this PR exists. #1358's changes are all
repo-local, while `Invoke-TestSuiteGate`'s SHARDING docstring travels to consumers through two plugin
mirrors — and it still told them the gate is *contention-bound*, that *"adding lanes is close to
linear,"* and nothing about that reversing the moment they shard. It now reads as a question of scale:
adding lanes pays while a shard's lane-seconds exceed its longest file and stops dead at that file, and
the trap is quoting the first paragraph after the shard count has crossed into the second. It also names
the lever that is **not** another runner — those suites are ~100% their own lint invocations, and #1358
bought its 12.6% inside the script they invoke without touching any partition — and it carries the
reconstruction warning, because this function is precisely what makes that mistake easy: it records no
per-suite duration and buffers output until a suite completes, so a log timestamp is a finish time.

**One figure of this branch's own was withdrawn rather than shipped.** It first reported the heaviest
suite at 237.0s standalone on an 18-core workstation and argued from that agreeing with the CI reading
that no faster machine could touch it. The reading was taken while this session ran gates concurrently;
#1358's idle measurement is 58.7s, with a local-to-CI ratio of 3.6-4.0x that reproduces the CI figure
exactly. The file is machine-sensitive, the conclusion never depended on it, and the argument offered
for it was wrong. Also corrected: `~35s` of per-runner provisioning to the measured `~20s`, which the
trunk's own block already stated two paragraphs lower.

**Score:** 2

#### What makes this deploy extra special

A subscriber gets the corrected `Invoke-TestSuiteGate` docstring in the plugin mirror — the half that
tells them when adding a shard stops paying, what to reach for instead, and how not to mis-measure it.
That is the question a consumer staring at a slow required check actually asks, and the old text
answered it in the wrong direction. Nothing they run changes.

**Score:** 2

#### Pull Request

Correct the shard floor: the required check is pinned to the slowest FILE, not to the partition
