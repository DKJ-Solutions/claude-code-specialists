## `fix/shared-block-coverage` progress

### Steps

#### PLAN

- [x] Measure coverage per plugin before touching anything: 15/15, 0/3, 0/5, 0/3
- [x] Read each of the eleven in context first — eight turned out to share a bullet with role-specific
      text, which a blind sentinel wrap would have handed to the generator to delete

#### CREATE

- [x] `#699` — wrap the canonical block into all eleven, splitting the merged bullets so role-specific
      text stays outside the generated region
- [x] Preserve `03-08`'s "which period, which account" as its own bullet rather than dropping it
- [x] Run `build-agent-defs.ps1`: 0 files updated, which proves all eleven match the source exactly
- [x] Verify no hand-typed variant survives anywhere (0 hits)
- [~] `#700` — the final-message closer: NOT done here, and the issue is being corrected instead.
      Re-measured precisely, only **3** of the 20 defs carry the exactly-generic sentence; the other 17
      have role-specific tails. That is the stem-with-slot family, which needs templated shared blocks
      that do not exist yet — a design job, not this mechanical one, and three files do not earn a
      shared block

#### TEST

- [x] `build-agent-defs.ps1` reports 0 files updated -- the eleven match the source byte for byte
- [x] Coverage re-counted per plugin: 15/15, 3/3, 5/5, 3/3
- [x] `check-plugin-integrity.ps1` green, shared-block check over all 30 blocks included
- [x] full test suite green

### Where I left off

