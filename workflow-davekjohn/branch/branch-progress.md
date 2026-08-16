## `docs/gate-record-measured` progress

### Steps

#### PLAN

- [x] Verify the locked topic against the repo before acting — lock and repo agreed on every block
      (`7c200a8`, clean, zero open issues, three pending entries).
- [x] Confirm the mechanisms the lock names actually exist — `Get-GateFingerprint` in
      `scripts/lib/gate-lib.ps1`, and the wall-clock section in Nolan's lens.

#### CREATE

- [x] Measure what `ship-pr` would have paid: lint gate n=3, test gate n=6 at 43 suites.
- [x] Measure what it paid instead: one fingerprint + one evidence read per gate, n=10.
- [x] Read PR #734's own timeline from `gh` — evidence stamp, PR creation, CI green, merge.
- [x] Recount the historical merge-lag distribution instead of quoting the docstring's figure.
- [x] Write the section into `.claude/specialists/lenses/06-25-extension.md`, beside the existing
      wall-clock section.
- [x] Correct the summary table above it: 40 → 43 suites, and a real number on the lint row.
- [~] Re-run the suites a seventh-plus time to narrow the 139.7–195.0s band — dropped: the band IS the
      finding, and every second of it is saved either way, so a tighter figure changes no conclusion.

#### TEST

- [x] Hold the machine idle for every timed run — no concurrent tool calls, after `#714`'s lesson that a
      stopwatch reading taken on a busy machine came out 40% high.
- [x] Six suite runs green (`green=True` on every one), so the timings are of a passing gate.
- [x] Check the trend for accumulation rather than assuming noise — run 4 dipped after run 3, so not
      monotonic and not accumulating temp state.

### Where I left off

Measurement and write-up complete. Remaining is the ordinary chain: `open-pr` (which runs the lint and
test gates itself), CI, merge, fold.

Note for whoever picks this up: the suites clear the gate-evidence record as part of their own fixtures,
and the record on disk was in any case stamped against `9838faf` while HEAD has moved — so `open-pr` will
run both gates for real here rather than skipping them. That is correct behaviour, not a regression, and
it is the mechanism this branch documents working as designed.

