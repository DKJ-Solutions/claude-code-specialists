## `feat/source-repo-guard` changelog

### Branch title

Refuse a shared script that runs from outside the repo it is maintained in

### Branch ID

20260812-213710

### Branch type

feat

### What does the change on this branch bring to main?

Eleven of the thirteen shared entry points now **stop**, with exit 1, when they are running from a copy
outside the repo being operated on while that repo holds its own copy of the same script — and they name
the local path to run instead. That is the mechanism behind the sentence added to the skill pages earlier
today: the prose told a reader which copy to run, and this makes running the wrong one impossible rather
than merely documented.

**The test is not "am I in the plugin cache".** It is: *does the repo being operated on hold its own copy
of the script now running?* Three conditions, all required — the running script sits outside the repo root;
the repo has a `.claude-plugin/marketplace.json`, so it publishes plugins at all; and the local copy exists
at the same path below `scripts/`. That phrasing needs no knowledge of where a harness puts its caches,
survives one moving, and answers itself correctly for a consumer, who has no such copy and is therefore
never refused.

**A refusal rather than a warning, because all three measured instances were silent** — a changelog entry
scaffolded in a retired shape, a status report with one section quietly empty, and a third produced by the
session that wrote this. A warning can be read past, and those are exactly the results that look finished.

**Two entry points deliberately do NOT carry it, and the gap is stated rather than left quiet.**
`check-roster-sync.ps1` and `check-script-contract.ps1` are invoked by both SessionStart hooks from
`${CLAUDE_PLUGIN_ROOT}/scripts/sync/`, by design, against the current repo — so a refusal there would fail
**every session start in this repo**. Measured before choosing the scope rather than discovered afterwards.
Closing that needs the hooks to pass an explicit bypass, which is more surface than the defect warrants
today.

**The lib had to travel with the mirror, and that is the whole reason it is a registered pair**: the guard
fires from inside the copy a reader wrongly ran, so one that stayed behind in the source tree could never
fire at all. Every entry point dot-sources it `$PSScriptRoot`-relative **and guarded**, so a mirror built
before this pair existed degrades to the previous behaviour instead of throwing.

**Three claims that this change made false were repaired rather than left standing.** `session-status`, the
`lock` page and the `continue` page each promised the script "dot-sources no library"; it now loads exactly
one, optionally. The property that actually mattered is unchanged and is what they say instead: no library
and no seam function is needed to *produce the answer*, so a repo that has adopted none of this workflow
still gets a full report.

Thirteen asserts, and the allow cases are the ones carrying the risk: a consumer with no marketplace, a
consumer holding a same-named script of their own, a publishing repo without this particular script, and
the source repo's own in-repo mirror — which lint check 8 holds byte-identical, so running it is not the
staleness this guard is about. One integration case runs a real entry point from a copy outside a real repo
and asserts it exits 1 **before** doing any of its work; without it, a lib returning the right answer to
nobody would pass. That case also documents a trap it fell into: `-match 'REFUSED'` passed against a run
that never fired, because `session-status` prints the lock file and its prose is full of the word
"refuses". It is `-cmatch` now.

### Significance

#### Tier 0

The failure it prevents happened three times in one day, on the commands that start a piece of work, and
every instance was silent — one of them corrupted a working file. A sentence in a document relies on the
reader having read it; this does not. It also names its own remedy, so the correction costs one line rather
than a search.

**Score:** 4

#### Tier 2

By construction the guard never fires for an ordinary consumer — that is the condition it is built around,
and four of the thirteen asserts exist to keep it that way. What it buys them is the case where this system
is copied: a consumer who publishes plugins of their own inherits the identical trap, and now inherits the
guard with it. The two skill pages also stop making a promise about the script that is no longer true.

**Score:** 2

### Pull Request

