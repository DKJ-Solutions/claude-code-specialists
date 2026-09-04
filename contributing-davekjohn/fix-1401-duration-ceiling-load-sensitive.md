## fix/1401-duration-ceiling-load-sensitive

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

Issue #1401: replace the absolute <4s ceiling in test-suite-gate.tests.ps1 scenario 4b with a
load-invariant comparison, per the file's own floor-vs-ceiling rule at line 240.

### CREATE

- [x] Read where #1232 landed before choosing a mechanism, which is the issue's own direction 2:
      PR #1236 retried the fixture with a wider bound. That works there because the number is an
      *input* handed to the code under test; here it is an assert on a measurement already taken,
      so the mechanism does not carry over.
- [x] Replace the absolute `-lt 4` ceiling in scenario 4b with `-lt $maxOffset`, and write into the
      block comment why a wider ceiling -- the issue's direction 1 -- was declined rather than taken.
- [x] Correct the scenario 4b header comment, which described the assert as "a CEILING on every row".
- [~] Sweep the rest of the suite for sibling ceilings. Done as a scan, and there was nothing to
      change: line 343 is the only timing ceiling the file has left, so no second edit exists to make.

### TEST

- [x] Standalone: 67 pass, 0 fail. The two timing asserts read `largest offset +8.2s` and
      `largest duration 1.7s` -- a 4.8x margin, where the old ceiling gave 2.4x and tripped at 5.1s.
- [x] Mutation test, which is the whole point of an assert that guards a defect: re-introduced the
      #1358 defect in `native-capture-lib.ps1` (print `$t.StartOffset + $t.Duration` in the duration
      column) and re-ran. The assert FAILED as it must -- `largest duration (10s)` against `+8.3s`.
      The lib was restored afterwards; the diff touches one file.
- [x] Full lint + test gate via `open-pr.ps1`.

### DEPLOY: fix/1401-duration-ceiling-load-sensitive

The test gate's own suite no longer refuses a push because the machine was busy. Scenario 4b in
[`../scripts/tests/test-suite-gate.tests.ps1`](../scripts/tests/test-suite-gate.tests.ps1) proves that
the per-suite table prints a *runtime* and not a *finish time*, and it proved it with a hard-coded
`-lt 4` second ceiling. That is the exact shape the same file forbids forty lines higher up: a timing
FLOOR is guaranteed by `Start-Sleep`, a timing CEILING is guaranteed by nothing, because nothing bounds
how slow a shared machine can be. Under a 65-suite gate run one of the fixture's 1.2s sleeps came in at
5.1s, the assert failed, and `Invoke-WorkflowGates` refused to push a branch that had touched nothing
the suite reads -- the same shape as #1232, one file over.

The ceiling is now a comparison against the queue the fixture itself builds: `$maxDuration -lt
$maxOffset`. Serially the last lane opens only after the five suites before it have run, so the largest
offset is the SUM of five runtimes while a true duration is ONE of them -- and a duration column holding
finish times reads `offset + runtime` for that same row, which exceeds the offset by construction,
whatever the machine was doing. Contention scales both sides together, so the discriminator survives a
loaded box in a way no second-count can. Measured on this branch: 1.7s against +8.2s, a 4.8x margin
where the old ceiling had 2.4x and tripped at 5.1s.

Widening the ceiling to 6-7s was the issue's own first suggestion, and it is declined in the comment
rather than silently: it keeps the fragile shape and discriminates *worse* the more load there is,
because contention inflates the defect's reading too -- and 6-7s lands within noise of the ~7.2s a
finish-time column reports at rest, which is the one figure the assert must stay below. The retry
mechanism #1232 landed on does not carry over either, for the reason in CREATE above.

The assert still fails for the defect it exists to catch, and that is proved by mutation rather than by
argument: re-introducing the #1358 defect in the duration column makes it read 10s against +8.3s and
refuse. Closes [#1401](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1401).

**Score:** 3

#### What makes this deploy extra special

N/A -- the suite is source-repo-only. `native-capture-lib.ps1` is mirrored into the plugins and is
unchanged by this branch; `scripts/tests/test-suite-gate.tests.ps1` is not payload, so no consumer of
this marketplace runs it or notices this.

**Score:** N/A

#### Pull Request

The test gate's duration assert compares against the queue instead of a fixed second-count
