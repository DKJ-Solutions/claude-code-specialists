### the checks read the install record, not just enabledPlugins · Fix · 2026-07-31

Inbound [#302](https://github.com/DaveKJohn/davekjohns-workshop/issues/302) and
[#304](https://github.com/DaveKJohn/davekjohns-workshop/issues/304), both from `DaveKJohn/life-hub`'s
adoption round **v7**, measured against `v3.0.6` (tag-commit `d9a57e6`).

## #302 — the other half of what Claude Code needs

Claude Code wants **two** things before a session loads a plugin: an **enable** in the settings chain,
and an **install record** for this project path in `~/.claude/plugins/installed_plugins.json`. #294
taught these checks to read the first one properly. Nothing read the second — so a mirror image of #294
lived in the same scripts, pointing the other way.

Measured in a throwaway consumer with three plugins enabled and no record for its path:

| | what it said |
|---|---|
| the session | zero specialists skills, zero subagents, **zero hook output** |
| `check-roster-sync` | **27 specialists**, one `[ERROR]` each |
| `bootstrap.ps1` | **27 lens files** written — `4 persona-lens(es), 23 lens-scaffold(s)` |

Where #294's blindness produced a reassuring lie in one check and a spurious error in another, this one
produces a confident, fully detailed report about a plugin surface that is not there. The plugin had
already written down why that is the dangerous direction (`specialists-init/SKILL.md`): *"no hooks
because the plugin is not loaded" reads exactly like "no hooks because everything is in order"*.

**The fix is to lift out the one reader that already existed, not to add a second.** #302's grep for
`installed_plugins` over the plugin tree came back with prose only — and that was true as scoped: the
sole reader lived in `scripts/sync/check-connectors.ps1`, workshop-owned, outside the tree searched. So
`Get-InstallRecord` + `Test-PluginInstalledHere` now live in `check-report-lib.ps1`, the lib all three
call sites already dot-source, and the connector check asks them instead of hand-rolling the query.
"One reader per call site, tightened in none of them" is the sentence #294 was filed about; a second
reader would have re-earned it.

`check-connectors`' matching rules are preserved verbatim, because they encode a defect of their own
(#240): **every** matching record, never just the first, and case- and trailing-separator-insensitive,
since two spellings of one path are not two answers.

**What each caller now says:**

- **`check-roster-sync`** — one non-counting `[NOT-INSTALLED-HERE]` roll-up, in the family of
  `[NOTHING-ENABLED]`/`[BOOTSTRAP]`/`[ORPHANS]`, naming the count, the ids and the one command that
  fixes it, plus a non-counting detail line per plugin naming the enabling layer. Not an error — the
  repo is not broken and the state is usually one install away from intended — but it can never again
  read as a checked, healthy roster.
- **`roster-sessioncheck`** — its own verdict above the in-sync line, and it rides along with the drift
  and bootstrap headlines, which would otherwise describe a surface no session in this repo has.
- **`check-connectors`** — the existing *"no machine record for this consumer"* `[INFO]` was worded
  purely as a version check that could not run. When the plugin is **also enabled** there, the same fact
  means a session in that checkout loads none of it, and **that repo cannot report it** — the hook that
  would is inside the plugin that is not loading. It stays `[INFO]`, deliberately: a consumer
  legitimately used from another machine has no record here either, so the state is not conclusive and
  the message names both readings.
- **`bootstrap.ps1`** — the closing count is qualified instead of left to read as a clean setup, with a
  copy-ready install command per plugin. Since #294 the script said what it *skipped*; the reverse
  asymmetry was missing.

**Three decisions recorded on the helper rather than left implicit.** A **pathless** record (the
user-scope shape) covers every repo, so it never yields a "not installed here" claim — the honest note
is that this shape is *inferred* from the field's absence being meaningful, not from a user-scope
install that was watched being written, and erring this way can only suppress a warning, never invent
one. An **unreadable or absent administration** keeps the predicate permissive: absence of the authority
is not evidence of absence, and a check that fires its loudest new signal where it knows least is the
cry-wolf failure #294 spent a release removing. And the marker's **own blind spot is stated**: when *no*
plugin is installed for a path, the hook does not run at all, because the hook ships in the plugin — the
total case is covered from the workshop by `check-connectors`, the one vantage point that still has a
voice when a consumer has gone silent.

## #304 — "is present in" named three layers where the key was in one

`check-roster-sync.ps1` used `$enabled.Summary` for a claim about **where the key lives**. `Summary` is
the phrasing of `Consulted`, and `Consulted` is *the layers that exist* — so it answers "what did you
look at?", never "where is the key?". Measured in life-hub: the key sat in exactly one of three layers
(the user one, as an empty object), and the line named all three — sending a reader looking for it to
the two repo-owned files that demonstrably do not have it, which are the two they open first.

That inverts the promise #294 was fixed to make — every verdict names the layer an enable came from,
*"so an enable arriving from outside the repo is diagnosable instead of mysterious"* — in the one line
where the layer **is** the whole answer. The data was already there (`Layers[].HasKey`); what was
missing was a ready-made phrasing. So `Get-EnabledPlugins` gained `KeyIn` + `KeySummary` — a second
`Summary`, for exactly the reason the first one exists — rather than a filter re-typed at the call site.
The line above it (`-- checked <Summary>`) is unchanged and stays correct: that one *is* a claim about
what was inspected.

`Format-LabelList` was extracted while doing it, since two hand-rolled joins producing "almost the same
sentence" is the shape that made #294 and #304 possible to begin with.

## Tests

**+40 assertions**, all measured against the real shapes rather than invented ones:

- `check-report-lib.tests.ps1` — `KeyIn`/`KeySummary` against **life-hub's exact fixture** (one layer
  with the key as an empty object, two without), including an assertion that `Summary` and `KeySummary`
  are *different sentences*; `Get-InstallRecord` across path match, another path, duplicate disagreeing
  records, pathless records, a vanished `projectPath`, an unparseable administration and four
  valid-but-crashable shapes; `Format-LabelList` and `Get-JsonField`.
- `roster-sync.tests.ps1` — scenario **10b** end-to-end: the marker fires for a record pointing
  elsewhere, is silent when the record is for this path, is silent for a pathless record, says *"could
  not check"* when there is no administration, says nothing at all when nothing is enabled, and travels
  with a real drift report. Plus hook cases **H10–H10d**.
- `connectors.tests.ps1` — **8e/8f**: the sharpened wording when the plugin is enabled there, and the
  milder wording kept when it is not.

**One test-harness defect found and fixed while writing these.** The roster-sync suite's fixtures are
temp directories, which never have an install record — so the new marker fired on *every* case, and an
assertion on it would have proved nothing: it would have been there whatever the code did. `Invoke-Ps`
now pins `$env:USERPROFILE` to a throwaway profile, exactly as it already pins the settings chain's user
layer via `-UserHomeOverride` and for the same recorded reason. Cases that care build an administration
with `New-FixtureAdmin`.

**And one design correction, caught by the suite rather than by reasoning.** The per-plugin detail lines
started as counting `[INFO]`s, which added a permanent info signal to every fixture run and broke five
existing assertions — two of them guarding a *zero-signal baseline* ("a migrated repo reports completely
clean"). Papering over those would have cost exactly what they protect, and #302 had asked for a verdict
that is neither an error nor a counting signal. They are non-counting now; the baseline still means
something.

## Verified

- All 18 suites green (`0 failing`), lint gate `0 error(s)`.
- `check-roster-sync` in this repo: unchanged, `0 error(s), 0 info signal(s)` — this repo does have its
  project record, so the marker correctly stays silent.
- The marker fires against a purpose-built record-less fixture, and the `[INFO]` reads
  *"'enabledPlugins' is present in user ~/.claude/settings.json"* — one layer — against life-hub's shape.
- `bootstrap.ps1` run both ways: the notice with a copy-ready command in the record-less consumer,
  completely silent in this repo.
- `check-connectors` live: `smartwatchbanden` gets the **milder** wording (not enabled there either),
  which is the branch 8f pins.
