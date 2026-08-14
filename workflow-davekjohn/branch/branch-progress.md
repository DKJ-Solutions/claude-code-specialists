## `fix/skills-cannot-self-trigger` progress

### Steps

- [x] Verify B2 still stands against the tree, symptom and reasoning separately -- the three skills do
      lack the flag; the "only start-task has it" fact has expired (9 of 16 carry it now)
- [x] Verify the proposed repair names something that exists: `disable-model-invocation` is a real key
      already used by nine shipped skills
- [x] `disable-model-invocation: true` on the three team-alpha skills
- [x] A PowerShell-presence check at the FRONT of each of the three, each with its own consequence
- [x] Lint gate green
- [x] All test suites green
- [~] Extend the flag to the four other model-invocable `.ps1` wrappers -- dropped: #669 did not
      measure them, and `new-branch` is one a model may legitimately reach for inside a repo. That is
      a workflow decision, not this repair.

### Where I left off

B2 done. Remaining from #669, in the order Dave set (E stays open, so nothing bilingual is built):
C2 (the `GENERATED` pointer resolves to nothing for a consumer), C1 (every agent looks for a lens that
is not there), C4 (what travels along to a wider audience), and B1 (Chris never loads without a repo)
-- B1 and C3 sit closest to E's territory and are reported rather than assumed.

