## `fix/smartwatchbanden-is-gemigreerd` progress

### Steps

- [x] Measure the consumer's end state after its own PR merged: enabled ids, lens inventory, remote
- [x] Map the 25 lenses onto the four plugins from the plugin source, rather than guessing the split
- [x] Rewrite `connectors/smartwatchbanden.json`: new ids, `team-ecomm` added, real org slug
- [x] Keep the two standing lessons in `notes` and record what today's migration measured
- [x] Verify with `check-connectors.ps1` — all four blocks `[OK]`, 0 errors
- [~] Do not touch `connectors/life-hub.json`: that consumer has not migrated, so its two `[INFO]`
      signals are correct as they stand and the register must keep recording what it HAS

### Where I left off

Done. The three inbound issues the migration produced (#555, #556, #557) are verified as still
standing and are deliberately not part of this branch — they are product changes, this is bookkeeping.

