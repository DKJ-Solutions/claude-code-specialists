### The bootstrap's scaffolds satisfy the plugin's own contract · Fix · 2026-07-29

Resolves [#226](https://github.com/DaveKJohn/davekjohns-workshop/issues/226). A freshly bootstrapped
repo got **3 `[ERROR]` lines about files the bootstrap had just written** — `Test-BranchName`,
`Get-RosterPath` and `Get-RosterIgnoredIds` missing from the `VUL-IN` scaffolds `specialists-init` places.

The issue asked which side was wrong, and the answer was in the scaffold's own docstring: it advertised
`Get-RepoName / Get-RepoBlobUrl / Get-LintScript`, the contract as it stood when the scaffold was
written. The contract then grew — `Test-BranchName` with `new-branch`, `Get-RosterPath` and
`Get-RosterIgnoredIds` with the roster-sync feature in v1.12.0 — and the scaffold never followed. So the
scaffold side was stale, and the check's wording made it read the other way round: *"this lib predates
the contract"* is the wrong story for a lib written seconds earlier by the current version of the plugin.

All three functions are now in the scaffolds, with the real semantics rather than stubs:
`Get-RosterPath` defaults to `CLAUDE.md`, `Get-RosterIgnoredIds` to an empty array (with a note that
adopting a specialist is the default, and that without this function "skip this one" is not an
implementable outcome at all — which is why the contract marks it required), and `Test-BranchName`
carries the actual reject rules, including that an unknown prefix is deliberately *not* a hard reject.

**The durable part is not the three functions — it is the invariant.** Every existing scaffold assertion
was a spot-check against a hand-maintained list, and that is precisely how this drifted. The new case
spot-checks nothing: it runs the **real contract check against the real bootstrap output**, so adding a
required contract entry without extending the scaffold now fails the suite, whatever the entry is called.
It also asserts the check genuinely probed the libs rather than passing because #225's `[BOOTSTRAP]`
short-circuit swallowed the run — a test that can pass for the wrong reason is not a test.

Measured with the harness from #224: a correctly bootstrapped consumer now shows **19 `[ERROR]` lines,
down from 22.** What remains is the roster rows the owner genuinely has to add, all 19 of them, which is
real work rather than a defect — though 19 near-identical lines is still more noise than one roll-up
would be, and that is worth a separate look now that this is out of the way.
