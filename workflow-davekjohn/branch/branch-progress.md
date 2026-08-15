## `feat/quieter-signals-and-a-derived-pin` progress

### Steps

#### PLAN

- [x] Read inbound #203 before touching the hook output, so the fold could not undo the attribution
      that issue was filed to get
- [x] Measure what the pin actually buys before "deriving" it, which is how the derivation turned out
      to trade away the only property it has

#### CREATE

- [x] `#713` — `Group-ConnectorSignals` in the hook: fold on marker + consumer + message, keep every
      plugin name, pass anything unparseable through untouched
- [x] `#709` — the three exact counts become floors, with the 21-edit history and the known gap
      written in beside them
- [x] `#705` (durable half) — `Write-SelfConsumptionReminder` in `cut-release.ps1`, conditional on this
      repo enabling a plugin from the marketplace it declares, and mirrored to the plugin copy
- [~] Derive the record count as the issue proposed — declined, with the reason recorded in the code:
      it is already parsed from the registry, so deriving further compares the source against itself
      and stops catching a silent removal
- [~] Have the cut RUN the refresh rather than print it — declined: a plugin update rewrites what every
      future session loads, which a release script should not do to you unasked

#### TEST

- [x] `connectors.tests.ps1`: 7 new asserts on the fold, 168 pass / 0 fail
- [x] `script-contract.tests.ps1`: 282 pass / 0 fail with the floors in place
- [x] `cut-release-guardrail.tests.ps1`: 6 new asserts on the reminder, 61 pass / 0 fail
- [x] Measured the real fold on this session own signal set: 733 chars -> 311, all four plugin names kept
- [x] `build-shared-scripts.ps1` ran, so the plugin copy of cut-release matches
- [x] `check-plugin-integrity.ps1` green
- [x] full test suite green

### Where I left off

