## `feat/lint-skip-checks` progress

### Steps

- [x] Time every suite serially, to find what actually bounds the parallel gate
- [x] Instrument the slowest suite: 98% of it is inside 110 child lint runs, not in its asserts
- [x] Profile one lint run over the fixture — `agent-def`, `parse`, `branch-template` are half of it
- [~] `-Only <check>` on the lint — dropped: 26 wrapping points inside the gate that guards every PR,
      for the same win three points buy. Available later if it is ever worth it
- [~] Batch the 110 runs into fewer — dropped for the same reason: the risk lands on absence asserts,
      which fail silently rather than loudly
- [x] `-SkipCheck` with an unknown name refused at exit 2, and no coverage line for a skipped check
- [x] Wire the suite up and find every scenario that needs `-Full` — one was missed and caught by its
      own message assert while its exit-code assert passed vacuously
- [x] Guard tests: the skip announces itself, a typo is refused, and no production caller passes it
- [x] Re-profile what is left, so the next reader does not repeat the measurement

### Where I left off
