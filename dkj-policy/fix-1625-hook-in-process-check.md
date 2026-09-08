## fix/1625-hook-in-process-check

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN

Issue [#1625](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1625): every SessionStart
check hook in this family spawns a **second** `powershell.exe` to run its own check script, on top of the
one the harness has already started to run the hook.

#### What the report got right, and the two places it was off

The pattern is real and was in every hook it named that exists. Two corrections, both measured before
anything was changed:

- **Six hooks, not seven.** `claude-home-sessioncheck.ps1` is not in this tree —
  [#1609](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1609) is still open, so the
  seventh instance it credits has not landed. The six are `connector`, `git-identity`,
  `script-contract`, `unfolded-entry`, `consumer-prose` and `roster`.
  `shopify-floor-sessioncheck.ps1` is a seventh session check and is **not** a subject: it has no check
  script and spawns nothing.
- **"The obvious fix is not a one-liner" is right about dot-sourcing and wrong about the fix.** `exit`
  inside a **dot-sourced** script does terminate the hook, and so does one inside a script **block**
  invoked with `&`. Neither is what this needed: a `.ps1` **file** invoked with `&` gets its own scope,
  its `exit` terminates the script alone, and control returns with `$LASTEXITCODE` set. Verified on a
  fixture before the repair was designed, which is why option 1's "biggest win, biggest change" refactor
  of every check into a lib was not needed to collect the win.

#### The question the report said to settle first — settled

> *"Not measured here: whether the harness runs the hooks in one matcher block sequentially or in
> parallel. That question should be settled before anyone optimises on the number."*

**Parallel.** The Claude Code hooks guide states it: *"Claude Code runs all matching hooks in parallel."*
So the ~875 ms the report reached by summing seven spawns was never additive to the critical path, and
this issue could reasonably have closed as its own option 3.

It does not, because the parallel figure is **not** one spawn either. Measured the way the harness
actually runs them — six concurrent hook processes, with the redundant spawn and without, three rounds:

| | wall-clock |
|---|---|
| six hooks **with** the redundant spawn | 867 / 715 / 777 ms |
| six hooks **without** it | 424 / 404 / 445 ms |
| **saving** | **443 / 311 / 332 ms** |

More than one spawn in isolation, far less than six, because six simultaneous process creations contend
for CPU and disk rather than each costing what one costs. Paid on every `startup`, `resume`, `clear` and
`compact`.

### CREATE

- [x] `scripts/lib/hook-check-lib.ps1` — one function, `Invoke-CheckScript`, returning the same
  `@{ Output; ExitCode }` shape `Invoke-NativeCapture` returns so a caller moves between the two without
  re-reading its own result handling. Registered in `Get-SharedScriptPairs` with **two** mirrors, on
  `check-report-lib` / `native-capture-lib-shopify`'s precedent: `dkj-policy` for five of the hooks and
  `dkj-team-alpha` for `roster`, the one hook in this family that ships outside the workflow plugin.
  The two plugins are separately versioned and separately installed, so reaching across into the other's
  cache would be a dependency a version mismatch breaks silently.
- [x] All six hooks call it, and each dot-sources the lib **inside its existing `try`** — so a payload
  missing the file reports itself as a skipped check instead of failing at load with nothing said. That
  path was walked for real: the connector hook got the call before it got the dot-source, and it said so
  in one line rather than going quiet.
- [x] `plugins/dkj-policy/scripts/README.md` — the mirror row and the destination table, both of which
  the lint gate's check 32 refuses to let go stale.

#### A lib rather than four lines copied six times

Three traps, and every one of them fails **silently** — a wrong answer, not a crash — so a drifted
seventh copy would report a clean check rather than announce itself. Each is written out in the lib's
header with what it measured:

1. **An array splats positionally in-process.** `& powershell -File $s @arr` hands a child a command
   *line*, so `'-Skip','-Path','C:\x'` binds by name; `& $s @arr` hands a script an argument *list*, and
   the same array binds `-Skip` to the first positional parameter. Measured on
   `param([switch]$Skip,[string]$Path)`: `Skip=False Path=-Skip`. Nothing errors. So the function takes
   a hashtable, and each hook's `$checkArgs` became one. Concretely, left alone this would have had
   `script-contract` run the reachability walk it exists to skip, and `connector` run its drift check
   against a manifest path that is really a flag name.
2. **`Write-Host` does not reach the pipeline.** In a child process it lands on the child's stdout, which
   the caller captures. In-process it goes to the information stream, so `$out = @(& $s)` captures
   *nothing* and every line leaks straight to the hook's own stdout — unfiltered into the session
   context, which is the one thing these hooks exist to prevent. `6>&1` is what makes the capture
   equivalent.
3. **One `Write-Host` can carry several lines.** A child's stdout arrives already split; an
   `InformationRecord` stringifies to one element holding the newlines, and the hooks then indent the
   block once and line-match it as a unit. Measured on a fixture: 5 lines through the child, 3
   in-process, 5 again once split.

And one that is loud rather than silent but wanted the same care: `$LASTEXITCODE` is **stale, not
absent**. A `-File` child always leaves a code behind; a script called in-process that returns without
reaching an `exit` leaves whatever the previous native call put there. It is reset before the call.

#### What was deliberately NOT changed

- **The connector hook's other child process stays a child.** Its `plugin-versions` engine call is
  bounded by `Invoke-NativeCapture` with a 30 s timeout, and an in-process call cannot be abandoned from
  the thread making it. Nothing regresses in the six that moved — they were unbounded spawns with no
  timeout either — but a call that already bought a hang boundary does not give it up for 200 ms.
- **`cycle-autopark.ps1`** carries the same pattern and is a `Stop` hook, so it fires far more often than
  any session check. Out of scope here and filed rather than folded in.
- **Every check script.** Option 1's lib refactor is unnecessary once `&` on a file is understood, and it
  would have put a cross-cutting rewrite of every consumer's session start behind this review.

### TEST

- [x] All six hooks run and print reports **identical** to this session's own start, verdict for verdict.
- [x] Per-hook medians of 3, before → after: connector 2161 → 1856, git-identity 1489 → 1114,
  script-contract 1195 → 818, unfolded-entry 1136 → 704, consumer-prose 841 → 523, roster 1965 → 1406.
- [x] Interpreter start-up isolated on this machine, 5 runs of a script whose only line is `exit 0`:
  **219 ms** median spawned against **6 ms** in-process. (The report measured 125 ms on its own machine;
  the direction is the same and the cost here is larger.)
- [x] `check-plugin-integrity.ps1`: 0 errors. All suites green.
- [x] The `exit`-isolation, splatting, colour, multi-line and exit-code behaviours were each verified on
  a fixture **before** the hooks were touched, not inferred.

### DEPLOY: fix/1625-hook-in-process-check

Every SessionStart check hook in this family spawned a second `powershell.exe` to run its own check
script, on top of the interpreter the harness had already started for the hook. All six now run their
check **in that same interpreter**, through one shared `Invoke-CheckScript`
([`hook-check-lib.ps1`](../scripts/lib/hook-check-lib.ps1), mirrored into `dkj-policy` and
`dkj-team-alpha`). Measured across six concurrent hooks — which is how the harness runs them — that is
**311–443 ms** of wall-clock off every session start, resume, clear and compact. Reports are unchanged,
verdict for verdict.

The figure is smaller than [#1625](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1625)
filed, and deliberately so: it assumed the hooks run sequentially and named settling that as the thing to
do first. They run in parallel — *"Claude Code runs all matching hooks in parallel"* — so the ~875 ms
sum was never on the critical path. It is also not one spawn's 219 ms, because six simultaneous process
creations contend rather than each costing what one costs.

**Score:** 3

#### What makes this deploy extra special

The repair the issue talked itself out of turned out to be the one-liner it said was unavailable.
`exit` inside a **dot-sourced** script does take the hook with it, and so does one inside a script
**block** — but a `.ps1` **file** invoked with `&` gets its own scope, and its `exit` returns control
with `$LASTEXITCODE` set. That is why no check script had to be refactored into a lib to collect this.

What the change is careful about is the other direction: in-process invocation has three failure modes
that are all **silent**. An array splats positionally, so a flag binds to the first positional parameter
and its value is dropped; `Write-Host` never reaches the pipeline without `6>&1`, so a hook whose whole
job is to forward `[ERROR]` and hold the rest back would forward everything; and one `Write-Host` can
arrive as a single record holding several lines. All three are handled once, in one lib, rather than six
times — a seventh copy that got any of them wrong would not crash, it would quietly report the wrong
thing into the session context.

**Score:** 2

#### Pull Request

Session-start hooks run their check in-process instead of spawning a second interpreter
