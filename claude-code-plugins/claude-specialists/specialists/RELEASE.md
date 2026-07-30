# Release v3.0.0

**Date:** 2026-07-30  
**Type:** Major

Chapter 2 consolidated (v2.2.0 -> v2.16.0)

You are on this release.

## Fixes

### #273 · Four secondary findings from the life-hub round (inbound #271) · Fix · 2026-07-30

The four lower-severity findings from
[#271](https://github.com/DaveKJohn/davekjohns-workshop/issues/271), fixed together because all four sit
in the same install/uninstall path — and **three of them are defects in work shipped earlier the same day**,
which is the argument for a second pair of eyes outside this repo.

**1. The audit missed a Dutch possessive, which is a false negative in a scan built to over-report.**
`Dereks` takes no apostrophe in Dutch, so the trailing `\b` rejected it and a live reference in a
consumer's own tracked prose went unreported — in a scan whose skill documents itself as biased toward
over-reporting *precisely because a miss is the expensive failure*. The name group now accepts an optional
possessive (`Dereks`, `Derek's`, `Alex'`). **Applies to every non-English consumer, so not an edge case.**

Fixing it exposed a second, smaller lie in the same line: the hit was reported from the capture group, so a
match on `Dereks` printed `name 'Derek'` — sending a reader to search for a string that is not on that
line. It now reports the text **as it appears in the file**.

**2. The dry-run audit showed the wrong 40 lines.** The preview is explicitly the inventory a reader says
yes to, and it was filled entirely by the ~20 lens files the same run had just listed under `[remove]`:
every one mentions a specialist, they consumed the whole cap, and the hits that actually matter only became
visible after `-Apply`. Files on the removal list are now **excluded** rather than sorted last — a
reference inside a file that is going away is not a surviving reference, so listing it would be wrong and
not merely noisy. The exclusion is counted and stated, because a silent narrowing is the thing this audit
exists to prevent.

**3. `[keep]` on an occupied `repo-config.ps1` left a broken contract silently.** Keeping it is correct —
these addresses are inhabited in any repo that predates the plugin, since the scaffolds are the files that
were *extracted from* repos like these. But an existing one has no reason to define the plugin's own
contract functions, so `check-roster-sync` then calls `Get-RosterPath` on a file that does not have it and
the consumer gets `[ERROR]` lines at every session start with nothing connecting them to the bootstrap.
The `[keep]` line now names the missing functions — **only the missing ones**, since listing all four at a
repo that already has them is the noise that teaches people to skim.

**4. The per-item `[KEEP]` line claimed authorship the script cannot establish.** It printed *"filled
in"* while the summary block below it correctly hedges with *"not recognised as an unfilled scaffold"* —
the `smartwatchbanden` correction landed in the summary and not in the line above it, so one run asserted
and hedged about the same file. The line now says what the script actually knows.

**All four are asserted**, including the two that could only be caught by looking at real-world shapes: a
Dutch possessive in a consumer's prose, and an occupied scaffold that lacks the contract. The
possessive test also asserts that a line naming **no** specialist is still not a hit — a looser boundary
must not become a boundary that matches everything.

[PR #273](https://github.com/DaveKJohn/davekjohns-workshop/pull/273)

---

### #272 · The orchestrator note was removed by its first line only (inbound #271) · Fix · 2026-07-30

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

[PR #272](https://github.com/DaveKJohn/davekjohns-workshop/pull/272)

---

### #268 · The bootstrap report printed CLAUDE.md instead of a count · Fix · 2026-07-30

Found by **measuring** rather than reasoning, while checking a blocking report from the first real
adoption attempt (`life-hub`, July 30, 2026). The report itself turned out to be about something else
entirely — see below — but running the measurement it demanded surfaced this:

```
Done: 4 persona-lens(es) created, # life-hub-achtig  Eigen governance.  already present; ...
```

`$kept` is the persona-lens *"already present"* **counter**, declared at the top of `bootstrap.ps1`. The
note-tidy block near the end assigned an **array of `CLAUDE.md` lines** to that same name, so by the time
the summary line ran, PowerShell interpolated the consumer's whole `CLAUDE.md` where a number belonged.
Renamed to `$keptLines`; the counter is left alone.

**Why every suite stayed green, which is the part worth keeping.** That block runs *only* when the
consumer already has a `CLAUDE.md` that does not yet carry the guard import — **exactly the path a real
adoption takes**, and never the path a fixture takes: a fixture with no `CLAUDE.md` gets one written by
the bootstrap and goes down the other branch. So the bug was reachable only where no test looked, and it
corrupted the one number the round-trip protocol tells an operator to write down first.

Third instance of one lesson in this repo — after the `$pid` note in `check-roster-sync` and the
shared-counter collision behind it: **a name reused for a second purpose in the same scope breaks
somewhere else entirely, and a report line is the last place anyone looks.**

**The blocking report itself was a defect in the test, not in the plugin — and the plugin's behaviour
already was what the reporter proposed.** They found both scaffold addresses occupied in `life-hub`:
`scripts/repo-config.ps1` (55 lines) and `scripts/lib/branch-info.ps1` (88 lines, named by that repo's own
`CLAUDE.md` as its single source of truth for the branch taxonomy). Their proposal was to treat scaffolds
like lenses — neither placed nor removed once inhabited. Measured on a fixture built to match:

- **Bootstrap:** `[keep] scripts/repo-config.ps1 already exists -- not overwritten`, both files
  byte-identical afterwards.
- **Teardown `-Apply`:** `[KEEP] ... filled in; it describes this repo's branch taxonomy, which outlives
  the plugin` — both kept, both byte-identical, while the 25 items the plugin *did* write are removed and
  the audit reports `[FREE]`.

So the round trip on an occupied consumer was already correct in both directions. What was wrong were the
**expectations in the test prompt**, which read "both scaffolds present" as a success criterion after the
bootstrap and "both scaffolds gone" after the teardown — true only for a repo that never had them. Stopping
before installing was the right call, and the second half of their note ("a fixture cannot measure this by
definition") is exactly right.

**Both halves are now pinned by tests** — an *occupied consumer* scenario in `teardown.tests.ps1`: the
bootstrap keeps and reports, the teardown keeps and reports, both files byte-identical across the full
round trip, and the report line asserted to carry digits. Verified against the unfixed script: **the two
report assertions fail and the thirteen behavioural ones pass either way**, which is the proof that the
behaviour was always right and only the report was broken.

**And the protocol that misled the prompt is corrected at the source.** The round-trip section of
[`specialists-teardown`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md#verifying-a-round-trip--and-why-git-status-is-not-enough)
now states that the two `Test-Path` lines are an **inventory, not an expectation**, with a table for the
occupied case and the instruction to read `[create]`/`[keep]` and `[remove]`/`[KEEP]` rather than the
booleans. The general form: **the plugin scaffolds precisely the files that were extracted from repos like
these** — free real estate on a fixture, inhabited in any real consumer.

**One correction to the report, for the record.** It concluded that the prompt's ~20 mid-word truncations
were *"in the source file, not in the transfer."* The source file is intact: line 64 reads
`Where-Object { $_ -match '^\s*@' }`, not the reported `Where-Obount`, and no scratchpad file contains a
single broken token. So the damage is in the channel — the same failure
[#260](https://github.com/DaveKJohn/davekjohns-workshop/pull/260) recorded on July 29, now on a different
route. Worth stating plainly because the two diagnoses lead somewhere different: a corrupt source is fixed
by rewriting it, a corrupt channel is not. The prompt's own truncation guard did its job — the session saw
the damage, stopped at step 2, and said so instead of guessing.

[PR #268](https://github.com/DaveKJohn/davekjohns-workshop/pull/268)

## Documentation

### #266 · A seam migration can move a consumer's lenses out of git · Docs · 2026-07-30

Found while running the teardown skill's own pre-flight instruction — *"establish whether `.claude/` is
tracked **before** running with `-Apply`"* — ahead of the first real adoption test round. The instruction
existed because `git status` proved partly blind in `davekokbwj/smartwatchbanden` on July 29. Following it
turned up something that is **not** about the repo being tested.

**Measured across both real consumers, July 30, 2026:**

| repo | `.gitignore` | consequence |
|---|---|---|
| `DaveKJohn/life-hub` | no `.claude` entry at all | the whole tree is tracked — a wrongly removed lens is one `git checkout` away |
| `davekokbwj/smartwatchbanden` | `.claude/*` with `!.claude/plugins/` | tracked **only** on the pre-seam path |

That second row is correct today and **breaks silently on migration.** The exception un-ignores
`.claude/plugins/` — the *pre-seam* location. Move the lenses to `.claude/specialists/` and they match
`.claude/*` with no exception covering them, so the tree leaves version control **without a single line of
the migration looking wrong**: every gate stays green (the readers accept the seam — that is the whole
point of [#253](https://github.com/DaveKJohn/davekjohns-workshop/pull/253)), `git status` shows nothing
because they are ignored, and the teardown's undo is gone. A repo would discover it at the moment it most
needed that undo.

**So the migration is now five steps, and the new one is step 0:** add `!.claude/specialists/` and commit
it *before* moving anything. Reversed, the move lands untracked and the commit that would have captured it
has nothing to capture.

**The general form, which is the part worth keeping:** *an ignore rule written against a path is a bet that
the path will not move.* A migration is exactly when that bet is called in — and no gate in this family can
see a consumer's `.gitignore`, which is why this belongs in the operator's pre-flight rather than in a
check.

**One clearance for the upcoming test round, since that is the question the pre-flight was run for:**
`life-hub` tracks `.claude/` in full, so its round-trip has a working undo and `-Apply` is safe there. It is
`smartwatchbanden` that needs the `.gitignore` step first — and only if and when it migrates, since an
update alone leaves it on the pre-seam path, where it is tracked.

[PR #266](https://github.com/DaveKJohn/davekjohns-workshop/pull/266)

---

Full workshop notes: [releases/development/3.x/3.0.0.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/3.x/3.0.0.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
