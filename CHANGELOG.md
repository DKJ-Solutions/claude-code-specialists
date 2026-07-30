# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

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

Plugins: specialists

[PR #272](https://github.com/DaveKJohn/davekjohns-workshop/pull/272)

---

### #270 · Open the 3.x overview section, and make the guardrail honest in both directions · Docs · 2026-07-30

Preparation for the 3.0.0 milestone: `releases/README.md` now carries a `### 3.x` section above `### 2.x`,
so the first `3.0.0` row lands under its own major instead of being filed under the previous one. That is
the deliberate act [#269](https://github.com/DaveKJohn/davekjohns-workshop/pull/269)'s guardrail refuses to
perform on anyone's behalf, and the reason it refuses is now stated in the overview's own intro rather than
only in a code comment.

**Opening the section made a flaw in that guardrail reachable, so it is fixed here.** The check compares
the release's major against the section a new row would land in, and refuses a mismatch — correct in both
directions, but the message only described one of them. With `### 3.x` on top, a `-Bump minor`
(2.16.0 → 2.17.0) now mismatches too, and the message would have said *"releases/README.md has no
'### 2.x' section yet"*. That section exists; it simply is not on top. **A guardrail that misdescribes the
repo teaches people to bypass it**, so the message now states only what it knows — which section the row
would land in and which release this is — and branches on direction:

- **new major above the target** (the ordinary case): print the exact heading and table to add.
- **new major below the target**: say that the section does exist but sits under a higher one, and that
  releasing an older major after a newer one has been opened is a decision the script will not make —
  move the row by hand after cutting, or reconsider the version.

**One test changed value, and that is the test doing its job.** The assertion on the live document
answered `2` — the pin that made *"a 3.0.0 cut would misfile"* a stated fact rather than an observation.
Opening the section flipped it to `3`, so the suite failed until the new invariant was written down:
*a 3.0.0 cut now lands under its own major, and a 2.x cut would be refused.* An assertion against the real
document is worth exactly this: it does not let a deliberate change land silently. Its comment now says to
update it, with a reason, whenever a major section is opened.

The empty `3.x` table carries one line of prose saying it is open with nothing cut yet — so a reader
meeting a header with no rows knows it is deliberate rather than broken.

[PR #270](https://github.com/DaveKJohn/davekjohns-workshop/pull/270)

---

### #269 · A major bump would file its row under the previous major · Fix · 2026-07-30

Found by a question rather than a failure: *"is it correct that no `3.x` directory has been created yet?"*
The directory is fine — `cut-release.ps1` creates it itself. The **overview section** is not, and that one
does not create itself.

`releases/README.md` groups releases by major (`### 2.x`, `### 1.x`, newest first, each with its own
table), and the row inserter matches the **first** `| Version | Date | Type | Title |` header it finds.
That is correct for every minor and patch, because the current major's table sits at the top. On a **new
major** there is no table yet, so a `v3.0.0` row would be filed neatly under `### 2.x`. Nothing errors,
nothing looks wrong, and the one document whose entire job is to say which release is which would be
quietly incorrect.

**It has never been hit, and could not have been.** Grouping-by-major arrived in **v2.0.1** — one release
*after* `v2.0.0`, the only major this repo has ever cut. So a major has never met this structure. The code
knew: the comment above the inserter already said *"a brand-new major starts a new top section manually
first (a deliberate milestone moment)"*. A manual step that is documented in a code comment, needed once
per major, and silent when skipped is a step that will be skipped.

**So it now speaks up.** `Get-OverviewTargetMajor` (pure, in `release-lib.ps1`) answers where a row would
actually land, and `cut-release.ps1` refuses a mismatching major **before writing anything** — placed with
the other guardrails on purpose: the row insertion happens *after* the notes file exists, so failing there
would leave a release half-cut. The error prints the exact heading and table to add.

Two details in the pure function that are easy to get wrong:

- **The answer is the last section heading *before the first table*, not the first heading in the file.**
  That is precisely the section the inserter writes into; deriving it any other way would be a second
  definition of the same thing, free to drift from the first.
- **No table at all, or a table with no section heading above it, returns `$null` and the guardrail stays
  silent.** An ungrouped overview is a different shape, not this failure, and a guardrail that fires on it
  would block a release for no reason.

One assertion is deliberately about the live document: **this repo's own overview currently answers `2`** —
which is the test stating, in the suite, that a `3.0.0` cut *would* have misfiled until now.

**And one lesson from writing the test, which cost a failing assert to learn.** The header pattern requires
a newline *after* the separator row. A fixture built by joining lines without a trailing empty element has
no such newline, so the function correctly returned `$null` and the test read it as a bug in the function.
**A fixture that is not shaped like a real file will accuse the code of its own defect** — noted in the
test itself, next to the trailing `''`.

[PR #269](https://github.com/DaveKJohn/davekjohns-workshop/pull/269)

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
[`specialists-teardown`](claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md#verifying-a-round-trip--and-why-git-status-is-not-enough)
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

Plugins: specialists

[PR #268](https://github.com/DaveKJohn/davekjohns-workshop/pull/268)

---

### #267 · A milestone release can carry an authored summary · Feat · 2026-07-30

Groundwork for a **3.0.0 milestone** whose notes are a summary of everything between 2.2.0 and 2.16.0
(Dave's request, July 30, 2026) — 26 releases. The release machinery could not express that, and finding
out *why* is the useful part.

**`cut-release.ps1` generates its notes from the pending `## Pull Requests` entries, and nothing else.**
`Build-ReleaseNotes` is header + `-Title` + the entries grouped by category. `-Title` is exactly one
sentence; the entries are per-PR. So an ordinary release's notes answer *"what changed since the last
one"* — the right question for an ordinary release, and the wrong one for a milestone, whose whole point
is the arc across many. The only route left was to cut normally and hand-edit the generated file
afterwards, which is not a repeatable release and is the reason this script exists at all.

`-SummaryFile <path>` now places an authored markdown block between the title line and the generated
entries, closed off with a horizontal rule.

**Three decisions in it, each of which could reasonably have gone the other way:**

- **A file path, not a string.** A multi-page summary does not survive a command line.
- **The file may live outside the repo, and normally will.** Its canonical home *becomes* the generated
  notes file, so keeping a second copy under `releases/` purely to feed the parameter would be exactly the
  duplication this repo removes elsewhere. A scratch path is the expected case.
- **The rule separating it from the entries is not decoration.** Without a visible boundary an authored
  summary reads as though it were generated, which is the one thing it must not be mistaken for.

**And one deliberate non-symmetry with the entries, asserted by test.** An entry's root-relative links
*are* rewritten (`../../../`), because an entry was authored in the root `CHANGELOG.md` and then moved
three folders deeper. A summary is authored **for** the notes file, so its links are already relative to
where they will sit — rewriting them would break the ones that were right. Same input shape, opposite
correct treatment, and it is only obvious once the reason is written down.

Opt-in throughout: a test asserts that a call without `-Summary` is **byte-identical** to the output
before the parameter existed. A missing or empty `-SummaryFile` is a hard stop rather than a silent
fallback — an empty file would otherwise produce an ordinary release while the operator believes they cut
a milestone, which is the failure this parameter would be blamed for.

**Recorded next to it in [Rendall's lens](.claude/specialists/lenses/05-06-extension.md), because it is a
judgment call and not a flag:** a `major` bump reads as *breaking* to anyone applying semver
mechanically, and a milestone in this repo may break nothing at all — the seam, the largest change in
2.x, is backward compatible by construction, since every reader accepts the old layouts. When nothing
breaks, the summary's opening lines have to say so, or a consumer sits on an old version waiting for a
migration that does not exist.

**The cut itself waits.** The 3.0.0 release is deliberately not part of this branch: it comes after the
first real adoption round-trip in `life-hub`, because a milestone whose central claim is *"adoption is
reversible"* should not be published before that claim has been tested outside a fixture.

[PR #267](https://github.com/DaveKJohn/davekjohns-workshop/pull/267)

---

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

Plugins: specialists

[PR #266](https://github.com/DaveKJohn/davekjohns-workshop/pull/266)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.16.0] - 2026-07-30 — Minor

See [releases/development/2.x/2.16.0.md](releases/development/2.x/2.16.0.md) for the full release notes.

---

### [v2.15.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.15.1.md](releases/development/2.x/2.15.1.md) for the full release notes.

---

### [v2.15.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.15.0.md](releases/development/2.x/2.15.0.md) for the full release notes.

---

### [v2.14.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.14.1.md](releases/development/2.x/2.14.1.md) for the full release notes.

---

### [v2.14.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.14.0.md](releases/development/2.x/2.14.0.md) for the full release notes.

---

### [v2.13.3] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.3.md](releases/development/2.x/2.13.3.md) for the full release notes.

---

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

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
