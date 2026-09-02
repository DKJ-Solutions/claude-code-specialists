## Development: `fix/round-tally-error-wrap-v1` · 20260902-181117

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN

Issue [#1242](https://github.com/DaveKJohn/claude-code-specialists/issues/1242): the local test gate
refuses on this machine, on an assert that cannot reach the branch being pushed.

```
-- no round column at all --
  [PASS] none: exits 1 rather than printing a table of nothing
  [FAIL] none: and points at the parameter that would fix it

Result: 32 pass, 1 fail.
```

#### What was measured before anything was changed

All 58 suites run: **exactly one fails**, and `ci.yml` on `main` is **green** at the same commit. So
the thing under test is not broken -- `round-tally.measure.ps1:192` really does write *"Pass
-ColumnPattern if this round names its columns differently."*

The assert at `round-tally.tests.ps1:209` matched that token against a `Write-Error` record captured
through `Invoke-NativeCapture`, and **PowerShell 5.1's error formatter hard-wraps an `ErrorRecord` at
the output width, splitting mid-token.** Reproduced directly:

```
...nothing to count. Pass -ColumnPat
tern if this round names its columns differently.
```

**The break column is a function of absolute path lengths** -- the rendered line is prefixed with the
measure script's full path and carries the fixture's -- so it moves with the operator's home directory
name. Measured both ways on this machine: the same call passes with a fixture under
`C:\Users\DAVEK_~1\AppData\Local\Temp\rt-<pid>\` and fails with the one the suite actually builds,
`C:\Users\davek_onn\AppData\Local\Temp\round-tally-tests-<pid>\`. A CI runner's `runneradmin` path is
short enough to pass, which is why nothing upstream ever saw it.

`24b5bfa0` (*"every suite's temp fixture is per-process"*) is what exposed it, by appending `-$PID` to
`$TmpDir`. **That commit is correct and is not the defect** -- it only shifted a break point this
assert should never have depended on.

### CREATE

- [x] Flatten the captured record before matching, since the property under test is that the *message*
      names the parameter and never that the formatter left the line alone. The comment carries the
      whole diagnosis, because the naive form is the one anybody would write again.
- [x] Scope it to this one assert rather than to `Invoke-Measure`. Every other match in the suite is on
      `Write-Host` output, which the formatter does not re-wrap, and the table asserts need the line
      structure kept -- flattening for everybody would break the cases this suite exists to pin.
- [~] No shared helper promoted, and the reason is a measurement rather than restraint:
      `park-branch`, `park-cycle`, `worktree-lane` and `find-specialist-mentions` **already** flatten
      captured output inline with this exact `-replace`. It is the house pattern and round-tally was the
      outlier that matched raw, so this is the suite joining a convention, not a fifth caller arguing
      for a mechanism.

### TEST

- [x] `round-tally.tests.ps1` -- **33 pass, 0 fail** (was 32/1). The assert still requires the token, so
      a message that stopped naming the parameter still fails it; only the formatter's line break stops
      counting.
- [x] The full gate, via `open-pr`. The point of the branch is that the suite set goes green, so the
      gate run is the test rather than a formality.

### DEPLOY: `fix/round-tally-error-wrap-v1`

The test gate no longer refuses a push because of the operator's home directory name.
`round-tally.tests.ps1` matched `ColumnPattern` against a `Write-Error` record captured through
`Invoke-NativeCapture`, and PowerShell 5.1's error formatter hard-wraps an `ErrorRecord` at the output
width **splitting mid-token** -- so the assert read `-ColumnPat` / `tern` and failed against text that
visibly contains the word. The break column is a function of absolute path lengths, so it moved with
the checkout's own paths: green on a CI runner, red under a longer home directory. The assert now
flattens the wrap before matching, which is what four other suites in this tree already do at the point
of capture.

Two things make it worth more than a one-line diff. It was **a gate refusing work it had never
measured** -- the failing assert names whichever branch happens to be pushing, exactly the shape #1236
repaired for a timing assert days ago. And it was **invisible to CI**, so the mechanism that normally
finds a red suite could not: the only person who ever sees it is an operator whose paths are long
enough, and the next one would have re-derived the whole diagnosis. `24b5bfa0` exposed it by lengthening
the fixture path and is not itself wrong.

**Score:** 3

#### What makes this deploy extra special

N/A -- the suite is not plugin payload. `round-tally.measure.ps1` and its tests live only in
`scripts/tests/` and are mirrored to no plugin, so nothing here reaches a consuming repo.

**Score:** N/A

#### Pull Request

the round-tally assert reads the message, not where PowerShell broke the line
