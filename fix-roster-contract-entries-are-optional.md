### The only two required contract entries a consumer cannot decline become optional · Fix · 2026-08-04

**Measured over the whole contract table: 6 of 23 entries were required, and four of those six serve a
script the consumer *invokes*.** `Get-BranchInfo`, `Test-BranchName`, `Get-RepoName`, `Get-LintScript` —
don't want the script, don't call it. `Get-RosterPath` and `Get-RosterIgnoredIds` were the only two whose
sole caller is `check-roster-sync`, which runs from a SessionStart hook: nothing in the repo invokes it
and nothing can decline it. So the only demands a consumer could not opt out of were these.

**They cost nothing to make optional, because the reading script never required them.**
`check-roster-sync` carries its own defaults — roster `CLAUDE.md`, no ignored ids — and runs to
completion without either function. The `[ERROR]` pair came from **this table alone**, declaring a
requirement the script it speaks for does not have. An `[INFO]` naming the default is simply the accurate
report, and it is the shape seven other entries already use.

**Where this came from, and what was deliberately NOT built.** Inbound
[#445](https://github.com/DaveKJohn/claude-code-specialists/issues/445) asked for something larger: a way
for a scripts-only consumer to declare *"I use the shared scripts, not the specialists system"*, honoured
by all three SessionStart checks. That was not built, because verifying the report's reason took the
ground out from under it:

- **The consumer that filed it reversed course 52 minutes later.** Issue filed 12:02 UTC; life-hub's
  commit `ce7f1ad` at 12:54 UTC reads *"sluit het specialisten-team weer aan"* and connects the seam, the
  roster, the lenses **and** a second plugin. Its own follow-up PR is titled *"het specialisten-team is er
  toch, en het dossier zei van niet"*. The `[BOOTSTRAP]` marker the issue cites as noise described exactly
  the state that commit resolved — by bootstrapping, which is what the marker advises.
- **The stale-register claim resolved itself with it.** `connectors/life-hub.json` was said to be untrue
  since 2026-07-30. Re-run afterwards, that connector is green on all 24 extensions across both plugins,
  both on the source version. Nothing to correct.
- **And two of the six reported lines were never errors.** `[BOOTSTRAP]` is a non-counting marker,
  deliberately so since #225. Of the six, two were errors (repaired here), one was that marker, and three
  were register signals that are now gone.

So an opt-out would have been built for an adoption shape no consumer currently has, against evidence
that had already evaporated. **The asymmetry repaired here is the part that stands on its own** — it is a
property of the table, true regardless of who wants which adoption shape.

**Tests: 250 asserts, up from 243.** The three that pinned the old behaviour were rewritten rather than
deleted, and three guards were added around them: the sibling function gets the same treatment, **both at
once** (the pair a scripts-only consumer would strip), and — the one that keeps this from being a blanket
downgrade — `Get-RepoName` stripped from the same lib still exits 1 with an `[ERROR]`. The absent-lib
scenario now asserts in **both** directions per optional function, present as `[INFO]` and absent from the
errors, because "no error" alone would also pass if the check had quietly stopped examining them.
