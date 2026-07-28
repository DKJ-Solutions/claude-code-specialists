# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #213 · Hooks survive compaction, and consumer messages stop pointing at the workshop · Fix · 2026-07-28

Two findings from Dave's principle: **assume a consumer knows nothing about this workshop.** A
colleague who merely installs the plugin must be served by it, not put to work for it.

**1. The three session hooks went silent after the first `/compact`.** `hooks.json` matched only
`startup`, while a SessionStart hook's injected stdout does not survive a compaction on its own — the
[documented](https://code.claude.com/docs/en/hooks) way to keep it is to let the hook run again, which
it does only for the sources its matcher names (`startup`, `resume`, `clear`, `compact`, `fork`). So
every report — roster drift, script-contract drift, connector signals — disappeared from the context at
the first compaction and never came back. Now `startup|resume|clear|compact`.

`fork` is deliberately excluded: a forked session inherits the parent's context, so re-running would
only duplicate the report. The cost was **measured** before widening rather than assumed — all three
hooks together take ~4.6s (the connector check ~2.6s of it, since it runs the drift check per consumer),
less than the compaction they now run alongside. Because `hooks.json` is JSON and cannot carry a
comment, the reasoning lives in the hook docstrings.

This was filed in inbound #204 as one of two closing observations *"offered as data rather than as
asks"*, and left out of scope then. It turned out to be the load-bearing one.

**2. Two consumer-facing messages handed out homework in a repo the reader may not have.**

- **`[UNREGISTERED]`** said *"add connectors/<repo>.json in the workshop"*. Who benefits from
  registration is the plugin's maintainer; who was being instructed was the consumer. It now states that
  nothing there is broken (the plugin works normally; only the maintainer's view is missing) and
  addresses the fix conditionally — *"if you maintain the plugin source … if you just use the plugin, no
  action is needed on your side."* The hook's verdict line drops the word "workshop" too: internal
  nickname, meaningless to that reader.
- **A missing script-contract function** ended with *"update it from the workshop's own
  scripts\repo-config.ps1"* — useless advice for exactly the reader most likely to hit it. Each contract
  record now carries a `Returns` line stating in one sentence what the function must give back, so the
  finding is **self-contained**: the reader can write the function from the report alone. Example:

  > `[ERROR] 'Get-RosterPath' missing from scripts\repo-config.ps1 (required by: check-roster-sync) --
  > this lib predates the contract the shared script(s) call; add the function. It must return the
  > repo-root-relative path to the file holding the specialist roster -- 'CLAUDE.md' unless this repo
  > keeps it elsewhere.`

`Get-RecordReturns` degrades to the shorter message when a record has no `Returns`, so nothing breaks —
which is precisely why a record could be added without one and nobody would notice. A drift guard
asserts the `Returns` count equals the record count, so a ninth record without one turns the suite red.

Two test-quality notes worth keeping. The "no workshop jargon" assertion first failed on the *fixture*
rather than the hook: the stub still carried the old message text, making the hook look guilty of words
it never produced. Stubs that exist to prove a wording must carry the real wording. And the intended
demonstration against smartwatchbanden could not run — that repo's session had already repaired its
script contract while this branch was being built, so its eight functions now report `[OK]`. The
demonstration moved to a throwaway fixture instead.

Plugins: specialists

[PR #213](https://github.com/DaveKJohn/davekjohns-workshop/pull/213)

---

### #211 · Adopting a new specialist is the default, not a question · Docs · 2026-07-28

Dave, during the smartwatchbanden catch-up: the session asked him, one by one, which of five new
specialists to adopt. His answer — *it should always just be adopted after a plugin update.*

**The asking came from a hand-written handover prompt, not from the system.** Nothing in the plugin or
the repo docs said to ask; the prompt for that session did, explicitly. That is the interesting part:
the rule had no home, so whoever writes the next prompt is free to invent the approval step again. It
now lives in the two places a session actually reads at that moment — the `sync-roster` skill (where
the catch-up is staged) and `check-roster-sync.ps1`'s docstring (where the `[ERROR]` comes from) —
rather than in a prompt that is written once and forgotten.

**The reasoning, because "always adopt" sounds careless and is not.** The lens scaffold is empty on
purpose: a `VUL-IN` lens may sit untouched until that specialist actually has work in the repo — that
is what the scaffold is *for*, not an unfinished task. So adopting costs a file nobody has to fill in
yet, while asking costs an interruption over a decision with no downside either way. That is exactly
the shape of approval question the governance rule already rules out: reserve them for the
irreversible, the outward-facing, and the genuinely risky.

What stays a judgment call is the *content* — what the lens says once the specialist has work, and
where the roster row belongs — and those are writes to the governance doc, which `sync-roster`
deliberately never makes. Adoption and lens content were being treated as one decision; they are two,
and only the second needs a human.

**The ignore-list keeps its role, with its character corrected.** `Get-RosterIgnoredIds` is for a
specialist that genuinely has no place in a repo, recorded on your own initiative with a comment
naming who and why. It is a statement, not an answer to a per-update question.

Also corrected in the same pass: the ordering advice given for the smartwatchbanden catch-up. Fixing
the script contract still has to come first, but for a different reason than was written down. It is
not "so that skipping becomes possible" — it is that `check-roster-sync` needs `Get-RosterPath` and
`Get-RosterIgnoredIds` to run without a hard error at all.

Plugins: specialists

[PR #211](https://github.com/DaveKJohn/davekjohns-workshop/pull/211)

---

### #210 · Record the measured smartwatchbanden gap in its register note · Chore · 2026-07-28

Preparation for the smartwatchbanden catch-up: its checkout is on the workshop machine, so the
v2.10.0 checks could be run against that tree directly. The result replaces the note's single
Bianca observation with the full, measured picture rather than an estimate.

**What was measured**, in two parts:

- **Script contract** — `scripts/repo-config.ps1` is missing `Get-RosterPath` and
  `Get-RosterIgnoredIds` (both required), plus the optional `Get-ChangelogHeading` and
  `Get-LiveStage`. `scripts/lib/branch-info.ps1` is complete. **This is the exact fingerprint that
  misled inbound #203**: the 2026-07-27 alarm about those two missing roster functions was true, about
  *this* repo, and it was reported into a life-hub session. Seeing it here closes that loop
  empirically — the check was right, about the wrong repo, which is precisely what #203 fixed.
- **Roster/lenses** — five specialists have neither a roster row nor a lens: 03-02 (Bianca, persona),
  06-24 (Ravi), 06-25 (Nolan), 06-29 (Marlowe), 06-30 (Auden). Everything else is clean: no orphans,
  no off-path lenses, no stale lens headers.

**The `extensions` arrays are deliberately left untouched.** They list 14 + 3, which is exactly what
that repo actually has — verified file by file against the canonical path (no legacy path in use). This
register records what a consumer *has*, not what it should have, so pre-filling the five missing ids
would make the check report them as `registered extension(s) missing` in the consumer. The inventory
gets updated after lenses actually land there, per the register's own "the registry data should follow
reality" rule.

**One ordering constraint recorded with it, because the intuitive order is wrong.** The script contract
has to be fixed *before* deciding per specialist: `Get-RosterIgnoredIds` is the mechanism for recording
a deliberate non-adoption, so while it is absent, "skip this one" is not an implementable outcome and
adopting all five is the only route that works. A session that takes the decisions first would either
stall or quietly adopt specialists nobody asked for.

Whether each of the five is adopted or deliberately skipped stays Dave's call per specialist — that
decision is not pre-empted here, only the data it needs.

[PR #210](https://github.com/DaveKJohn/davekjohns-workshop/pull/210)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

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
