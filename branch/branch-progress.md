## `fix/adopt-config-plugin-root` progress

### Steps

- [x] Measure the defect's reach: 1 file, 2 lines, sole outlier among 11 shipped skill pages
- [x] Repair both commands to `${CLAUDE_PLUGIN_ROOT}`, plus a line saying where that form resolves
- [x] Choose the gate's rule by measuring candidates -- the tree-wide path rule is born red, the
      command rule is born green with zero exemptions
- [x] Add lint check 22 and prove it fires: reintroduce the exact defect, confirm the finding, revert
- [x] Catch the docstring's check list up (19, 20, 21 were never listed; 22 joins them)
- [x] Six asserts, including the POSIX path and the deliberate `<plugin>` pass
- [~] Repair the teardown page's three `<plugin>/...` commands -- dropped on purpose: a consistency
      question, not this defect, and recorded in the entry for its own branch

### Where I left off

Lint green (26 commands examined, 0 findings), suite green at 176 asserts. Ready for the PR.
