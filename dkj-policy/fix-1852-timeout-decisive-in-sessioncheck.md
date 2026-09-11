## fix/1852-timeout-decisive-in-sessioncheck

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

#### What #1852 reported, and why both of its candidate causes are wrong

The report is exact about the symptom and wrong about the mechanism -- the second of the six ways an
item fails on pickup. It offered two candidates, the fake engine's sleep not lasting five seconds or
`-VersionTimeoutSeconds` not being passed through on that path, and read the failure as "evidence
against the fix #1701 made". Measured here on the same commit: neither holds, and #1701 is untouched.
The bound is passed, it is read, and it fired.

What the report could not see from CI is that **the bound firing does not make the capture empty**.
`Invoke-NativeCapture` kills the child's tree and then reads out.txt anyway, so a child that outlives
the kill -- `taskkill.exe` paying its own cold startup under the gate's sixteen lanes is enough, no
kill failure required -- finishes inside the post-kill five-second grace window, and its full output
comes back with `TimedOut = $true`. `connector-sessioncheck.ps1` then picked its verdict from that
output's CONTENT and never read `TimedOut`, so it printed the killed run's `[SUMMARY]` as a clean
version check.

- [x] Read the issue against the tree rather than routing it: the symptom stands, the reason does not.
- [x] Prove the bound works -- `Invoke-NativeCapture -TimeoutSeconds 1` against a 5s child, three runs,
      exit 124 and `TimedOut` every time. Candidate 2 is dead.
- [x] Reproduce the CI state deterministically through the real hook, with an engine that prints before
      it sleeps: byte-identical to the line #1852 quotes. Candidate 1 is dead, and the cause is found.

#### The blast radius, measured rather than assumed

Every other bounded caller in this tree already reads `TimedOut` -- `ship-pr.ps1` carries a comment
calling its own read LOAD-BEARING for precisely this reason, and `check-connectors.ps1` reads
`ShortRead` beside it. This hook was the one bounded caller reading neither.

- [x] Enumerate the bounded call sites and which of the two fields each one reads.

### CREATE

- [x] `connector-sessioncheck.ps1`: drop the engine's half-answer when `TimedOut` or `ShortRead` is set,
      keeping the exit code so the degraded line still names 124. Placed at the capture rather than at
      the branch, so the session cache below it stores what the live run reported.
- [x] `native-capture-lib.ps1` (three registered mirrors, held byte-identical): correct the
      `Stop-NativeProcessTree` docstring. Its claim that a failed kill "costs a stray process rather
      than a wrong answer" is the sentence that told callers there was nothing here to read, and it is
      false for any caller that parses `Output`.

### TEST

- [x] `connector-sessioncheck.tests.ps1` block 7, new: a timed-out run whose capture already holds a
      `[SUMMARY]` degrades anyway. Deterministic -- it turns on the engine's statement order, not on a
      timing race, so it reproduces on any machine at any load.
- [x] Prove block 7 can go red: with the repair disabled it fails with exactly the two assertions CI
      reported in #1852, and no others.
- [x] Block 6's comment corrected. Its "forced rather than raced" claim was true of the bound and false
      of the verdict, which is how it could fail where it says it cannot.
- [x] `native-capture.tests.ps1`: pin the lib contract the hook now rests on -- a bounded call that times
      out still returns whatever the child flushed, so `Output` is not evidence that the call completed.
- [x] Both suites green standalone (51/51 and 118/118), then the full gate before the PR.

### DEPLOY: fix/1852-timeout-decisive-in-sessioncheck

The session-start version check no longer reports a run that was killed mid-flight as a clean result.

`connector-sessioncheck.ps1` bounds the plugin-versions engine and then chose its verdict from whatever
landed in the capture. But a bound that fires does not empty the capture: `Invoke-NativeCapture` kills
the child's process tree and reads its output files regardless, so a child that outlives the kill by a
moment -- which needs nothing worse than `taskkill.exe` paying its own cold startup under load -- comes
back complete, flagged `TimedOut` in a field this hook never read. The result was an all-clear printed
for a check that did not finish: the `[UNREGISTERED]` hazard the hook's own wording exists to prevent,
arriving through the one field it was not reading. A capture truncated by the kill can also end after a
`[SUMMARY]` and before an `[ERROR]`, which reads as "up to date" about a checkout that is behind.

The hook now reads `TimedOut` and `ShortRead` -- as every other bounded caller in this repo already
does -- and degrades to its honest one-line verdict instead of parsing a document the engine never
finished writing. `Stop-NativeProcessTree`'s docstring, which had told callers a failed kill costs
nothing but a stray process, now says what it actually costs and where the answer is.

It surfaced as an intermittent red suite (#1852, CI run 34596638888) whose own comment said it could
not fail under load. That comment was arguing from the bound, which is load-proof, rather than from the
verdict, which was not. The new block 7 pins it deterministically, and fails with exactly the two
assertions CI saw when the repair is removed.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo's audience is its own maintainers. The two changed sources ship inside plugins, to a
consumer who runs this workflow, rather than to a subscriber of a service.

**Score:** N/A

#### Pull Request

A timed-out version check no longer reports its killed run as a clean verdict

