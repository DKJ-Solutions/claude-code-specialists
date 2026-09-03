## fix/shared-ast-pass-and-plateau-facts

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

Issue [#1358](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1358) reported a plateau of
five suite files at 189-232s and named two levers: split the files further, or reduce the per-invocation
cost of the 168 child `powershell` runs the four `check-plugin-integrity-*` suites make. It left the second
unpriced in its own words -- *"it is not obvious without measuring which half of that ~4.5s per invocation
is the lint's own work."* This branch measures it, takes the part of it that is free, and corrects what the
measurement contradicts.

#### What the measurement said, and where it went against the report

Three findings, all on an idle 32-core workstation over the fixture those suites build:

1. **The fixed overhead is a fifth, not a half.** Per invocation: spawn 0.097s + the lint's 3419-line parse
   0.115s + its 11 libs 0.071s = **0.283s of 1.362s (21%)** before any check runs. Removing it would mean
   the suites no longer spawning a process per assert, and the lint calls `exit`, so that is a rewrite of
   the fixture's contract for 21%. Not proposed. The report's 4.5s was a CI figure divided by an invocation
   count, which folds four-lane contention on a four-core runner into an apparent per-call cost.
2. **The real duplicate was the AST walk, not the parse.** Two non-skippable checks, barred-skill and
   shopify-cli, each called `ParseFile` and then `FindAll(CommandAst)` over the same file set. Over this
   repo's 184 script files one pass is 1.413s, of which the walk is 1.157s and the parse 0.256s; a second
   pass off a shared cache is 0.014s.
3. **Two of the five files were never plateau members.** The gate records no per-suite duration and buffers
   each suite's output until it completes, so a log timestamp is a *finish* time. Subtracting the shard
   start is a duration only for a suite that started at `t0` -- queue positions 1-4 with 4 lanes. The four
   `check-plugin-integrity-*` files sit at positions 3, 3, 3 and 4, so the report's figures for them are
   exact exactly as it claimed; `entry-scaffold` is 5th of 16 and `new-branch` 9th of 16, so both
   reconstructions include lane wait. `entry-scaffold` is **17.0s** standalone here against the 51-59s of
   the verified suites, which at their 3.6-4.0x local-to-CI ratio predicts ~65s, not 189s.

### CREATE

- [x] `Get-PsScriptCommandAsts` in `../scripts/lint/check-plugin-integrity.ps1`: one memoised parse and
      walk of the script set, shared by barred-skill (check 30) and shopify-cli. Both call sites now take
      their CommandAsts from it. Check 5 (`parse`) deliberately keeps its own pass -- it is the only
      skippable one of the three and it needs the parse errors the accessor discards, which is the property
      barred-skill's own comment already relied on.
- [x] An unparseable file yields an **empty list**, not `$null`. Both callers counted such a file as
      covered and then skipped it, so an empty list preserves their coverage numbers exactly.
- [x] The accessor states its cost where it is paid: it retains 25,476 AST nodes for ~72MB of heap and
      ~100MB of working set over the 184-file set, and names the memory-bounded alternative (one pass over
      the set rather than a cache) for whoever needs it later.
- [x] `../.github/workflows/ci.yml`: the floor comment said **~51s** for the heaviest of the four. That was
      a post-split *workstation* figure from the lint's own docstring, never a CI measurement, and the
      measured floor is ~232s. Corrected with the exact per-suite numbers, the shard makespans from both
      cited runs, and the reconstruction trap spelled out so the next re-measurement does not repeat it.
      This was #1358's stated purpose.
- [x] `../scripts/tests/check-plugin-integrity-fixture.ps1`: the `-SkipCheck` note claimed those three
      checks were *"half of every run's work"*. Re-measured at **2.0%** (1.362s against 1.390s) -- the
      fixture carries 2 skills, no manuals and no personas, so they have almost nothing to walk in it. The
      figure is corrected rather than the skip removed, with a line saying not to reach for it for speed.
- [x] Same file: its `-Full` list said **four** scenarios and named two (`r13bGood`, `r13bGone`) that no
      longer exist. There are **nine**; all nine are now named.
- [x] `../scripts/lint/check-plugin-integrity.ps1` docstring: *"110 times ... all 27 checks"* is now
      **168** (52+45+40+31) and **30**, and the ~51s figure is marked as the workstation number it is.
- [x] `../.claude/specialists/lenses/06-25-extension.md`: the decomposition table, the walk-not-parse
      finding, and the reconstruction trap with the corrected plateau membership -- so the split that is
      left is priced off the right numbers.

### TEST

- [x] The real lint gate: **0 findings**, coverage counts unchanged (barred-skill 327, shopify-cli 184).
- [x] The four suites green with **identical assert counts** -- 108 / 95 / 78 / 59 before and after, which
      is what makes "nothing was removed to buy the time" checkable, the constraint #714 set and #1358
      restated.
- [x] Measured **-12.6%** across the four: 58.7 / 55.7 / 51.0 / 34.5s before, 50.8 / 48.9 / 44.7 / 30.3s
      after. Consistent 12-13% per suite, matching the ~174ms per invocation the profile predicted.
- [x] Two asserts added to `../scripts/tests/check-plugin-integrity-docs.tests.ps1` at the one scenario in
      the four suites that puts a file the parser refuses in front of the gate: barred-skill and
      shopify-cli each still report their coverage there. A shared accessor returning `$null` would take
      both checks down together instead of one, and nothing pinned that before. Suite 95 -> 97 asserts.
- [x] Full local gate via `open-pr.ps1` (lint + every suite), then the same gate as CI.

#### What this branch did NOT do

The split itself. It is still the only lever that reaches #1358's ~195s target, and it is now a smaller job
than filed -- four files rather than five, with the floor already ~30s lower. It redistributes rather than
shrinks and #714's pieces regrew, so it buys time once. The size of that change is Dave's call; #1358 keeps
the corrected pricing.

### DEPLOY: fix/shared-ast-pass-and-plateau-facts

The lint gate parses and walks this repo's script set **once** per run instead of twice. Two checks that
always run -- the barred-skill check and the Shopify-CLI check -- each used to call the PowerShell parser
over every script and then walk the whole tree looking for command calls. They now share one pass. Over 184
script files that walk is 1.157s of a 1.413s pass, so the duplicate was the expensive half, and a second
pass off the shared result costs 0.014s.

Where it shows up is the test gate, because the four suites that exercise this lint run it 168 times and are
almost nothing but those runs: **-12.6%** across them, 199.9s to 174.7s standalone, with every assert count
unchanged at 108 / 95 / 78 / 59. On CI that takes the required check's floor down by roughly 30 seconds.

**Score:** 3

#### What makes this deploy extra special

It is the rarer half of a performance report: the measurement said the proposed lever was worth a fifth
rather than a half, and named a different duplicate nobody had looked for. Three figures written in the tree
turned out to disagree with the tree -- a CI floor comment claiming ~51s where the measured floor is ~232s,
a documented 50% saving that measures 2.0%, and a list of four scenarios that has nine and named two that no
longer exist. And the report's own plateau shrank from five files to four once the reconstruction behind it
was checked: a log timestamp from this gate is a finish time, so subtracting the shard start only gives a
duration for a suite that started at `t0`, which two of the five did not.

**Score:** N/A

#### Pull Request

Share one AST pass and correct the plateau's measured facts
