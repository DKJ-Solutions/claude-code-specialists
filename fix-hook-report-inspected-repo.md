### SessionStart hooks name the repo a finding is about · Fix · 2026-07-28

Inbound #203 from life-hub. The three SessionStart hooks reported **that** there was drift but not
**where**: they filter their child check's output down to the `[ERROR]` lines, and that filter threw
away the one line naming the inspected repo. On 2026-07-27 that sent an investigation into the wrong
repo — a script-contract alarm about `Get-RosterPath`/`Get-RosterIgnoredIds` that did not reproduce,
against functions that had landed two days *earlier*. The check was right; it was right about a
**different repo** than the session it reported into, and the report had no way to say so.

**The fix is diagnosability, not detection — the checks themselves were sound.** Two mechanisms in
the shared `check-report-lib.ps1`, one per shape of check:

- **`Resolve-CheckRoot` + a `[SCOPE]` line** for a check whose whole run inspects one repo root
  (`check-script-contract`, `check-roster-sync`). Both now delegate their dual-context root
  resolution to that single source and print the resolved root *and how it was resolved*. The
  hooks keep `[SCOPE]` through the `[ERROR]` filter, so a surfaced finding always arrives with its
  repo. Deliberately the root the **check** resolved, not the one the hook assumes it is in: the two
  diverging *is* the failure mode, so printing the hook's own assumption would read just as
  reassuringly and be just as wrong.
- **`Set-CheckScope`** for a check that walks several scopes in one run (`check-connectors`, one
  block per connector). A per-run line cannot disambiguate there, so each finding carries its own
  subject. The label is set per iteration and cleared afterwards, so a run-level notice is never
  attributed to whichever connector the loop happened to end on.

Naming the connector turned out not to be enough, and this repo's own register proved it: the live
session summary showed two **word-for-word identical** `[ERROR]` lines for smartwatchbanden, because
that consumer registers two plugins and both were behind on one outdated install — the
distinguishing `-- plugin:` header being exactly what the filter drops. The label therefore narrows
to `<repo> / <plugin-id>` inside a plugin block. Same defect, one layer deeper.

Two further blind spots in the hooks, from the same issue:

- **A partial drift report used to be indistinguishable from a complete one.** The exit code cannot
  carry that distinction — a complete report *with* findings and a crash halfway both leave a `-File`
  child on a non-zero exit. `Write-CheckSummary`'s `Summary: N error(s)` line is the check's last
  statement, so its absence is the reliable marker; a drift report missing it (or on an unexpected
  exit code) is now flagged as possibly partial. Used only to *qualify* a drift report, never to
  withhold the in-sync line: a check may legitimately exit 0 early without a summary, and turning
  that into "could not complete" would trade one misreport for another.
- **`connector-sessioncheck` printed "signals found -- summary" with an empty list** whenever the
  check exited non-zero without emitting a signal line — a finding that is not there. That case now
  has its own could-not-complete branch, matching the other two hooks.

`Resolve-CheckRoot` also reports a missing `CLAUDE_PROJECT_DIR` explicitly instead of falling back to
the working directory's git root in silence, and returns `$null` rather than letting a caller under
`$ErrorActionPreference = 'Stop'` die on a `.Trim()` of nothing.

**The dual-context invariant moved with the behavior.** `shared-scripts.tests.ps1` asserted that
every shared source matches `CLAUDE_PROJECT_DIR` — which the two sync checks would still have passed
purely on their *comments* after the resolution moved into the lib. It now requires a real call
(inline `$env:CLAUDE_PROJECT_DIR` **or** `Resolve-CheckRoot`), plus an assertion that
`check-report-lib` itself really reads the env var. Otherwise the guard would have quietly stopped
guarding anything.
