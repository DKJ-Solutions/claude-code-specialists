## Development: `fix/native-capture-grandchild-launch-race-v1` · 20260902-151607

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

Issue #1232: the 3s bound in native-capture.tests.ps1 must cover two cold PowerShell 5.1 startups before the grandchild writes its started marker. Under load it does not, and the test gate refuses the push for a race the branch had no part in.

#### What the report got right, and the two directions that do not survive reading

The symptom, the mechanism and the measurement all stand. `native-capture.tests.ps1:290` gave a
3-second bound that had to cover the outer `powershell -File` cold start, its `Start-Process`, AND
the grandchild's own cold start, before the grandchild's first statement writes `started`.

The report ranks three directions and asks explicitly that they be picked "after reading rather than
from this list". Read against the tree, two of them do not hold:

**Direction 1 -- poll for the marker after the run returns -- CANNOT work.** `Stop-NativeProcessTree`
(`scripts/lib/native-capture-lib.ps1:181`) kills with `taskkill /PID <outer> /T /F`, and the
grandchild is inside that tree by construction. At the bound it is dead. Whether `started` exists is
therefore decided AT kill time and cannot change afterwards, so no amount of waiting recovers it. The
report's own caveat -- that it had not measured which startup ran over -- is what this is.

**Direction 2 as written -- the outer writes `started`, the grandchild writes only `survived` --
destroys what the assert is for.** The fixture's comment says it plainly: asserting the absence of
`survived` alone "passes just as happily when the grandchild never launched at all, which would be a
test that cannot fail." A marker written by the outer proves the outer ran, which the `TimedOut`
assert already proves. The vacuity guard would be gone.

#### And the measurement overturned this branch's OWN first direction

The plan opened by proposing to make the grandchild a near-zero-startup process, so the bound would
have to cover one cold start instead of two. Measured on 18 cores, from launch to the grandchild's
own marker, that is not enough:

| background load | launch -> `started` (median) | of which the grandchild's own startup |
|---|---|---|
| idle | 0.52s | 0.22s |
| 2 workers | 0.46s | 0.17s |
| 9 workers (half the cores) | 0.58s | 0.26s |
| 18 workers (every core busy) | **2.67s** (max 2.89s) | 1.22s |
| 36 workers (twice the cores) | **9.68s** (max 10.39s) | 4.62s |

The bound is 3s, so full core saturation alone lands inside the noise band of the threshold, and
twice that overruns it by more than 3x. The grandchild is only ~46% of the chain: removing it leaves
about 1.4s at saturation (fine) but about 5.0s at twice that (still over). **The OUTER startup alone
was 4.3-5.1s at twice the cores** -- so no amount of cheapening the grandchild settles this, and the
report's ranking of "raise the bound" as weakest is right for the same reason: any fixed bound is a
threshold some machine crosses.

Two shapes with a cheap grandchild were also measured and both failed to launch at all -- `cmd /c`
strips the first and last quote of a fully quoted command line. That is this suite's own subject
biting back, and an argument against moving the fixture to `cmd` at all.

#### So: repeat the attempt with a wider bound

The subject -- *did the grandchild launch* -- does not expire, which is the true half of the report's
direction 1; only its mechanism was wrong. A failed attempt is re-run at a wider bound instead of
being reported as a failure of the code under test. An unloaded machine passes the first attempt and
pays exactly what it paid before; a loaded one re-runs. A run where even the wide bound cannot get
the grandchild up still FAILS, so the gate keeps a verdict that means something.

### CREATE

- [x] measured the two startups in isolation, idle and at four load levels -- the table above, which
      is what overturned the branch's own opening direction
- [~] make the grandchild a near-zero-startup process -- dropped on that measurement: the outer
      startup alone overruns 3s, and both `cmd`-based shapes failed on `cmd /c` quoting
- [x] repeat the attempt at bounds 3 then 12, with per-attempt marker paths so a kill that was
      ALLOWED to fail cannot let one attempt's grandchild vouch for the next one's launch
- [x] the two derived numbers follow the bound -- the grandchild sleeps `bound + 3`, the wait after
      the run is `bound + 6`; at the first bound those are the 6 and 9 this fixture always used
- [x] the fixture comment states which half of the bound is load-bearing, carries the measurement,
      and says why polling after the run cannot work, so the next reader does not re-introduce it

### TEST

- [x] `native-capture.tests.ps1` green standalone: 58 pass, 0 fail
- [x] and green under the condition the report describes -- 36 CPU burners on 18 cores, run twice:
      `the grandchild did not launch inside 3s -- loaded machine, retrying wider`, then 58 pass, 0 fail
- [x] the OLD suite under that same load, in the same window, reproduces the report exactly:
      `[FAIL] the grandchild really launched`, 57 pass 1 fail, exit 1 -- twice
- [x] no idle cost: OLD 21.7s / 21.7s against NEW 20.1s / 21.6s
- [x] `check-plugin-integrity.ps1` and every suite, as CI runs them

### DEPLOY: `fix/native-capture-grandchild-launch-race-v1`

The test gate no longer refuses a push because the machine was busy. `native-capture.tests.ps1`'s
grandchild fixture had a 3-second bound that has to cover two cold PowerShell 5.1 startups before the
grandchild can write the marker proving it launched, and that bound is crossed by load alone --
measured here at 2.67s with every core busy and 9.68s at twice that, against 3s. The assert that
failed is about process startup timing, so the refusal named a branch that had nothing to do with it
and cost a full gate run. The attempt is now repeated at a wider bound rather than reported as a
failure, with the grandchild's sleep and the post-run wait derived from whichever bound is in play;
an unloaded machine still pays what it always paid, and a run where even the wide bound cannot get
the grandchild up still fails, because a gate whose verdict a re-run clears is a gate that has
stopped working.

**Score:** 3

#### What makes this deploy extra special

N/A -- the suite is not plugin payload. `native-capture-lib.ps1` is mirrored to consumers, its test
suite is not, so nothing here reaches a consuming repo.

**Score:** N/A

#### Pull Request

the grandchild-launch assert no longer races two cold PowerShell startups
