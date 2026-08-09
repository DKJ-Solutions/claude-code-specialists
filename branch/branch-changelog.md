## `fix/smartwatchbanden-is-gemigreerd` changelog

### Branch title

The connector register records smartwatchbanden's migrated plugin ids and its real org

### Branch ID

20260809-215340

### Branch type

fix

### What does the change on this branch bring to main?

`connectors/smartwatchbanden.json` now records what that consumer actually has. It migrated to the
`team-*` ids on August 9, 2026 — the three retired ids out, `team-alpha`, `team-shopify` and
`team-ecomm` in, plus `workflow-davekjohn`, which it had never had — and the register still named the
retired ones, so `check-connectors.ps1` reported it as unmigrated four times over.

Three things were measured while updating it, and only one of them is the migration:

- **The `repo` field named the wrong organisation.** It said `davekokbwj/smartwatchbanden`; the real
  remote is `BWJ-ecommerce/smartwatchbanden`, private. That drift is older than today's migration and
  no check can see it, because nothing here resolves the slug against GitHub — the checks all run
  against `localCheckout`, which was correct and is unchanged (the local folder genuinely is
  `davekokbwj/`). Worth knowing rather than repairing in code: a slug that is only ever read by a human
  is exactly the field that goes stale in silence.
- **`team-ecomm` had never been registered at all.** It was enabled in that consumer's
  `settings.json` well before today, so its three extensions are an addition, not a rename — the
  migration is what made anyone look.
- **`workflow-davekjohn` ships no `agents/`**, so its extension list is deliberately `[]`. An empty
  array is the measured answer; leaving the plugin out entirely would have said the consumer does not
  have it.

Verified after the edit rather than assumed: all four plugin blocks report `[OK]` on every line —
19 + 3 + 3 + 0 registered extensions present, each on source version v4.0.0. The register was updated
only after the consumer's own PR had merged, per its own rule that it records what a consumer **has**;
writing it earlier would have made the register itself the false alarm.

### Significance

#### Tier 0

`check-connectors.ps1` stops reporting a migrated consumer as unmigrated. Four `[INFO]` signals that
were correct yesterday became noise the moment that consumer moved, and noise in a check is how a
check gets ignored — the register is the only thing this repo has that says what consumers run.

**Score:** 3

#### Tier 1

Nobody but this repo's own developers reads the connector register; it is maintenance bookkeeping for
the source repo and is not shipped to anyone.

**Score:** N/A

#### Tier 2

A consumer never sees this file. Their own migration landed in their repo and is already merged there.

**Score:** N/A

### Pull Request

