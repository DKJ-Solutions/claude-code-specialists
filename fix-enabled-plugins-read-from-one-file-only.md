### read enabledPlugins from the settings chain, not settings.json alone · Fix · 2026-07-31

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
