# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #299 · read enabledPlugins from the settings chain, not settings.json alone · Fix · 2026-07-31

Inbound [#294](https://github.com/DaveKJohn/davekjohns-workshop/issues/294), measured in
`DaveKJohn/life-hub` against 3.0.5: three places read `enabledPlugins` from `.claude/settings.json`
alone, while Claude Code honors a **chain** of settings files -- and this plugin's own settings proposal
points the reader at the other end of it (*"Copy desired blocks to .claude/settings.json (or
settings.local.json)"*). One blind spot, three symptoms, in both directions at once:

- **False green.** `roster-sessioncheck` reported *"roster in sync with the enabled plugins"* for a repo
  with 0 lenses, 0 roster rows and no `@`-import -- in the very session that had loaded four of its
  skills and all three of its hooks. With nothing enabled the `[BOOTSTRAP]` branch cannot fire either,
  so the run reached the exit-0 branch and printed the single most reassuring line that hook owns for
  the least configured repo it had ever seen. That is the sentence `roster-sessioncheck.ps1` says in as
  many words it must never print, and the same class as the gap #225 closed -- reached through another door.
- **Silent skip.** `bootstrap.ps1` placed **19** lenses instead of 24 and said nothing about the 5 it
  never considered, because `specialists-lifehub` was enabled in a file it did not read.
- **False alarm.** `check-connectors` reported *"plugin is NOT (or no longer) enabled"* for that same
  repo in that same session -- literally true about `settings.json`, false about the session.

**The fix is one shared reader, not three local patches** -- the identical blindness produced a
reassuring lie in one gate and a spurious error in another, so a reader who cross-referenced them
learned to trust neither. `Get-EnabledPlugins` in `check-report-lib.ps1` (the lib all three call sites
already dot-source) reads the whole chain -- user `~/.claude/settings.json`, `.claude/settings.json`,
`.claude/settings.local.json` -- with per-key precedence, local winning. Every verdict now names the
**layer** an enable came from, so an enable arriving from outside the repo is diagnosable instead of
mysterious.

Two decisions are recorded on the helper rather than left implicit. The **user layer is in**: a plugin
enabled at user scope is loaded in every session, so a repo that does not roster it genuinely has drift,
and excluding that layer would rebuild the same false green one level up. Verified before including it
that it widens nothing silently here. And precedence is **per key**, not wholesale layer replacement,
because that errs in the safe direction for these three callers: it never *loses* an enable, so the worst
case is a visible drift report rather than the false green this exists to kill.

Beyond the cause, the failure **shape** is closed too: the check emits a non-counting
`[NOTHING-ENABLED]` roll-up and the hook gives it its own verdict, so any future route to zero enabled
plugins still cannot read as a healthy roster. It travels with the drift headline as well, for the one
state that reaches that branch with nothing compared. The bootstrap now says what it skipped and why --
the old code only spoke up for an *unreadable* `settings.json`, so the case that actually happened (a
valid file without the key) passed in complete silence.

**Two defects found while verifying, both fixed here:**

- A settings file holding exactly `{ }` was reported as *"does not parse"*. Under
  `Set-StrictMode -Version Latest` the repo-wide `$obj.PSObject.Properties.Name -contains ...` idiom
  **throws** on an object with no properties. The old inline reader hit this too, where `EAP = 'Stop'`
  turned it into a dead check reported as *"could not complete"*; routing it through a `catch` merely
  relabelled it as corrupt, which is worse -- a confident false statement about a perfectly ordinary
  consumer file. `{ }`, `"enabledPlugins": { }` and `"enabledPlugins": null` are now all answers.
- The id list was sorted with `Sort-Object`, whose **culture-aware** collation orders
  `specialists@...` before `specialists-lifehub@...` while an ordinal comparison does the reverse. Either
  order is defensible; a check whose output order depends on the machine's culture is not. Now ordinal.

**Verified live**, not only in fixtures: a throwaway consumer with the enable **only** in
`settings.local.json` gets **24** lenses (19 + the 5 of `specialists-lifehub`, all 5 present on disk) and
reaches `[BOOTSTRAP]` instead of a silent green; `life-hub` -- which has no enable anywhere since the v3
teardown -- now gets the `[NOTHING-ENABLED]` verdict instead of *"roster in sync"*; and the connector
check's remaining errors are true ones that name the whole chain.

**Tests:** the settings chain gets direct unit assertions (order, per-key precedence both ways, the user
layer, the valid-but-crashy shapes, an unparseable layer); `roster-sync` gains the local-only enable in
both its in-sync and its `[BOOTSTRAP]` form, the precedence case, the unparseable-layer case and two hook
verdicts; `connectors` gains the local-only enable and the chain wording. All three suites also **pin the
user layer to a throwaway home**, because a chain that reads outside the repo would otherwise make the
lens counts depend on what the machine running the suite has enabled globally.

**Gates:** `check-plugin-integrity` 0 errors, **18/18** suites green.

Plugins: specialists

[PR #299](https://github.com/DaveKJohn/davekjohns-workshop/pull/299)

---

### #293 · install does not refresh the cache — measured, so stop calling it unmeasured · Fix · 2026-07-31

`v3.0.5` was cut to ship #292, and the stale-cache window it opened was used for the question #292 had
to leave open. **That window expires** — it lasts only until something refreshes the clone — so it was
measured the minute it existed instead of left for the next adoption round, which had already reported
it as an unreachable gap twice
([#287](https://github.com/DaveKJohn/davekjohns-workshop/issues/287) §5.1, and the round before it).

**The measurement, as a controlled pair.** Same machine, same minute, two fresh throwaway folders, with
the cached clone recorded beforehand as sitting on the `v3.0.4` commit and not containing the `v3.0.5`
one:

| | command | result | clone afterwards |
|---|---|---|---|
| A | a fresh project-scoped install, **no refresh** | **3.0.4** — the previous release | unchanged, still on `v3.0.4` |
| B | `claude plugin marketplace update` first, then the same install | **3.0.5** | advanced to `v3.0.5` |

So **`install` does not refresh the cache and `update` does.** The per-command distinction #292
introduced is no longer half-measured: the `install` half rests on two independent measurements on two
different releases (July 30 after `v3.0.2`, July 31 after `v3.0.5`), and the refresh is *load-bearing* in
front of an install where it is idempotent insurance in front of an update. Both keep it.

**One detail that is worse than the earlier account said.** The install's success line names the **scope
and no version at all**. Previous notes said "nothing in that output hints the version is stale", which
understates it: there is no version in the output to be suspicious of. The install record is the only
place it appears — exactly why the adoption path verifies against `installed_plugins.json` rather than
reading a success line.

**What this corrects.** [Rendall #06's lens](.claude/specialists/lenses/05-06-extension.md) said in as
many words that the `install` half was *"still unmeasured: that needs the next release's stale window"* —
true when written a few hours earlier, false now, and left alone it would be the same class of defect this
repo spent the day closing. Corrected there, in the QUICKSTART's *Staying up to date*, in
`specialists-init` step 0b, and in the root README's *Versioning*. Rendall's lens also gains the
operational lesson: **the stale window after `cut-release.ps1` pushes the tag is a measurement opportunity
that expires**, so an open cache question gets answered then or waits a whole release.

Not claimed: any mechanism. *Why* `update` refreshes and `install` does not was not established, and the
docs state the two measured behaviours rather than a theory about them.

Plugins: specialists

Plugins: specialists

[PR #293](https://github.com/DaveKJohn/davekjohns-workshop/pull/293)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

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
