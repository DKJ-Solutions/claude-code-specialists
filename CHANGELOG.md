# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #206 · Roster check covers persona-only specialists · Fix · 2026-07-28

Inbound #204 from life-hub. `check-roster-sync.ps1` never checked whether a **persona-only**
specialist had a roster row and a lens, so the roster could lose Chris's or Derek's row and the check
would stay green. Measured in life-hub: the shared check validated **20** specialists where that
repo's own `lint-plugin-sync.ps1` compared **24** — the gap being exactly the four persona-only
main-loop specialists.

**The old exclusion bundled two decisions into one, and only the first followed from the reasoning.**
*"A persona is not an orphan"* is right — counting personas as backing is what stops them being
flagged as orphans in every real repo, and `Get-BackingIds` keeps doing exactly that, untouched.
*"A persona can therefore never be missing"* does not follow: a persona is a real specialist with a
roster row and a lens, just like an agent, and when the row or the lens is gone that is actionable
drift of precisely the kind this check exists for. The missing-row/missing-lens loop now walks agents
**and** personas, each finding naming which kind it is about.

**One persona exception remains, deliberately: the lens-header drift check.** That comparison needs
the specialist's current name, which comes from an agent file's `name:` frontmatter. A persona file
carries only `id`/`group`. Run it anyway and every persona lens whose header holds a name — i.e. all
the older ones — would be reported as drifting from its own id: a false signal in exactly the
register the session hook is being taught to trust. Documented as a gap in the script, with a test
pinning the absence of the false signal rather than the presence of a feature.

**Two consequences of extending the coverage, both handled rather than discovered later:**

- **A deliberately unrostered persona is now real drift.** This workshop has one: Bianca (03-02), a
  main-loop *intake* persona `CLAUDE.md` explicitly does not roster, because there is no
  intake-interview work here. That choice was prose only; it is now also recorded in
  `Get-RosterIgnoredIds`, where the check can read it. The ignore-list doing its job — the
  alternative was a permanent `[ERROR]` at every session start for a decision made on purpose.
- **The `sync-roster` skill would have staged nothing for the new findings.** Its `[ERROR]`-parsing
  regex matched the literal word `agent`, while both the check's own report and the session hook point
  the reader at that skill to stage the catch-up. Left alone, the pointer would have looked helpful
  and quietly done nothing for exactly the findings this change introduced. The pattern now accepts
  `persona` too. Both downstream steps already cope: the lens scaffold has been nameless since #145,
  so it needs no persona variant, and a proposed roster row falls back to the id plus an explicit
  *"(add a short description)"* placeholder — degraded on purpose rather than inventing a name a
  persona file does not contain.

**Change 2 — the orphan trail is no longer silent.** An orphan (a roster token or lens file with no
backing agent *or* persona — the "specialist removed from the plugin, consumer lens left behind"
case) is `[INFO]`, and the hook suppresses `[INFO]`, so the finding existed only for whoever
deliberately ran the script: in practice nobody. The per-orphan lines stay `[INFO]` and stay
suppressed — an orphan can be a legitimately just-removed specialist, and a red line through every
transition is how a gate gets ignored. What the check now adds is one non-counting `[ORPHANS]`
roll-up naming the count, which the hook *does* surface, in both the drift and the in-sync branch.

Deliberately **not** the alternative the issue also offered (promote the orphan to `[ERROR]`), and
deliberately not a generic *"N info signals"* line either: a repo permanently carries ignore-list
`[INFO]`s — this one has six — so a generic counter would fire at every single session start, which
is the noise PR #99 removed. No orphans means no line at all, and there is a test for that too.

**What this unblocks.** With persona coverage in place the shared check subsumes the repo-local
duplicate, so a consumer can retire its own `lint-plugin-sync.ps1` — the reason #204 was
investigated. Until this reaches a consumer via a release, that duplicate is load-bearing, not
redundant.

The issue's two closing observations (`Resolve-PluginDir`'s cache-based resolution as the reference
behavior, and the `startup`-only hook matcher) were offered as data rather than asks and are left as
they are.

Plugins: specialists

[PR #206](https://github.com/DaveKJohn/davekjohns-workshop/pull/206)

---

### #205 · SessionStart hooks name the repo a finding is about · Fix · 2026-07-28

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

Plugins: specialists

[PR #205](https://github.com/DaveKJohn/davekjohns-workshop/pull/205)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
