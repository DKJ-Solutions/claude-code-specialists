## `docs/gate-record-second-firing` progress

### Steps

#### PLAN

- [x] Confirm the second firing actually fired before writing it down — both skip lines present in
      `ship-pr`'s own output for #735.

#### CREATE

- [x] Correct the "only #734 is confirmed" sentence in the section merged by #735.
- [x] Add the second-firing subsection: the 198.6s gated `open-pr`, the skipped `ship-pr`, the 15s
      merge gap.
- [x] Fold in the two suite readings that firing produced (168s, 183s) — band now n=12, median ~172s.
- [x] Record the HEAD-hashing constraint that forces the choice between committing a reading and
      keeping the evidence valid, so the next person meets it as documentation rather than as a surprise.
- [x] State what two firings do NOT establish, rather than leaving the gaps to be read as a distribution.

#### TEST

### Where I left off

Records PR #735 as the second confirmed firing (gates 198.6s in open-pr, both skipped in ship-pr, merge 15s after CI green) and folds in the two suite readings that firing produced.

