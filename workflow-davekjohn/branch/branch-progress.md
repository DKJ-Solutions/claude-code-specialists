## `fix/client-store-data-out-of-the-plugin` progress

### Steps

- [x] Measure the real extent instead of taking the report's list: two more brand names sit one item
      below the ones #669 named; the manuals and skills are already clean
- [x] Rewrite the pre-push checklist item to state the rule and point at the repo lens
- [x] Rewrite the ownership item the same way, and add the principle its examples were implying
      (do not read a prefix as ownership in either direction)
- [x] Measure a candidate gate before proposing it -- 1 finding, false (a GitHub comment id in a URL),
      0 subjects after this change -- and record the decline rather than build it
- [x] Verify nothing is left: no store name, no brand, no id
- [x] Lint gate green
- [x] All test suites green

### Where I left off

C4's first half done, on Dave's decision. What remains of #669 all lands on the open design question
in section E, which Dave has asked for a decision note on before deciding: **B1** (Chris never loads
without a repo -- the only alternative route, the root `agent` key, is already verified and declined in
#215), **C3** (the vocabulary, i.e. bilingual agent defs) and **C4's second half** (the two hygiene
proposals contradict each other: 89 bare issue numbers a consumer cannot resolve, versus 140
references to a personal repo -- resolving the first means adding to the second).

Next deliverable: that decision note on E. Rebecca establishes what a Cowork-native package concretely
costs, Marlowe red-teams #669's own recommendation.

