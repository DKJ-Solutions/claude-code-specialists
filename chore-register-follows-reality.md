### The connector register catches up with reality, in both repos · Chore · 2026-07-29

The register's own doctrine says the data should follow reality after a refresh. Two inventories had
fallen behind it, and a deliberate run of `check-connectors.ps1 -SkipDrift` reported eleven
`[INFO]` signals to prove it. Both are now at the full 19 specialists, and the run comes back with
none.

- **`smartwatchbanden.json`** — the catch-up that issue #218 was waiting on has landed. Both halves
  of the gap measured on July 28 are in: the script contract reports all eight functions `[OK]`, and
  the five specialists that had neither a roster row nor a lens — `03-02` (Bianca), `06-24` (Ravi),
  `06-25` (Nolan), `06-29` (Marlowe), `06-30` (Auden) — all exist there now. All five were adopted,
  none deliberately skipped, exactly as the "adopting is the default" rule (v2.11.0) intends. The
  `notes` field, which described the gap as open, now records it as closed and verified.
- **`davekjohns-workshop.json`** — the same drift, in the register of the repo that owns the check.
  Six lenses landed with the adopt-the-six change (PR #212) while this inventory was never updated
  alongside: `02-09`, `03-02`, `04-11`, `04-12`, `04-13`, `06-30`.

**The lesson, recorded in the manifest itself:** an inventory drift can sit unnoticed indefinitely,
because "exists in the consumer but is not in the register" is an `[INFO]`, and the session hook
reports only `[ERROR]` lines. Nothing surfaces it at session start — it took a deliberate run to
find. So whoever lands a lens updates that array in the same change, rather than trusting a signal
to remind them later.

Both inventories were verified against the checkouts on this machine, not taken from a consumer's own
report — the same principle the register applies to a measured gap.
