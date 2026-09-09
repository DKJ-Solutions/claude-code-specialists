## fix/1723-gate-crash-vs-verdict

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

Two shapes, both diagnosed. Shape 1: the gate judges on exit code alone, so an unhandled AccessViolationException reads as FAILED (exit -1073741819) -- a crash reported as a verdict. Shape 2: the ordering assert in release-notes-page.tests.ps1 case 7 ('the recoverable route is named before the destructive one') searches PowerShell's console rendering of a throw, which hard-wraps mid-word; measured at width 120 the phrase is absent from the message body and the assert survives only on the FullyQualifiedErrorId echo. Cited by name rather than by line: it sat at :305 when this branch was opened, and this branch's own edit moved it.

#### What the report inferred, and what the tree actually says

The report pointed shape 2 at the capture, on the ground that the assert reads captured child
output while 29 other lanes were capturing theirs. **That specific reason does not hold**, and
it is falsified by reading rather than by argument: `Invoke-Build` calls `Invoke-NativeCapture`
with neither `-Utf8` nor `-TimeoutSeconds`, so it takes the `&` arm -- which has no capture file,
hard-codes `ShortRead = $false`, and therefore has no grandchild handle for anything to truncate.

**What IS established**, at width 120: the assert reads PowerShell's error formatter's output,
which hard-wraps mid-word, so `-InitToken for a fresh path` is absent from the message body and
the assert was passing on the `FullyQualifiedErrorId` echo. Sweeping the interpolated path length
over 130 values, 9 fail the old assert -- one contiguous band, which is a wrap boundary sliding
through the phrase. The assert's verdict was a function of a temp path's length.

**And here is what is NOT established, stated plainly because the tempting sentence is one step
further than the evidence goes.** *Which* length the failing run actually hit was never
identified. The suite's own path varies only by `$PID`'s digit count, and digit counts 3 to 7 all
PASS on this machine at this width -- so the failing run differed in something still unnamed
(another machine's `$env:TEMP`, another console width, a `ship-pr` run with no console of its
own). An earlier fan-out here -- 180 runs of the build under 30 lanes, 0 failures -- was quoted as
proof that lanes are not the variable; **it is not**, because it composed a path of a different
length and so never exercised the one quantity the diagnosis turns on. Marlowe's red-team caught
that, and the claim is withdrawn rather than restated.

**Neither gap changes the repair.** The assert was reading a rendering instead of a message, that
is true independently of what tripped it, and an assert whose verdict moves with a temp path's
length is broken whether or not this run is the one that proved it. What the gaps do change is
what may be claimed: shape 2 is a latent defect now removed, not a closed mystery.

### CREATE

- [x] Shape 2 -- adopt the established `Test-Says`/`Assert-Says` helper in
      `release-notes-page.tests.ps1` and convert the 15 asserts fed by a `throw` or a
      `Write-Warning`. Not a new mechanism: seven suites already carry this one under #1512.
- [x] Shape 2 -- the ordering assert reads `Get-SaysIndex` for both phrases, and now requires
      both to be FOUND: `-1 -lt <any index>` is `$true`, so it could pass vacuously.
- [x] Shape 1 -- `Test-GateSuiteCrashed` and `Format-GateExitCode` in
      `native-capture-lib.ps1`; the gate's reap loop reports CRASHED instead of
      `FAILED (exit -1073741819)` and does not enter the suite in `$failedNames`.
- [x] Shape 1 -- a crashed suite is re-run ALONE, once, after the pool has emptied, and the
      green verdict names the crash so the quoted line is not the one place it is invisible.
- [x] Shape 1 -- narrow the discriminator from the sign bit to NTSTATUS's own error window
      (`0xC0000000..0xCFFFFFFF`), on Sebastian's security review: `exit -1` is a line any
      `.tests.ps1` may write and arrives as `0xFFFFFFFF`, so the sign-bit test let a suite hand
      ITSELF the re-run that the promise beside it exists to deny.
- [x] Shape 1 -- exclude `0xC000013A` (`STATUS_CONTROL_C_EXIT`) from the window, on Marlowe's
      red-team: it sits inside it and is not a fault. Every suite child shares one console via
      `-NoNewWindow`, so interrupting a stuck 30-lane run would otherwise have the gate answer a
      deliberate stop by re-running everything it was just told to abandon.
- [x] `native-capture-lib.ps1` is a MIRRORED source (Victor): both plugin copies regenerated via
      `scripts/sync/build-shared-scripts.ps1`, or the fix reaches no consumer and
      `shared-scripts.tests.ps1` stays red. Caught only because it was looked for -- the local
      suites were all green.
- [x] The per-suite duration table no longer reports a crashed suite as a cheap one (Victor): the
      row keeps its honest "died this far in" seconds and says `CRASHED` beside them, and the lone
      re-run prints its own elapsed time, which is where that file's real cost is legible.
- [x] The retention comment ("A GREEN ONE KEEPS NOTHING") corrected (Victor): a crash cleared by
      its re-run deliberately keeps the pool run's capture files on an otherwise green run, which
      is the evidence #1622 lost.
- [~] Shape 1 -- change the seam-probe idiom that faulted. Dropped from this branch: one
      sighting of a 5.1 engine fault, unreproduced, against 68 call sites. Filed as
      [#1729](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1729) with the
      stack and what a repair would have to measure first.
- [~] Shape 2 -- sweep the same helper through the other eight suites. Dropped: 358 exposed
      asserts, and which of them matter is decided per site by reading the emitting call.
      Filed as [#1728](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1728)
      with the per-suite counts.

### TEST

- [x] `release-notes-page.tests.ps1`: 165 asserts green, up from 162. The three new ones are
      deterministic and carry no console -- they hold the measured wrapped literal, assert that
      `IndexOf` really does miss it, that `Test-Says` finds it, and that a genuinely absent
      phrase stays absent.
- [x] `test-suite-gate.tests.ps1`: case 8, 31 asserts. A suite that crashes once and passes
      alone (gate green, crash named on the verdict), one that crashes both times (gate red,
      called a crash), and the guard that matters most -- a suite exiting 1 runs **exactly
      once**, counted through a fixture that appends to a file.
- [x] The discriminator's own asserts: `0xC0000005`, `0xC00000FD` and `0xC0000409` read as crashes;
      `exit 0`, `exit 1`, a `$null` code, `0xFFFFFFFF`, `0xFFFFFFFE` and `0x80000000` do not.
- [x] The forged-crash case as a live fixture: a suite that writes `exit -1` and would pass on a
      second invocation fails the gate, is not called a crash, and is proved by a run counter to
      have been invoked exactly once. Plus a tree-wide assert that no script under `scripts/`
      exits negative at all, which is the measurement the docstring cites.
- [x] Shape 2's mechanism, measured rather than argued: sweeping the interpolated path's length
      over 130 values, 9 of them (a contiguous band, which is a wrap boundary sliding through the
      phrase) make the OLD assert fail. The assert's verdict was a function of a temp path's length.
- [x] `shared-scripts.tests.ps1`: 636 asserts green once the mirrors were rebuilt.
- [x] Ctrl+C pinned: `0xC000013A` is not a crash, while `0xC0000139` and `0xC000013B` on either
      side of it still are -- one status is excluded, not a range.
- [x] Lint gate + all suites via `open-pr.ps1`.

#### What the review round changed, since it is most of this branch

Five reviewers ran in parallel on the diff, and three of them found things that mattered. **The
blocker was invisible to every local suite**: `native-capture-lib.ps1` is mirrored into two plugins,
so a green run here still shipped nothing to a consumer. Sebastian and Marlowe both attacked the
discriminator and both landed -- the sign bit was forgeable by a suite writing `exit -1`, and the
narrower NTSTATUS window that replaced it still swallowed Ctrl+C. Marlowe also caught the branch
overclaiming its own diagnosis, which is why the section above now says what was not established.

### DEPLOY: fix/1723-gate-crash-vs-verdict

The 30-lane test gate stops reporting two things that were never failures as failures.

**A crashed suite is no longer called a failed one.** The gate judged a suite on its exit code
alone, so a child killed by an unhandled `AccessViolationException` inside the PowerShell engine
came back as `FAILED (exit -1073741819)` -- which reads as a suite that ran and said no. It did
not run: it wrote no `[FAIL]` line and no summary, so every minute spent looking for the failing
assert was spent on an assert that does not exist. The discriminator is NTSTATUS's own error
window, `0xC0000000..0xCFFFFFFF`, which is exact without being a list of known codes: every
unhandled structured exception exits with a status in that window -- access violation, stack
overflow, heap corruption, stack buffer overrun -- and nothing inside the family has to be
enumerated. It is deliberately narrower than "any negative exit code", which was the first
version and was forgeable by the very content the gate judges: `exit -1` arrives as `0xFFFFFFFF`
and would have bought that suite the free re-run the promise below exists to deny it. Such a
suite is now reported as CRASHED with the code as hex, and re-run ALONE once after the pool
empties -- which
is what the gate's own docstring already told a reader to do by hand. Green on the re-run leaves
the gate green and still names the crash on the verdict line; a second crash, or a real failure
the crash was hiding, is red. **An ordinary failure is never retried**: an `exit 1` has measured
the tree and said no, and re-running that would mask a verdict instead of obtaining one.

**And a refusal assert stops reading the console's layout instead of the message.** A `throw` and
a `Write-Warning` reach a capture through PowerShell's error formatter, which hard-wraps at the
host's buffer column *inside a word* -- so at width 120 `-InitToken for a fresh path` arrives as
`-InitToken fo` + newline + `r a fresh path` and the phrase is absent from the message body. The
assert had been passing on a `FullyQualifiedErrorId` echo further down the same rendering, a
coincidence of arithmetic between the width and the length of a temp path -- and that is measured
rather than argued: sweeping the interpolated path's length over 130 values, 9 of them fail the old
assert, in one contiguous band, which is what a wrap boundary sliding through a 27-character phrase
looks like. What was NOT identified is which length the one failing run hit, so this is a latent
defect removed rather than a mystery closed. Fifteen asserts in that
suite now go through the `Test-Says` helper seven other suites have carried since #1512, and the
ordering assert requires both phrases to be found rather than accepting `-1` for either.

**Score:** 4

#### What makes this deploy extra special

N/A. This is the test gate and one of its suites -- no consumer of the released plugin sees
either, and nothing about a published release document changes.

**Score:** N/A

#### Pull Request

The test gate tells a crashed suite from a failed one, and a refusal assert stops reading console wrapping

