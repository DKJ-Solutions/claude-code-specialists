## `fix/enabled-vs-installed-verdict` changelog

### Branch title

The gates report an enabled plugin that is installed nowhere

### Branch ID

20260809-103822

### Branch type

fix

### What does the change on this branch bring to main?

A plugin that is **enabled** for a repo but has **no install record** for that path now says so at
session start, in the repo it concerns. Until today that state was reported by nothing: a session
loaded none of that plugin — no skills, no subagents, no hooks — while every visible signal said the
plugin was present.

`check-connectors.ps1` already knew. It emits the fact as an `[INFO]`, and the reason for keeping it
one is sound where it applies: for a consumer the check is merely walking, the install may legitimately
belong to another machine, so the state is not conclusive. **That second reading does not exist for the
repo the session is running in** — the session is in that checkout, so a missing record means a missing
install. So the check now adds a non-counting `[NOT-INSTALLED-HERE]` marker there, and
`connector-sessioncheck.ps1` surfaces it. Same `Test-IsSessionRepo` scoping as `[INVENTORY]` and
`[UNREGISTERED]`, for the same reason: promoting the line for *every* connector would put another
machine's business back into every session start, which is exactly what the `[INFO]`-silence rule
removed.

**Why nothing caught it, which is the part worth keeping.** Two artefacts could have spoken and neither
could:

- `check-roster-sync` has a marker of the same name for exactly this state, and its own docstring
  already records that it is unreachable at session start **by design** — a session start writes the
  install record itself before any hook can look;
- `check-connectors` covers it from the source side, as the `[INFO]` the hook suppresses.

Each decision is defensible alone. Together they left the state with no reporter at all.

**The measured instance** ([#533](https://github.com/DaveKJohn/claude-code-specialists/issues/533),
August 9, 2026). A mid-session `git pull` carried this repo across the plugin rename:
`.claude/settings.json`, the connector register and the plugin tree all moved to the new names in one
fast-forward, while `installed_plugins.json` kept the pre-rename record. Both enabled plugins were left
without an install record, so the repo ran with none of its own specialist surface — while the one
plugin line in the session context reported a version gap on a plugin that was no longer enabled. It
was found by hand, hours later.

The marker is **non-counting**: nothing is wrong with the source, only with what this machine has of
it, so the exit code stays 0 and the per-signal `[INFO]` stays suppressed. In the hook it takes the
headline when it fires — a session running without the surface it thinks it has outranks a register
finding about a repo that otherwise works — and the register notices are printed beside it rather than
swallowed by the branch that won.

### Significance

#### Tier 0

The state it reports had already happened here, undetected, on the day the marker was written: two
enabled plugins with no install record, a repo running on none of its own specialist definitions, and
every visible signal saying otherwise. Finding that by hand cost most of a session; the gate now names
it and the fix in one line.

**Score:** 4

#### Tier 1

The same failure is at its most likely in exactly the situation this project is worked in — more than
one device, so a pull that moves settings, register and plugin tree while the machine's install records
stay put is routine rather than exotic. What a colleague gets is the guarantee that a session which is
silently missing its specialists says so at the start instead of behaving oddly for an hour.

**Score:** 3

#### Tier 2

Consumers receive the hook half through a plugin update and the check half through the maintainer's
checkout, so the marker fires in a consuming repo on the same terms. It is worth less to them than to
this repo only because a consumer's plugin set moves less often — when it does move, the consequence is
identical: an enabled plugin that loads nothing, previously reported by no one.

**Score:** 2

### Pull Request

