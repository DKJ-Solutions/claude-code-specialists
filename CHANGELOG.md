# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

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
