## Development: `fix/lint-gate-wall-clock` · 20260903-161137

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

Issue #1319: `Invoke-WorkflowGates` (`scripts/lib/gate-lib.ps1`) runs the lint gate and prints only a
pass/fail line -- no elapsed figure -- while its test half prints `test gate: all N suites passed in
Xs`. So a session writing down "the full gate cost ~Ys" has a number for the test half and none for
the lint half; #1314 measured the consequence (three conflicting "full gate" figures for one test
set).

Decisions taken on the issue's three open points:

- **Print the seconds.** It is the direct parallel to the test gate and makes the "was lint included"
  half of #1314's DEPLOY rule answerable from the output instead of by inference. Not mutually
  exclusive with "the rule already says cite lint separately" -- the rule stays; this makes it
  cheaper to satisfy.
- **On the `gate-lib.ps1` line, not inside `check-plugin-integrity.ps1`.** Matches where the test
  gate times itself (the gate helper `Invoke-TestSuiteGate`, not the suites), and leaves
  `check-plugin-integrity.ps1` -- which CI and standalone runs also invoke -- untouched.
- **Real runs only.** The evidence-cache fast path keeps its `already proved ... -- skipped.` line
  with no seconds, the way `Invoke-TestSuiteGate`'s own cache branch does.
- Format is invariant-culture (`[string]::Format([CultureInfo]::InvariantCulture, '{0:N0}', ...)`),
  the concern `Format-GateSeconds` documents under #1159; inlined rather than borrowed because
  `gate-lib` does not dot-source `native-capture-lib`.

### CREATE

- [x] `scripts/lib/gate-lib.ps1`: wrap the real lint run in a `Stopwatch`, print
  `lint gate: integrity check passed in Xs.` (green) / `... FAILED in Xs.` (red) on the two verdicts.
- [x] Rebuild the plugin mirror (`scripts/sync/build-shared-scripts.ps1`) -- mirror back in sync.
- [x] `scripts/tests/gate-lib.tests.ps1`: new sub-case 15d-clock -- a real run prints its seconds on
  both verdicts, the cache-hit run prints the skip line and no elapsed figure.

### TEST

- [x] `scripts/tests/gate-lib.tests.ps1` -- 115 pass, 0 fail (case 15e still confirms `Write-Host`
  lines do not pollute the function's return value).
- [x] Standing gate as coverage: `open-pr` runs `check-plugin-integrity.ps1` and every suite before
  the push. Hand-run of the lint gate on this branch went green -- `0 error(s)` -- which is also the
  run this change times; it printed `lint gate: integrity check passed in Xs.` as intended.

### DEPLOY: `fix/lint-gate-wall-clock`

`Invoke-WorkflowGates` (`scripts/lib/gate-lib.ps1`) now times the real lint run and prints
`lint gate: integrity check passed in Xs.` / `... FAILED in Xs.`, the direct parallel to the test
half's `test gate: all N suites passed in Xs`. Timed around the child run only -- the evidence-cache
fast path keeps its `already proved ... -- skipped.` line with no seconds. So a session recording
"the full gate cost ~Ys" now has a lint figure to name beside the test figure, which is the half
#1314 found missing when three conflicting "full gate" numbers were quoted for one test set. The
figure is formatted invariant-culture (the `Format-GateSeconds` / #1159 concern), inlined because
`gate-lib` does not dot-source `native-capture-lib`.

Closes [#1319](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1319).

**Score:** 2

#### What makes this deploy extra special

A consumer running the `contributing-davekjohn` workflow plugin picks up the mirrored `gate-lib.ps1`
on the next plugin update: their `open-pr` / `-GatesOnly` run gains the same lint-gate seconds line,
symmetric with the test-gate timing they already see. Console output only -- no behaviour, gate
verdict or exit code changes.

**Score:** 2

#### Pull Request

Lint gate prints its own wall-clock

