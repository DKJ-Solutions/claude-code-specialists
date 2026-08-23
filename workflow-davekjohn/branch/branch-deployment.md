## `feat/worktree-lane` deployment

### What does the change on this branch deploy to main?

A new shared script, `worktree-lane.ps1`, opens a branch in its own git worktree -- a "lane" -- so one
branch can be **built** while another one **ships**, and hands the lane's branch back to the primary
checkout when it is ready. It is the answer to a measured cost: `ship-pr.ps1` blocks on
`gh pr checks --watch`, whose median is **8m 01s** over the 65 most recent blocking CI runs, and at 73
merged PRs in seven days that is **9h 45m per week** in which the session that opened the PR can do
nothing else. Lanes convert that from blocking to non-blocking without touching a gate and without
proving any less.

The direction matters and is the opposite of the obvious one: **the worktree is where you build, the
primary checkout is where you ship.** Shipping from a worktree cannot work -- git refuses one branch in
two worktrees, and that refusal lands *after* the merge, in the one gap where the PR is merged, the entry
is unfolded, and every gate stays green until a release trips over it.

`new-branch.ps1` gains a `-RepoRoot` parameter, on the precedent `fold-changelog-entry.ps1` has carried
since #101, so a lane's branch and both of its branch-dossier files come into being inside the lane
rather than in the primary. A new 35-assert suite covers both ends, including the guarantee that opening
a lane never moves the primary's HEAD -- the one property whose failure would break the thing the script
exists to protect.

**Score:** 4

#### What makes this change extra special

Three of the findings in it came from running the thing rather than from reading it, and two of them
contradicted the plan they were testing. The first design pointed `CLAUDE_PROJECT_DIR` at the lane, which
the source-repo guard refused -- correctly, because that variable answers *which repo the session is on*
and not *which tree this call writes to*; that is what produced the `-RepoRoot` parameter instead of a
workaround. The first hand-back then failed with `Permission denied`, because on Windows the process's own
working directory holds the lane open, and standing in the lane is the normal case rather than an edge
one. And the message that failure printed -- "nothing was changed" -- turned out to be **false**: git had
already emptied the tree and deregistered the worktree, so `git worktree remove` is not atomic and the
script now asks git what it thinks instead of inferring from an exit code.

The alternative repair is recorded as declined rather than unconsidered: a one-line change to
`ship-pr.ps1` would remove the two commands a hand-back costs, and was measured as saving nothing in
wall-clock while changing the single line that produces the state nothing reports.

**Score:** 3

### Pull Request

A branch can be built in its own worktree while another ships
