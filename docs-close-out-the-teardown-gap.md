### The teardown gap is closed · Docs · 2026-07-30

The paperwork on [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221), Dave's July 29
requirement that a consumer must be able to install and uninstall at any moment and afterwards *stand
fully free*.

**Every item of the target shape now carries its own *Settled on* marker.** Five already did; the seam
itself — the first and largest item — did not, which is the sort of gap that makes a finished list read as
an open one. It was settled on July 29 ([#253](https://github.com/DaveKJohn/davekjohns-workshop/pull/253)
specified it, [#254](https://github.com/DaveKJohn/davekjohns-workshop/pull/254) taught both writers, and
[#255](https://github.com/DaveKJohn/davekjohns-workshop/pull/255) migrated this repo onto it as the first
consumer), with the marker now recording that **its paperwork lagged a day behind its machinery**:
[#261](https://github.com/DaveKJohn/davekjohns-workshop/pull/261) for the 120 stale path references and
[#262](https://github.com/DaveKJohn/davekjohns-workshop/pull/262) for `sync-roster` still *writing* to the
old location. That is the useful part to remember, not the completion.

**The section is kept in full rather than trimmed to a verdict, and the status block says why.** The
measurements are the reason the design took the shape it did: 26 orphaned lens files, an `@`-import that
actively broke, 101 specialist mentions across 492 lines, and a resolver that took the consumer's daily
git workflow down with it. A conclusion is easy to argue with; the numbers are not. A future change that
finds this shape inconvenient should have to argue with those.

**What stays open, deliberately.** [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) —
delivering Chris from the plugin's own `settings.json`. The mechanism is verified, the blocker (his body
being unusable as a main-thread system prompt) was removed, and the switch is still off for two reasons
that no further work here changes: it would alter every consumer's main loop from a version bump they did
not read, and a second `agent`-setting plugin silently wins on load order. Dave's call, on a measured fact
rather than an unknown.
