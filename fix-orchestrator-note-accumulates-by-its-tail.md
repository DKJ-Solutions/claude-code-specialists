### The orchestrator note was removed by its first line only (inbound #271) · Fix · 2026-07-30

Reported from `DaveKJohn/life-hub`'s first real adoption round-trip
([#271](https://github.com/DaveKJohn/davekjohns-workshop/issues/271)), two full `init` → `teardown` cycles
with a filesystem inventory after every phase. **Confirmed, and reproduced exactly.**

The note the bootstrap writes above the orchestrator import is **one sentence wrapped over two lines**: a
fixed head and a generated tail naming where the imports point. Both cleanup paths matched the **head
only** — the teardown, and the bootstrap's own `[tidy]` guard, each by re-typing that literal. So every
teardown left the tail behind, and the next bootstrap wrote a fresh two-line note above the orphan.

Reproduced on a fixture with the fix reverted, and it matches the reported table line for line:

| phase | note head | note tail | `CLAUDE.md` lines |
|---|---|---|---|
| after first init | 1 | 1 | 10 |
| after teardown 1 | **0** | **1** | 12 |
| after bootstrap 2 | **1** | **2** | 12 |
| after teardown 2 | **0** | **2** | 14 |

**The invisibility was the worse half, and the report is right that it is the same failure class as the
1 → 2 → 3 accumulation fixed after `smartwatchbanden` — moved one line down into the only line nothing
checked.** Every counter in the documented verification keyed on the head, so it read 1 / 0 / 1 / 0
throughout: exactly the healthy values. **Including the regression test written for the first version of
this bug.** The lesson already recorded above that fix — *"idempotence has to cover everything the script
WRITES, not just the line it happens to look for"* — was true of the note itself, and had to be learned
twice.

**Why it happened, which is the part that generalises.** One literal, mirrored by hand into two scripts.
That is exactly the shape `Get-SeamPaths` exists to prevent — *"the pair that must never drift apart"* —
so the note now lives beside it: `Get-OrchestratorNote` supplies the head and a tail **pattern**, and
`Test-IsOrchestratorNoteLine` is the single matcher both removers use. The tail has to be a regex rather
than a literal because it interpolates a path that differs per consumer and per layout (the seam names the
seam dir; the pre-seam form names the plugin path), and it stays anchored on the distinctive generated
clauses so the existing rule holds unchanged: **a consumer who reworded or translated the note has
authored it, and neither remover touches it.**

**The test now asserts on the tail, as the report asked — and on one thing it did not.** Alongside a
head counter and a tail counter at every step, the round-trip asserts that `CLAUDE.md` has the same
**length** as after the first bootstrap. A counter watching one line of a two-line block certifies half a
file; a length check catches a leftover **under any name**, including the next one nobody has thought of.
That is the assertion that would have caught this bug without knowing it existed. Verified against the
unfixed scripts: 6 assertions fail, and every head assertion still passes.

**Found on the way, and worth its own line:** the plugin's mirror of `check-report-lib.ps1` was stale
after the source edit, and the suite failed with *"Get-OrchestratorNote is not recognized"* — because the
skills dot-source the mirror, not the root copy. `build-shared-scripts.ps1` fixed it. The shared-script
model catching its own drift, twice today, in two different gates.

**On the report's finding 2 — the `$kept` fix being on `main` but not in a release — it is right, and the
answer is a release rather than a code change.** That is already queued as the `3.0.0` milestone, and the
policy question it raises is the sharper half: *a consumer cannot tell "fixed" from "fixed and
released."* Recorded here so the next release note says which version a fix actually lands in, rather than
the adoption docs claiming `v2.16.0+` for something `2.16.0` does not contain.

**The four secondary findings are accepted and not fixed here** — deliberately, so this branch stays the
one thing it is. Each is real: the audit's word boundary misses a Dutch possessive (`Dereks`), the dry-run
audit's 40-line cap is filled by lens files the same run is about to delete, a `[keep]` on an occupied
`repo-config.ps1` leaves `check-roster-sync` calling functions that file does not have without saying so,
and the per-item `[KEEP]` line still claims *"filled in"* where the summary correctly hedges. They are
listed on the issue and will be picked up from there.
