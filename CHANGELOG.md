# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #319 · the record names a commit, and the clone tracks main · Docs · 2026-08-01

Closes inbound [#313](https://github.com/DaveKJohn/davekjohns-workshop/issues/313), the heaviest of round
v8's three findings (overview: [#316](https://github.com/DaveKJohn/davekjohns-workshop/issues/316)).

**A consumer runs `main`, not the release, and every documented way of asking said `3.0.8`.** Round v8
measured a consumer that had moved `3.0.6 → 3.0.8` with no command run and landed three commits past the
`v3.0.8` tag. `plugin.json` reads `3.0.8` on both commits, so the version string cannot express the
difference — while the payload genuinely differed (the same `SKILL.md` hashed differently on the tag and in
the installed cache), and `3.0.7` was never cached at all, so that release's fixes were skipped over
entirely. `gitCommitSha` was the only field that could tell the two apart, and it appeared **nowhere** in
the payload.

**Both printed record queries now name the commit** — step 0c in `specialists-init/SKILL.md` and step 1 in
the QUICKSTART — with the reading a user needs beside them: `version` identifies the *release*,
`gitCommitSha` identifies the *code*, they can disagree, and when they do only the second is true. Step 0c
also carries the one-line `git rev-list` that settles which of the two you are on.

**And the mechanism is now recorded as measured rather than suspected, which is more than the issue could
establish.** The issue proposed saying "the clone tracks `main`"; that has since been verified directly —
the cached marketplace clone has `main` checked out, tracking `origin/main` — and the *documented*
two-command update procedure was run deliberately in this repo, producing the identical state
(`version 3.0.8`, sha on `main`). So this is not an artefact of an unknown scheduler: **the documented
update path cannot deliver a tagged release, because the source it reads is a branch.** Every commit merged
after a release ships to consumers immediately under the previous release's version number. The opening
line of *Staying up to date* said updates "reach you via releases" and now says what releases actually do
(announce) versus what lands (whatever `main` holds).

Two consequences spelled out for consumers, because both change how a reader should act: the family's own
discipline of *"pin source locations against the release tag"* does not hold inside a consumer, so pin
against the sha the record names; and a bug that will not reproduce against the tag may still be real,
because you were never on the tag. What stays open is deliberately marked open: that a refresh moves you to
`main` is settled, but what *triggers* an unasked refresh is not, and that half is CLI behaviour rather
than plugin code.

Plugins: specialists

[PR #319](https://github.com/DaveKJohn/davekjohns-workshop/pull/319)

---

### #318 · report the local-scope record a session start leaves behind · Feat · 2026-08-01

Closes inbound [#314](https://github.com/DaveKJohn/davekjohns-workshop/issues/314), the second of round
v8's three findings (overview: [#316](https://github.com/DaveKJohn/davekjohns-workshop/issues/316)), and
gives [#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315) the mechanism its documentation
fix could not provide.

**The finding: `[NOT-INSTALLED-HERE]` cannot fire from a session at all.** The fix for #302 was present
and correct in the payload, and round v8 built the exact partial fixture it targets — three plugins
enabled, one with no record anywhere on the machine — and got the line on no branch. Not a bug in the
predicate: **the session start writes the missing record itself**, with a fresh `installedAt`, so the
state has healed before any hook can look. The marker is reachable only by a *deliberate* run in a repo
where a record went missing and no session has started since — a far narrower window than the code's own
blind-spot note claimed, and that note is corrected in place rather than quietly widened.

**What survives a session start is a record of the wrong shape, and nothing reported it.** So there is now
a fifth non-counting marker, `[RECORD-SHAPE]`, joining `[ORPHANS]` (#204), `[UNREGISTERED]` (#208),
`[INVENTORY]` (#220) and `[BOOTSTRAP]` (#225) — reached for rather than invented, which is that pattern's
own instruction. It reports two measured shapes:

- **a record scoped `local` and none `project`** — what a session start leaves behind (#314);
- **more than one record for one `projectPath`** — what the prescribed repair install leaves (#315).
  Step 0c already taught the reader that two lines is the signal, but only a human eyeballing that query
  ever saw it. That is the "a rule with no mechanism" shape, and this closes it.

Not an `[ERROR]`, deliberately: the plugin loads from a `local` record just as well, so nothing is broken
and exit 1 would be a lie. Neither shape can indicate tampering — the CLI writes both. It gets **its own
verdict line** in `roster-sessioncheck`, and that is the point of the change: on a clean run the state
would otherwise fall through to *"roster in sync with the enabled plugins"* — true about the roster, and
the most misleading thing the hook could say to that reader. It also rides along with the drift, bootstrap
and not-installed headlines, since an `[INFO]` the hook suppresses is indistinguishable from no finding.

`Get-RecordShape` sits beside `Test-PluginInstalledHere` rather than inside it: one predicate must stay
permissive (a false not-installed claim is the cry-wolf failure #294 spent a release removing) and the
other strict about a shape. The tests assert both on the same fixtures, so the disagreement is pinned
rather than merely argued — "still installed here" stays true in every case the new one reports.

Coverage: 6 new scenarios in `roster-sync.tests.ps1` (11g–11l) plus 3 hook-branch cases (H11–H11c), and a
`Get-RecordShape` block in `check-report-lib.tests.ps1` including all four states that belong to another
marker — a pathless record, no record, an absent `scope` field, and an unreadable administration — so the
predicate cannot grow into its neighbours' territory unnoticed.

Plugins: specialists

[PR #318](https://github.com/DaveKJohn/davekjohns-workshop/pull/318)

---

### #317 · local as a third scope, and the duplicate record the documented repair leaves · Docs · 2026-08-01

Closes inbound [#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315), the first of the
three findings from adoption round v8 (overview:
[#316](https://github.com/DaveKJohn/davekjohns-workshop/issues/316)).

**Two things the family's docs got wrong about the install record, both measured in
`DaveKJohn/life-hub` on July 31, 2026 (CLI `2.1.220`):**

- **The prescribed repair install leaves a *duplicate* record.** Re-installing at project scope against
  a path that already carried a record adds a second record beside it instead of correcting the first,
  and reports `✔ Successfully installed` both times. That is exactly the "stray second record" step 0c
  already warns about — so the document warned against a state its own remedy produces, and the only
  signal is the *line count* in its own verification query. Both `specialists-init/SKILL.md` step 0c and
  the QUICKSTART's step 1 now say **one** line per plugin, and say why two can happen.
- **`local` is a third scope, and it is not written by the reader.** A session start creates a missing
  record itself and flips an existing `project` record to `local` — no command run, no file in the repo
  changed, nothing reporting it. It was documented nowhere in the payload (`git grep`: no hits), so a
  reader who met it had nothing to look it up in. Both docs now name all three scopes, say which one a
  session start produces, and give the removal that actually works.

**And the same class turned out to be sitting in the lint gate.** Check 11 required `--scope project` on
every printed lifecycle command — which would have rejected `claude plugin uninstall … --scope local`,
the only command that removes such a record (`--scope project` refuses it with *"installed in local
scope, not project"*). The gate encoded the very assumption round v8 disproved: that `project` is the
only scope a consumer can be in. The scope rule is therefore **verb-specific** now — `uninstall` accepts
`project` or `local`, `install`/`update` keep the stricter rule, since nothing measured says a
local-scoped install is ever wanted. Two new scenarios in `check-plugin-integrity.tests.ps1`: 26 proves
the allowance, 27 proves it did not leak to the other verbs. Scenario 25 also got the docstring entry it
was missing.

Plugins: specialists

[PR #317](https://github.com/DaveKJohn/davekjohns-workshop/pull/317)

---

### #312 · the record-adoption reproduction is reported upstream, with the link · Docs · 2026-07-31

Closing the one item [#306](https://github.com/DaveKJohn/davekjohns-workshop/issues/306) left outside the
PR series: the record-adoption behaviour from
[#301](https://github.com/DaveKJohn/davekjohns-workshop/issues/301) is CLI behaviour, so the only thing this
repo could do with it was report it. Reported, and now recorded here rather than living only in an issue
comment.

**It went to [anthropics/claude-code#76759](https://github.com/anthropics/claude-code/issues/76759#issuecomment-5146633011)
as a comment, not as a new issue.** That report already documented the *write* — a session start driven by
`enabledPlugins` writing `installed_plugins.json` — measured on Linux with CLI `2.1.207`. What v7 measured is
the same write with a consequence it had not covered: the entries can carry the `installedAt` of **another
project's** record, and that project's record is gone afterwards. Same root, worse outcome, so adding to a
well-written report beats filing a near-duplicate beside it.

Two things came out of searching before writing, which is the part worth keeping:

- **The upstream tracker already held eight open issues about this file**, including
  [#75392](https://github.com/anthropics/claude-code/issues/75392) — `install --scope project` **overwriting**
  `installed_plugins.json` rather than merging. That is a plausible mechanism for the loss we measured: a
  write that replaces the map instead of adding to it takes every other project's entry with it. Named as a
  possibility in the comment, not as a conclusion — we measured the file's contents, not the implementation.
- **Our reproduction adds a platform and a version**: Windows 11, CLI `2.1.220`, against that report's
  Linux/`2.1.207`.

`specialists-init/SKILL.md` now carries the link and that framing, plus the line that matters most for a
reader of this plugin: **nothing here depends on an upstream fix.** The checks detect the state locally since
v3.0.7, which is the half this repo controls.

The gaps stay stated rather than smoothed over: the trigger is still not isolated, and the rule by which a
victim record is chosen is still unmeasured.

Plugins: specialists

[PR #312](https://github.com/DaveKJohn/davekjohns-workshop/pull/312)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

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
