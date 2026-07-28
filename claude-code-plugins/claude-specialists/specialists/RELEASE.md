# Release v2.10.0

**Date:** 2026-07-28  
**Type:** Minor

An unregistered consumer no longer reads as 'no errors', plus the register handover in specialists-init

You are on this release.

## Fixes

### #208 · An unregistered consumer is visible at session start · Fix · 2026-07-28

Found by Dave: the `specialists` plugin had been installed on a third repo (`djcylow-react`) and it
never appeared in the connectors register. Reproduced against a throwaway clean consumer, and the
result was worse than a missing entry — it was a false all-clear:

```
check-connectors:        [INFO]  not registered: no manifest for this consumer in the register.
connector-sessioncheck:  no errors.
```

The check *knew*. The hook suppresses `[INFO]` (Dave's July 20, 2026 decision), so what a brand-new
consumer actually saw was a positive verdict for a repo this workshop cannot see at all: no
plugin-version check, no lens-inventory check, no agent-def drift check. `djcylow-react` had been
filing inbound issues since July 26 in that state.

**Two gaps, and they compounded.**

**Gap A — nothing pointed towards registration.** `specialists-init` contained no mention of the
register at all (`connector|register|manifest`: zero hits), and it structurally cannot create the
manifest: the register lives in the workshop, the bootstrap runs in the consumer, and the register's
doctrine is explicit that it never writes cross-repo. So it now closes the loop from the other side —
after bootstrapping it prints a **paste-ready manifest block**: repo name derived from the git remote,
lens inventory per plugin, and `visibility`/`localCheckout` left as `VUL-IN` because it genuinely
cannot know them (it has no idea where the workshop checkout sits relative to the consumer, and a
guessed path is exactly what the register's marker check exists to prevent). Printed, never written.

The inventory deliberately covers **both** lens kinds. Collecting only the agents would hand over a
manifest that under-reports the repo by exactly its persona-only specialists — the same class of bug
inbound #204 was about, one layer along.

**Gap B — the "unregistered" signal could not reach a session.** `check-connectors.ps1` now also emits
a non-counting **`[UNREGISTERED]`** line that the hook surfaces, *next to* the no-errors verdict rather
than under it: nothing is wrong with the plugin install in that repo, only with this workshop's view of
it, so the exit code stays 0 and the per-signal `[INFO]` stays suppressed. The `[INFO]` itself remains
for the count and the deliberate run.

Deliberately **not** promoted to `[ERROR]`, which would make the exit code 1 and put a red line in
every session of a repo somebody chose not to register. The mechanism is the one `check-roster-sync`
already uses for `[ORPHANS]` (inbound #204) — a dedicated non-counting token — applied a second time,
which is what makes it a pattern rather than a one-off.

**This is not a relaxation of the `[INFO]`-silence rule.** That rule was justified as *"often the
business of another machine or user"*; this signal is its opposite — about the repo the session is in,
actionable there. The connectors README's own classification rule already pointed the same way: a
category that must not stay out of sight may not be filed as `[INFO]`. Recorded there as a named
exception, so the next extension of the check has a precedent to reason from instead of a
contradiction.

**Someone got halfway here before.** `connectors.tests.ps1` case 5c carries the comment *"regression:
this used to be a bare Write-Host that did not count as an info signal, causing the hook to show 'all
connectors in sync'"* — the false reassurance was spotted once and half-fixed: made countable, so a
deliberate run reports it, while the hook kept hiding it. The remaining half is this change.

Not resolved here: registering `djcylow-react` itself. Its checkout is not on this machine, so its
plugin set and lens inventory cannot be read — that manifest needs a session on the machine where the
repo lives, or the data by hand.

[PR #208](https://github.com/DaveKJohn/davekjohns-workshop/pull/208)

---

Full workshop notes: [releases/development/2.x/2.10.0.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/2.x/2.10.0.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
