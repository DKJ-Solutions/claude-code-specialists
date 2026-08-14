## `fix/a-missing-lens-is-not-a-gap` progress

### Steps

- [x] Verify C1 still stands, and measure both halves: 53 lens pointers, 30 from one shared block and
      23 per-file; `of the consuming repo` is byte-identical in all 26 defs
- [x] Write `agent-shared/lens-optional.md`
- [x] Insert the sentinel pair into all 26 agent defs by script, keyed on the measured anchor
      (`filecontent-boundary` is the first block in 26 of 26) rather than on a line number
- [x] Qualify the per-file pointer with "if it has one", by script, 26 files / 26 occurrences
- [x] Settle the carrier scope -- no persona, because a persona is loaded through the repo's own
      `CLAUDE.md` and can never be in the state the block answers -- and record it in the README
      beside `filecontent-boundary`'s mirror-image reasoning
- [x] Tests: pin the coverage in BOTH directions, plus the per-file pointer; prove the pointer assert
      goes red on the pre-change wording
- [x] Lint gate green (incl. mojibake over 226 files, since two scripts rewrote UTF-8 content)
- [x] All test suites green

### Where I left off

C1 done. Remaining from #669 in Dave's order (E stays open): C4's hygiene half -- 165 `DaveKJohn/`
references, ~100 issue numbers in shipped skill pages, `author.name` in six `plugin.json` files.
**C4's first half is with Dave and unanswered**: `Shopmonkey MAIN` and live theme id `170064871700` in
two shipped team-shopify agent defs, in a public repo. Not a credential, but identifiable client data.
B1 and C3 sit closest to E's open design question and are reported rather than built.

