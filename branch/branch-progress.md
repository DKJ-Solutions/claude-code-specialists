## `feat/one-script-per-concept` progress

### Steps

- [x] Splice the file writing into `new-branch.ps1`, answering each of the three `exit` points
- [x] Move the trunk refusal in front of the checkout -- keep it, it is not dead code for a `master` trunk
- [x] Drop the env-var handoff: no process boundary left to requote across
- [x] Remove the script and its mirror; retire it from the shared-scripts registry
- [x] Retarget the script contract -- rename four seams to `new-branch`, DROP two it no longer reads
- [x] Rework both test suites that drove the inner script; retire the env-precedence scenario
- [x] Sweep 24 documents for the old name, then fix the paths the sweep got wrong
- [x] Retire the `chore/` prefix -- refused in `Test-BranchName`, `Chore` kept as a recognised type
- [x] Name the merge commit `merge: PR #NN <branch>`, so every line in the graph states its type
- [x] Record why the release stays off a PR, in Dave's words, with the coverage gap named beside it
- [x] Full suite green (26 suites, 0 failures), PR, merge, fold

### Where I left off

Lint clean, `new-branch` 93 asserts and `entry-scaffold` 282 asserts green. Full suite running.

**Two things the gates caught that I would not have.** The bulk rename turned
`scripts/release/new-changelog-entry.ps1` into `scripts/release/new-branch.ps1` -- a path that does not
exist, since the merged script lives in `scripts/task/`. The dead-link check found it. And a comment in
`shared-scripts.tests.ps1` came out reading "new-branch and new-branch", which no check would have caught;
found by grepping for the shapes a blind replacement produces.

**Two seams were dropped rather than renamed**, which is the part worth not getting wrong:
`Get-EntryTitlePlaceholder` and `Get-EntryBodyPlaceholder` are no longer read by the writer at all -- only
`open-pr`'s gate still reads them. Renaming them to `new-branch` would have declared a dependency that does
not exist.

Still open, unchanged: Tessa's proposal on the duplicated form description, with Marlowe's three
objections unanswered. And Dave's question about PR #503's Tier 0.
