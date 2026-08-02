# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #368 · The mojibake gate peels by the inverse operation, not by a table of known sequences · Fix · 2026-08-02

Found while measuring the surface for a different gate: `check-plugin-integrity.ps1` reported
`[mojibake] ... No findings` over files that held **517 doubly-encoded runs** — 315 em dashes, 43
arrows, 10 ellipses, 4 en dashes. Three of the four damaged files sat inside the check's own stated
scope, and the damage had ridden into `v3.1.0`: the root `CHANGELOG.md`, the specialists
`CHANGELOG.md`, its **consumer-facing** `RELEASE.md` card, and the 3.1.0 release notes.

**Why the gate could not see it.** `fix-mojibake.ps1` worked off a hand-written table of known
sequences, and the gate is deliberately nothing more than that tool run as a child process — one source
for "what does damage look like". The table carries the single-layer form of these four characters and
exactly one outer-layer peel rule, added when double encoding first bit. Damage double-encoded in any
*other* character matches no rule at all, so the fixpoint loop exits on its first pass with nothing
found. Shared source, shared blindness: the property that keeps repair and detection in step also kept
them wrong together.

**The repair is the method, not four more rows.** Mojibake is one specific operation — UTF-8 bytes
decoded as Windows-1252 — so its inverse is equally specific. Each run of non-ASCII text is now
re-encoded to Windows-1252 and decoded as UTF-8, repeatedly, for as long as the result gets shorter.
That repairs any character rather than the seventeen somebody wrote down. Both encoders are **strict**:
with the default fallbacks an unrepresentable character silently becomes `?` and invalid bytes become
`U+FFFD`, which would turn a repair tool into a corruption tool; strict, the round trip simply fails on
text that was never mojibake, and failure means leave it alone. Verified before adoption rather than
assumed — a correct em dash, arrow, middot, e-acute, a two-character run of u-diaeresis and an emoji all
survive untouched, while the eight-character double-encoded em dash peels to three characters and then
to `—`. The table stays as a net under the round trip for runs it cannot reach.

**Two reporting repairs alongside it.** The archived notes under `releases/` were outside the tool's
path list and held the largest single concentration of damage (474 sequences in `3.1.0.md`); they are in
scope now, because "history is not rewritten" protects what a note *said*, not a mis-decode nobody wrote.
And the coverage line said `checked 1` — the number of tool invocations, which is true of every possible
scope and therefore evidence of none. It now reports the file count the tool states (186) and names
`releases/` in its scope.

All 517 sequences repaired, confirmed by a detector written independently of the tool rather than by the
tool's own verdict.

Plugins: specialists

[PR #368](https://github.com/DaveKJohn/davekjohns-workshop/pull/368)

---

### #367 · QUICKSTART's checks are ones a fresh consumer can actually pass · Docs · 2026-08-02

Four findings from test round v11, all in `QUICKSTART.md`. Three are the same class — a captured sample
presented as a fixed expectation without naming what it was bound to — and the fourth is a verification
that reported green on a state that was not.

**The `projectPath` query passed while nothing was installed** (inbound #355). Measured on a fresh
profile after three session starts and zero `claude plugin` commands: the record read `project 3.1.0`
with the correct sha, the page's own query returned a clean line, and `installPath` pointed at a
directory that did not exist. No cache, no payload, three consecutive sessions that loaded nothing. The
query now resolves `installPath` and prints `payload present` or `PAYLOAD MISSING` as a fourth field, so
a record cannot pass as evidence of a payload — verified in both directions before shipping. The `#327`
blockquote said the payload "sat in the cache", i.e. one notch better than what v11 actually found; it
now carries both measurements.

**That same round settles the question the blockquote left open** (inbound #350). The experiment this
page prescribed has been run, and the two `claude plugin` commands are **not** redundant: a session start
registers the marketplace and writes a complete, correct-looking record, but never fetches the payload.
`marketplace update` + `install` are what do. The commands stay, now for a measured reason rather than
caution.

**The expected bootstrap `Done:` line was captured in the wrong kind of repo** (inbound #358). It
promised `0 script-scaffold(s) created, 2 already present`, which is what a repo that *already had* those
scaffolds prints. A fresh repo — this step's own audience — gets the inverse. The sample is now the
fresh-repo one, and the guidance covers both directions instead of only "lower than this": each pair
reads as `created + already present`, and the sum is what the page promises.

**Step 3 told you to look for a header no bootstrapped repo emits** (inbound #361). It asked the reader
to confirm `🧭 Chris — intake & routing`. Neither the portable persona nor `specialists-init` writes any
such rule — the persona guarantees *"This one is for \<name\> — \<reason\>."*, which is exactly what the
round measured. So the behaviour was correct and the acceptance check was unpassable, on the step that
exists to prove the install worked. The check is now the invariant (a named owner with a stated reason),
with a sample marked as illustrative and a note that a fixed per-turn header is a house style a repo
writes into its own `CLAUDE.md`, not something this plugin ships.

**The predicted scopeless-uninstall error was stale** (inbound #359, the "Staying up to date" half; the
`UNINSTALL.md` half shipped in #366). On CLI `2.1.220` the message names the scope and the settings file
and suggests `plugin disable --scope local`, which is not the step to follow. Quoted as version-bound,
with the flag named as the invariant.

[PR #367](https://github.com/DaveKJohn/davekjohns-workshop/pull/367)

---

### #366 · UNINSTALL names what it leaves behind, and what the leftover does · Docs · 2026-08-02

Three findings from test round v11, all in `UNINSTALL.md`, all the same shape: the page describes an
operation correctly and stops one sentence before the consequence.

**Step 2's predicted error text was stale, and the CLI now suggests the wrong remedy** (inbound #359).
On CLI `2.1.220` a scopeless `uninstall` no longer says *"not installed at scope user"* — it names the
scope and the settings file, which is an improvement, and then suggests `plugin disable --scope local`.
That is a different operation: it writes a local disable key on top of the project setting and leaves
the install in place, so Step 4's verification does not come back empty and the reader has added a key
instead of removing one. The measured message is now quoted, the CLI's own suggestion is explicitly
ruled out, and the paragraph says which part of it is version-bound — the flag is the invariant, the
wording is not.

**Step 5 did not mention that `marketplace remove` leaves an empty key** (inbound #357). It edits
`~/.claude/settings.json`, removes the `davekjohns-workshop` block, leaves `"extraKnownMarketplaces": {}`
and re-serialises the file. Step 2 already says exactly this about `"enabledPlugins": {}` and calls a
diff there the command working rather than a fault; the mirror-image sentence was simply missing. Worth
stating because it settles a question a clean-machine check keeps raising: after a by-the-book teardown
that row is never *literally* clean — the keys are empty, not absent.

**The surviving scaffold prose was listed as inert, and it is not** (inbound #362). `CLAUDE.md` is loaded
into every session as project instructions, so the two lines the bootstrap wrote keep telling later
sessions — in the channel that outranks their defaults — that the repo is governed by a system that is
no longer installed. Two separate fresh sessions flagged the contradiction unprompted. The reasoning for
keeping the lines is unchanged and still right: prose loads nothing on its own, and a script that deletes
sentences out of a governance file is doing the damage the classification exists to prevent. What changed
is that the row is now a to-do with two one-line remedies rather than a note ending in "yours to decide",
and the section's opening count moved with it — three of the five leftovers are correct, two are things
to act on.

[PR #366](https://github.com/DaveKJohn/davekjohns-workshop/pull/366)

---

### #365 · The kept count matches its markers, and the hook stub cannot be copied by accident · Fix · 2026-08-02

Two findings from test round v11, both in the reporting layer rather than in what the scripts do.

**`specialists-teardown` summarised itself as `0 kept` while printing two `[KEEP]` lines** (inbound
#356). The scaffold-prose loop added in #331 printed its own marker straight to the host and never
touched the `$kept` tally, so a run on the fresh-consumer row — a repo with no `CLAUDE.md` before
adoption — printed two `[KEEP]` markers, a `[note]` saying "2 line(s)", and a summary contradicting
both. The figure a reader skims to was the one that said nothing was left behind, which is precisely
the failure #331 was filed about, occurring inside the repair for it. Every `[KEEP]` marker now goes
through one `Add-Kept` door, so the markers and the number cannot drift apart — the same "one list,
one number" lesson #275 established for the remove side, applied to the half it did not reach. The
kept items carry which remedy applies to them and the summary groups by it: the `-EmptyLensPattern`
escape hatch is true of a file whose shape the script did not recognise and false of a prose line in
a governance file, so one blanket paragraph over both would have to be wrong for one of them.

**`settings.suggested.jsonc` invited copying a hook that points at nothing** (inbound #363). The
bootstrap proposes a `Stop` hook running `scripts/maintenance/lint-changed-hook.ps1`, a file it does
not create and nothing else ships. The proposal file did already say twice that its hooks are a stub
— so the gap was not the missing warning the issue reports, but where that warning is not: the
console's step 3 says "copy desired parts" with no exception named, and that console line is the
instruction a reader acts on. The path is now visibly a placeholder (`<your-check>.ps1`) rather than
a plausible-looking real one, and step 3 states which block is ready to use and which is not. Same
step also gave the file a trailing newline, which it never had — the `#337.2` warning names
`CLAUDE.md` for that and does not cover this file, so nothing pointed at it.

Regression covered on the v11 fixture itself, in both preview and apply mode, as the invariant
(every printed marker is counted) rather than against a literal count — a hardcoded expectation
could pass while both sides carried the same error, which is the failure the test exists to catch.

Plugins: specialists

[PR #365](https://github.com/DaveKJohn/davekjohns-workshop/pull/365)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

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
