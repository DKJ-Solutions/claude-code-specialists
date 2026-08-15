## `feat/quieter-signals-and-a-derived-pin` changelog

### Branch title

The connector check reports per consumer, three exact pins become floors, and a cut names its own refresh

### Branch ID

20260815-231737

### Branch type

feat

### What does the change on this branch bring to main?

Three signals from the review of August 15, 2026 that were each costing something small on every run.

**The connector session check reported per plugin, so one consumer behind on four plugins printed the
same sentence four times.** Measured at a session start that day: six `[ERROR]` lines, 1,511
characters — **81% of everything the five session hooks printed together**, and paid again on every
compaction, because this hook's matcher includes `compact`. The lines now fold per consumer: on the
real signal set, four lines of 733 characters became one of 311, a **58%** cut.

**What is deliberately not lost is attribution.** Inbound #203 was filed precisely because two
consumers on the same outdated version produced two identical, unattributable lines, and the repair
then was to name the connector on every line. This groups rather than summarises — every plugin name
still appears, moved beside its consumer — so "which plugins, in which repo" is still answerable. The
fold is conservative by construction: marker, consumer **and** message must match, so two different
problems can never read as one, and anything that does not parse as the per-plugin shape passes
through untouched, which is what keeps the drift check's own lines whole. Seven asserts pin exactly
that, including one that a differing message is never folded in.

**Three exact counts in `script-contract.tests.ps1` became floors.** The record-count literal had been
hand-edited **21 times** — 6, 7, 8, 12, 14, 19, 22, 25, 27, 29 — because it tracks a registry that
grows with ordinary feature work. A test that must be "fixed" on nearly every change teaches people to
write the assertion to match the code, which is the opposite of what an assertion is for.

**The issue asked for the number to be *derived*, and that was measured and declined**: the count is
already parsed from the registry, so deriving it further would compare the source against itself and
stop catching the one thing the pin genuinely buys — a record silently disappearing. A floor keeps
that (a removal still drops below it) and costs nothing when one is added. The gap is stated rather
than hidden: adding and removing in the same change can net out above the floor. That is narrow, and
it is the price of removing 21 edits.

**A cut now tells a repo that runs what it releases that its own install is behind.** The loop had a
missing return edge: a release commits straight to the trunk, so no PR and no CI follow, the plugin
cache keeps its old version, and the only thing that notices is a later session's connector check —
as an `[ERROR]` that reads like a fault rather than the ordinary consequence of having just cut. On
August 15 this repo sat on v4.9.0 against a v4.11.0 source with six rows red, and a hook that release
had *added* could not fire, because the cache predated it. The reminder prints the two commands, and
prints **only** when this repo enables a plugin from the marketplace it declares — a repo releasing a
product it does not itself run gets nothing. It reminds rather than acts: a plugin update rewrites
what every future session loads, which is not something a release script should do while your
attention is on the tag.

### Significance

#### Tier 0

The hook cost is paid at every session start and every compaction, by everyone. The pins were a tax on
almost every contract change. The cut reminder closes a loop that left this repo silently behind
itself twice in one day.

**Score:** 3

#### Tier 2

Two of the three ship. A consumer's session start gets materially shorter when they are behind on
several plugins at once — which is the normal case after a release, since the bump is in lockstep —
and their `cut-release` gains the same reminder under the same condition. Scored 3: it is the first of
these three that a consumer notices without being told.

**Score:** 3

### Pull Request

