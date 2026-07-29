### The post-merge sync names one ref · Fix · 2026-07-29

The post-merge sync step said `git pull --ff-only`, in
[Derek's lens](.claude/specialists/lenses/05-05-extension.md) and — the part that matters more — in
[`ship-pr.ps1`](scripts/release/ship-pr.ps1), which automates the whole merge → fold chain. That bare
pull aborted on July 29, 2026 with `fatal: Cannot fast-forward to multiple branches` on a clean `main`
immediately after `gh pr merge --delete-branch` plus a `git fetch --prune` that removed two remote refs.
`git merge --ff-only origin/main` ran straight through.

**Where it aborts is the whole point.** In `ship-pr.ps1` that step sits between the merge and the fold —
the one gap in the chain that nothing reports. The PR is merged, the entry file is still in the root,
every gate stays green, and it surfaces only when a release trips over an entry that should no longer
exist. That is precisely the half-finished state PR #256's own fold was found in earlier the same day.
Both call sites now `git fetch --prune origin` and then merge `origin/main` explicitly.

**The mechanism was deliberately not guessed at.** Git raises that error when it is handed more than one
ref to merge, and why the pull got more than one was not established: the repo's config is ordinary (one
`remote.origin.fetch` refspec, `branch.main.merge` naming a single ref, `pull.rebase=false`), and a later
inspection showed a single `for-merge` line in `FETCH_HEAD`. So this is not recorded as a mechanism note,
and the rule does not rest on one. It rests on determinism: naming `origin/main` explicitly hands git
exactly one ref, so the step cannot reach that failure mode at all, while a bare pull's behaviour depends
on whatever `FETCH_HEAD` happens to contain. For a step wedged between a merge and a fold, the more
predictable command is the right one regardless of what caused the stall.

**Test gap, stated rather than papered over:** `ship-pr.ps1` has no suite. Driving it under test means
standing in for `gh pr merge` against a real remote, and a mock convincing enough to be worth trusting
would be testing the mock. The lint gate's parse check covers the syntax; the changed step is two native
calls whose failure modes are the exit codes already checked inline.
