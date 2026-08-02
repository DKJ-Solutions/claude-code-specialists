# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #400 · a reported finding's reason is verified before it is repaired · Docs · 2026-08-02

The working rule that round v13 produced, recorded rather than left in a closing message. A report
carries two things — *what* went wrong and *why* — and the second is an inference by someone
measuring from the outside. The rule is to check the code, doc or output that would have to be true
for that explanation to hold, before writing the repair.

The measured instance is inbound
[#388](https://github.com/DaveKJohn/davekjohns-workshop/issues/388). It reported that the teardown
does not count a fixture's `README.md` *"even as prose"*, and proposed deleting the sentence that
promised the count. The symptom was real: nothing about that file shows up in the output. The reason
was not. `teardown.ps1`'s prose pass scans the **root markdown** — every `*.md` at the repo root,
excluding only `CLAUDE.md` and `CHANGELOG.md` — so the file is squarely in it. It scores **0**
because the fixture README deliberately names no specialist, and the note prints only above zero. The
sentence was not untrue; it was unfindable.

Had the proposal been built as written, the change would have deleted a correct sentence, left the
next measurer with exactly the same confusion minus its explanation, and carried an issue number
vouching for it. That is what makes this worse than the untouched defect: **a wrong repair is a
defect with a citation.** The repair that did ship explains where to look instead
(`DaveKJohn/specialists-adoptietest#2`).

It sits under *General working practices* rather than in a specialist's manual, because it belongs to
whoever is holding the report — which over one evening was the systems administrator, the technical
writer and the test engineer in turn — and because that section loads unconditionally. Nobody has to
go looking for it, which is the property this lesson needs: it applies at the moment you are most
convinced you already know what to build.

[PR #400](https://github.com/DaveKJohn/davekjohns-workshop/pull/400)

---

### #399 · the release card states what it describes, not where you are · Fix · 2026-08-02

Every plugin's `RELEASE.md` card carried the line *"You are on this release."* — written at cut time,
about a reader the card has never met. Round v13 measured it false in the ordinary case (inbound
[#384](https://github.com/DaveKJohn/davekjohns-workshop/issues/384)): the payload came from `main`,
three commits past the tag whose number both the card and `plugin.json` were carrying.

What makes it more than cosmetic is *where* the reader meets it. The QUICKSTART already documents
that **the documented update path cannot deliver a tagged release**, because the source it reads is a
branch — and v13 was the first round in which a consumer ran that tag comparison and reached the right
conclusion: *I am on `main`, not on the release*. Two minutes later the card of that same release told
them the opposite. Two documents of one family contradicting each other about one measurement, with
the wrong one being the one that cannot know.

`Build-PluginReleaseCard` now writes what the card *can* know — the version its manifest carries — and
hands the "where am I" question to the check that can answer it, linked as an absolute URL because the
card is read from a plugin cache where the QUICKSTART does not ship. The fix is in the generator, so
it holds for every future release instead of being retyped; the four cards on disk were regenerated to
match, and `cut-release.ps1`'s own description, [Rendall #06's lens](.claude/specialists/lenses/05-06-extension.md)
and the QUICKSTART line pointing at the card all follow the behaviour.

The test that pinned the old sentence now pins the new one **plus its negative**: the card must not
claim the reader is on this release. A line this one is only a repair for as long as nothing puts it
back.

Plugins: specialists, specialists-ecomm, specialists-lifehub, specialists-shopify

[PR #399](https://github.com/DaveKJohn/davekjohns-workshop/pull/399)

---

### #398 · two promises the consumer path cannot keep are made conditional · Docs · 2026-08-02

Both v13 findings are the same shape: a sentence that is true of the writer's situation and not of
the reader's.

**The `#336` hash pair is reproducible, and the warning said it was not** (inbound
[#385](https://github.com/DaveKJohn/davekjohns-workshop/issues/385)). `QUICKSTART.md` printed a
before/after SHA256 pair for `install --scope project` and then told the reader the values *"are not
something to match"*. Round v13 hit both of them exactly on a second profile — 224 bytes before, 246
after, and the +22 accounted for to the byte by the two documented changes.

That is not a coincidence, it is the prescribed path: Step 1 has the reader paste the printed block
into a file that does not exist yet, so the "before" bytes *are* the block, and the CLI's serialiser
is deterministic from there. Matching the pair therefore tells a reader two useful things — the block
went in intact, and the install did what it should. The warning was taking that away. It is now
conditional: match them if you followed this path, and if you had a `settings.json` already or
formatted it yourself, only the *difference* between your two values means anything.

**The `[UNREGISTERED]` safety net does not reach the reader it was written for** (inbound
[#383](https://github.com/DaveKJohn/davekjohns-workshop/issues/383)). `specialists-init`'s closing
step promised that until the repo is registered in the workshop, its own session start says so. The
line exists — but it comes from `check-connectors.ps1`, which `connector-sessioncheck` only runs when
it finds a **verified workshop checkout on this machine**, and a plain consumer has none. The
unregistered v13 repo got `no verified workshop checkout found on this machine -- check skipped.` in
every session of the round, and nothing else.

Defensible behaviour — there is nothing to check against — but it means the net catches the reader
who needs it least. The step now says so, with the line a consumer will actually see, and names why
this is the step most easily left lying: it asks for a PR in another repo, afterwards, once the
adoption already works.

Plugins: specialists

[PR #398](https://github.com/DaveKJohn/davekjohns-workshop/pull/398)

---

### #397 · the honest leftovers list gains a row and loses a stale citation · Docs · 2026-08-02

Two v13 findings in one section, because they are the same section.

**A sixth leftover** (inbound
[#386](https://github.com/DaveKJohn/davekjohns-workshop/issues/386)). For the first-time consumer
this family documents, `.claude/settings.json` does not exist before adoption — Quickstart Step 1 has
the reader create it. After a by-the-book teardown it is still there, holding `{}` at 3 bytes. Step 3
removes the keys and says so; the file itself was named nowhere, while the list it belongs to already
covers the `CLAUDE.md` scaffold prose, which is the same category: *a file that would not exist
without the adoption*. Small and harmless — but the section is called "honestly" and is explicitly
the complete list, so one row keeps that promise. The counts in its opening line move with it.

**The `CLAUDE.md` row's evidence is now the series, not its best round** (inbound
[#392](https://github.com/DaveKJohn/davekjohns-workshop/issues/392)). It cited round v11, where two
of two fresh sessions flagged the contradiction unprompted. v12 and v13 both measured **1 of 2**, so
the citation had quietly become the optimistic end of the range rather than the reading.

What the later rounds add is *when* it surfaces: across the four sessions of v12 and v13, the ones
that spoke up had been asked to **orient**, and the ones that did not had been given a **task** — one
of the silent ones flagged `CLAUDE.md` as an untracked leftover *"that does not belong in the
fixture"* while walking past the contradiction inside it. Four observations is a pattern and not a
law, and it is written down as one.

The advice does not change, and the row stays a **to-do**: a leftover that only sometimes announces
itself is precisely the one to close by hand, so 1-in-2 is the argument for that treatment rather
than against it. Only the evidence under it moved.

[PR #397](https://github.com/DaveKJohn/davekjohns-workshop/pull/397)

---

### #396 · a round's step-table totals are counted, not typed · Feat · 2026-08-02

`#371` fixed a hand-typed figure in a round's baseline table by measuring it. The table beside it —
the step table, whose totals line is what a whole round is hung on — was still counted by hand, and
was wrong in exactly the same way (inbound
[#387](https://github.com/DaveKJohn/davekjohns-workshop/issues/387)): the v12 line read *3 wrijving,
38 groen, 2 niet gemeten* over 43 rows while its own column held **4, 39 and 3 over 46**. One short
in every category — three rows added without the totals line following — and v13's assignment then
inherited it, naming three friction rows where the column had four.

`scripts/tests/round-tally.measure.ps1` counts the column instead, and prints the tally with the same
*generated, do not retype* marker the baseline block carries. Verified against the real v13 papers:
it reproduces v13's own line exactly (0 / 1 / 43 / 2 over 46) and independently confirms the v12
figures the finding reported.

**It has no vocabulary of its own.** No hardcoded status names, no hardcoded language, no hardcoded
markers: a cell that opens with a non-ASCII text element carries that marker, and the words after it
are that marker's label, taken from the table. So the tally cannot drift from the papers by holding a
stale idea of what "green" looks like, and a round scored in any symbols, in any language, counts the
same way. The totals come out as a table — one row per round — which is what makes comparing rounds
an output rather than a memory exercise.

Two properties are load-bearing rather than incidental, and both are pinned by tests:

- **Emphasis does not hide a cell.** The papers bold exactly the rows a round turned around, so
  reading `*` as the opening character would drop the four rows v13 was *about* while looking right
  everywhere else.
- **A markerless cell is reported, never dropped.** Older columns hold bare prose (`niet gemeten`,
  `niet opgetreden`). Counting them in no category is correct; staying quiet about them would produce
  a total that looks complete and is not — the same no-silent-caps rule the teardown's audit follows.

`-OutFile` writes UTF-8 without BOM, because a Windows PowerShell 5.1 redirect re-encodes stdout in
the console codepage and would put mojibake into the very block a reader pastes from.

[PR #396](https://github.com/DaveKJohn/davekjohns-workshop/pull/396)

---

### #395 · the untouched-install note is gated on the install record · Fix · 2026-08-02

`teardown.ps1` closed every run with *"The plugin install itself is untouched: run
`claude plugin uninstall …`"* — unconditionally, while the note directly above it was already gated
on the content of `settings.json`. Round v13 reached it by the route `UNINSTALL.md` Step 4 has
offered since `v3.1.2` (re-run the audit from the cache, which survives Step 2) and read that the
install was untouched **one step after** `Successfully uninstalled`, with the advice to run the
command again (inbound [#381](https://github.com/DaveKJohn/davekjohns-workshop/issues/381)). New
behaviour reached by the #373 repair, and unmeasured until someone walked it.

The condition was lying around: it is the same `projectPath` query `UNINSTALL.md` prints twice, in
Step 2 and again in Step 4. `Get-InstallRecordState` now asks it, and the note has three readings,
because *"no record"* and *"could not look"* are different claims:

- **a record points here** — the note names the plugin **and the scope the record is actually in**,
  rather than assuming `project`. A session start can write a `local` record by itself, and an
  uninstall aimed at the wrong scope is the failure the document spends a paragraph on;
- **readable, nothing points here** — it says so, and stops advising a command the reader has
  already run. This is what the Step 4 re-run now reads like;
- **missing or unparseable records file** — reported as a gap in the reading, never as a clean
  machine, and the teardown still exits 0.

`UNINSTALL.md` Step 4 says what to expect from that re-run, so the confirmation is documented rather
than discovered. Ten assertions cover the three states plus the unparseable route into the third.

Plugins: specialists

[PR #395](https://github.com/DaveKJohn/davekjohns-workshop/pull/395)

---

### #394 · the #327 disarm claim is conditional on which key stays behind · Fix · 2026-08-02

`UNINSTALL.md` Step 3 closed with *"Walk it through to the end of Step 5 and the mechanism is
disarmed, stray key or not."* Round v13 measured the opposite (inbound
[#382](https://github.com/DaveKJohn/davekjohns-workshop/issues/382)): after a by-the-book teardown
through Step 5 — record `{}`, `known_marketplaces.json` `{}`, clone and cache gone — with **both**
keys deliberately left behind, two session starts and no commands at all put the machine back on an
install record. Session 1 re-registered the marketplace and rebuilt the clone; session 2 wrote a
full `project` record.

The disarming does not hang on reaching Step 5 but on **Step 3 removing both keys**, and the two are
not equal: with only `enabledPlugins` left the machine does stay free (measured separately), so
`extraKnownMarketplaces` is the one that matters — it is the key that can put the marketplace back,
and everything else follows from that. The closing sentence now says so, and the key's bullet in
Step 3 is marked accordingly.

The three-state table gained a fourth row and lost one condition that was too strong. Its rows 1 and
2 read as a sequence rather than as alternatives — the state row 1 leaves behind *is* what row 2
fires on, which is what makes the whole thing possible unattended. And the record in row 2 does
**not** require the unpacked cache: v13's record pointed its `installPath` into a
`cache/davekjohns-workshop/…` directory that did not exist.

Folded in from the same round: a record written by a session start is recognisable by its **key
order** (inbound [#389](https://github.com/DaveKJohn/davekjohns-workshop/issues/389)) — a real
install puts `projectPath` second, a session start puts it last. A second signal next to
`installedAt` and independent of it, readable without the hand-edit that would wipe the evidence.
Written in as confirmation rather than proof, with its CLI-version caveat attached.

[PR #394](https://github.com/DaveKJohn/davekjohns-workshop/pull/394)

---

### #380 · A round's baseline table is measured, not typed · Feat · 2026-08-02

Test round v12's [#371](https://github.com/DaveKJohn/davekjohns-workshop/issues/371), and the last
open finding of that round. Its baseline table said the fixture README had **23** lines where the file
has **22** — in the papers of the round that was verifying #360, the repair about a figure naming its
convention. Both numbers are defensible: 22 is the count of line terminators, 23 is the number of line
positions an editor gutter shows. What the table lacked was the column that says which one is meant,
and its `hoe gemeten` cell — the documented remedy for exactly this — read `alle regels`, which names
nothing.

**Why this is a script and not a fourth doc fix.** The round's own closing note asked for it: the
papers live in `DaveKJohn/specialists-adoptietest`, outside the reach of check 15 and check 16, so
there the habit had to do the work — and it did not. `scripts/tests/round-baseline.measure.ps1`
computes every figure from a checkout and prints the markdown block, so the number cannot be a typo
and the convention cannot go unnamed. **It prints both line conventions as separate rows**, each with
its rule, which is the actual fix: a consumer who measures the other one is no longer left deciding
whether they mis-cloned.

**It reproduces v12's table exactly** — 1105 bytes blob, 1127 on disk, 22 terminators, 23 positions,
15 per `Measure-Object -Line`, 3 commits, `f56a9e6` — which is independent confirmation that the
reporter of #371 was right about the one row and that the other five were sound. The size delta is no
longer a claim in prose either: the row states that the 22-byte difference is exactly the 22 CRLF
conversions, which is the reasoning the reporter used to prove the line count.

**A hole it found in itself, on its first run.** The blob rows come from the ref and the disk rows from
the working tree. The smoke test measured `main` in a checkout standing on another branch, and the
table was right only because that branch happened not to touch the file. Right by luck is the class
this whole issue is about, so the script now refuses — hard error, no table — when the file on disk
differs from the ref, and the guard compares *normalized* content on purpose: a byte comparison would
reject every Windows checkout, which is the only kind this family runs. Both directions are asserted.

**Pinned by 47 asserts in `scripts/tests/round-baseline.tests.ps1`**, which drives the real script over
the `powershell -File` hop rather than dot-running it. Three of them are the reason the suite exists:
a file *without* a closing terminator must report the same number twice (a naive `terminators + 1`
passes the 22/23 case and lies here), no row may carry an empty or one-word `how measured` cell — the
defect itself, failing in CI instead of in someone's papers — and a CRLF working tree must not trip the
mismatch guard. The CRLF fixtures drive `core.autocrlf` per repo, so the suite gives the same verdict
on a CRLF and an LF checkout.

**Two things learned while building it, both now comments in the code.** `-Path` is a comma-separated
`[string]` rather than a `[string[]]`, because `powershell -File` cannot bind an array parameter and
`-Path a,b` would arrive as the single filename `a,b` — the same trap `pr-issues-lib`'s `-Resolves`
was reshaped for. And the first shallow-clone fixture was refused by the script: setting
`core.autocrlf` *after* a checkout leaves the working tree inconsistent with the config, so git reads
the file as modified. The fixture was wrong, not the guard.

The suffix follows `fresh-consumer.measure.ps1`: a `.measure.ps1` asserts nothing and stays out of
CI's `*.tests.ps1` glob, because on a fresh clone whatever it finds *is* the baseline. Its correctness
is what CI checks.

[PR #380](https://github.com/DaveKJohn/davekjohns-workshop/pull/380)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v3.1.2] - 2026-08-02 — Patch

See [releases/development/3.x/3.1.2.md](releases/development/3.x/3.1.2.md) for the full release notes.

---

### [v3.1.1] - 2026-08-02 — Patch

See [releases/development/3.x/3.1.1.md](releases/development/3.x/3.1.1.md) for the full release notes.

---

### [v3.1.0] - 2026-08-01 — Minor

See [releases/development/3.x/3.1.0.md](releases/development/3.x/3.1.0.md) for the full release notes.

---

### [v3.0.9] - 2026-08-01 — Patch

See [releases/development/3.x/3.0.9.md](releases/development/3.x/3.0.9.md) for the full release notes.

---

### [v3.0.8] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.8.md](releases/development/3.x/3.0.8.md) for the full release notes.

---

### [v3.0.7] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.7.md](releases/development/3.x/3.0.7.md) for the full release notes.

---

### [v3.0.6] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.6.md](releases/development/3.x/3.0.6.md) for the full release notes.

---

### [v3.0.5] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.5.md](releases/development/3.x/3.0.5.md) for the full release notes.

---

### [v3.0.4] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.4.md](releases/development/3.x/3.0.4.md) for the full release notes.

---

### [v3.0.3] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.3.md](releases/development/3.x/3.0.3.md) for the full release notes.

---

### [v3.0.2] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.2.md](releases/development/3.x/3.0.2.md) for the full release notes.

---

### [v3.0.1] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.1.md](releases/development/3.x/3.0.1.md) for the full release notes.

---

### [v3.0.0] - 2026-07-30 — Major

See [releases/development/3.x/3.0.0.md](releases/development/3.x/3.0.0.md) for the full release notes.

---

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
