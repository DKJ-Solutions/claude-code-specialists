## fix/1464-gate-orphan-warning

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

### CREATE

- [x] Add `Get-ResidentPowerShellCount` and a warning in `Invoke-TestSuiteGate` (native-capture-lib.ps1), synced to both plugin mirrors (dkj-policy, team-shopify)
- [x] Test the warning threshold via the driver-shadow seam in test-suite-gate.tests.ps1

### TEST

- [x] `scripts/tests/test-suite-gate.tests.ps1` -- 73/73, including the three new resident-count cases
- [x] `scripts/tests/native-capture.tests.ps1` -- 60/60
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors
- [x] Full suite gate, run serially (`-MaxParallel 1`, deliberately, given this fix's own subject) -- 70/70 in 1,705s

### DEPLOY: fix/1464-gate-orphan-warning

Fixes #1464. `Invoke-TestSuiteGate` starts each suite with `Start-Process` but never tracked those
children beyond its own in-memory queue, so a harness-killed gate run left its `powershell.exe`
children running -- invisible and unreachable to the session that killed it. An immediate retry could
then be OOM-killed too, even with `-MaxParallel` set correctly, because the retry's own memory budget
assumed room the dead run's orphans were still holding: measured on one machine as 5 processes at
rest, 28 orphaned after a kill, and a second `-MaxParallel 4` attempt dying from 1.7 GB free before a
third, serial attempt finally passed.

This ships the cheapest repair the issue asked for, not the two heavier ones it named (PID
tracking/reaping, or a Windows job object) -- both are real changes to the spawn model and neither is
part of this fix. `Get-ResidentPowerShellCount` counts resident `powershell.exe` processes before the
gate starts its own pool, and `Invoke-TestSuiteGate` prints one `Write-Warning` line when that count
is above 20 (comfortably over this file's own documented 16-18-lane ceiling for a legitimately busy
run, and comfortably under the 28+ orphans measured in #1464). It is advisory only -- it never fails
the gate -- so a silent kill now has a chance to read as "something is still draining" instead of "the
machine got slower".

**Score:** 2

#### What makes this deploy extra special

N/A -- this is a diagnostic line inside the shared test-suite gate; no subscriber of any consuming
repo's service ever sees it.

**Score:** N/A

#### Pull Request

The gate warns when resident powershell processes look like leftover orphans

