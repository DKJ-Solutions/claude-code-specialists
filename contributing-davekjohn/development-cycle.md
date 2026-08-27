## Development cycle: `fix/ship-step5-leaves-head-alone-v1` · 20260827-175719

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

ship-pr step 5 runs git checkout main unconditionally after the merge. Read HEAD first: still on the shipping branch or on main, nothing changes; moved elsewhere, fold from a throwaway worktree on main so the session's HEAD and its uncommitted work are never touched. Issue #972.

### CREATE

- [x] `ship-pr.ps1` step 5 reads `HEAD` before it moves anything, and branches the fold tree on the answer
- [x] the throwaway worktree lives outside the repo, and its removal is judged by `git worktree list` rather than by the exit code
- [x] all THREE exit paths take it down -- a failed fetch, a failed ff-only merge, and the fold itself, success or not; the first two were missed in the first draft and caught in review
- [x] the half-state message names the recovery command when the worktree cannot be added at all
- [x] mirror to the plugin copy via `build-shared-scripts.ps1`
- [x] the `ship-pr` skill page records the two measured outcomes and the new behaviour
- [x] `worktree-lane.ps1`'s declined alternative is answered rather than left contradicting this change

#### Also changed, because they now said the opposite

- [x] step 3's printed invitation called the lane a condition; it is advice now, and the comment above it says which part expired

### TEST

- [x] `fold-changelog.tests.ps1` gains the case this change rests on: the real fold script, run from the primary's copy against a `git worktree` on main, with the primary parked on another branch holding an uncommitted edit to a tracked file. Nine asserts, the two load-bearing ones being that the primary's `HEAD` never moved and that its edit survived byte for byte. **148 pass, 0 fail.**
- [x] `-Push` is part of that case rather than decoration: it is what proves the worktree has main properly *checked out*, which is the half the detached alternative could not offer.
- [x] the lint gate: **0 errors** over all 30 checks.
- [x] `internal-note.tests.ps1` -- the suite [#959](https://github.com/DaveKJohn/claude-code-specialists/issues/959) says can fail on console width -- run on its own here: 95/95. No `-SkipTests` was needed.

#### The gap, named rather than papered over

`ship-pr.ps1`'s own step 5 has no automated test, and this branch does not add one. The decision it now makes
is only reachable through a live PR: the script calls `open-pr.ps1` (the full lint + test gate, a push and a
`gh pr create`) and then five more `gh` calls before step 5 runs. A fixture for that would be a fake `gh` on
`PATH` plus a fake CI, which is a larger construction than the six lines it would cover.

What is covered instead is the **mechanism** those six lines choose -- and that is the half that was never
tested: `fold-changelog-entry.ps1`'s `-RepoRoot` has existed since #101 and was exercised only against a plain
directory, never against a git worktree and never with `-Push`. The remaining uncovered surface is the
`if` itself, and the worktree-removal failure arm, which needs an OS-level file lock that cannot be arranged
deterministically -- the same arm `worktree-lane.ps1` leaves untested, for the same reason.

### DEPLOY: `fix/ship-step5-leaves-head-alone-v1`

`ship-pr.ps1` step 5 ran `git checkout main` unconditionally, one line after the merge. Measured on
git 2.54.0.windows.1, that had exactly two outcomes on a backgrounded ship -- the shape the script started
inviting the same day, in #990: an uncommitted edit that **collides** with the trunk makes the checkout exit 1
("Your local changes to the following files would be overwritten"), stopping the run between the merge and the
fold -- PR merged, branch document still in the tree, every gate green until a release trips over it; an edit
that **does not collide** lets it exit 0, and `HEAD` moves to the trunk *with the uncommitted work travelling
along*, so the session carries on editing on `main` with its own work already sitting there.

Step 5 now reads `HEAD` first. Still on the shipping branch, or already on the trunk: it runs exactly what it
ran before, command for command. Anywhere else -- another branch, or detached -- it leaves that checkout alone
and folds in a throwaway `git worktree` on the trunk, then takes it down again.

**Three things were measured rather than reasoned, and each one closed a choice.** The worktree has main
*checked out* rather than being detached, because from a detached `HEAD` the fold's bare `git push` dies with
`fatal: You are not currently on a branch` (exit 128); it is only reachable at all because git refuses that
add when the primary itself holds main, which is why `HEAD -eq 'main'` folds in place instead; and
`fold-changelog-entry.ps1` needed no change, because its `-RepoRoot` has named this exact caller since #101 --
*"a consumer that runs the fold from a temporary/detached worktree (e.g. a ship-pr.ps1 that checks out main
elsewhere)"*.

**The one decline this had to answer is `worktree-lane.ps1`'s**, which says in as many words that changing
this line was weighed and rejected. It was -- for a different thing: folding via whichever worktree *already
holds* main, to spare a lane two hand-back commands, a convenience traded against touching "the single line
that produces the state nothing reports". #972 measured that line producing that state rather than merely
risking it, and this adds a tree of its own instead of borrowing a lane's. Both scripts now say so, so a
reader meeting the older paragraph is not left with a contradiction.

Closes [#972](https://github.com/DaveKJohn/claude-code-specialists/issues/972).

**Score:** 3

#### What makes this deploy extra special

**A backgrounded ship can no longer take your working tree with it.** `ship-pr.ps1` is workflow payload, so
this reaches every repo running `contributing-davekjohn` -- and it lands one release after the change that
made backgrounding the default, which is what turned a latent hazard into a routine one. Nothing about the
ordinary run changes: a foreground ship, and a ship run beside a `worktree-lane`, execute the same commands
they always did and still leave you on the trunk.

**What changes is the cost of forgetting the lane.** It was your uncommitted work, silently, in one of the two
directions git happens to choose; it is now a temporary directory. The lane is still the better move -- it is
where you build, and it keeps one tree doing one thing -- and the skill page now says that as advice rather
than as a condition, with both measured outcomes in a table beside it.

**Score:** 3

#### Pull Request

Step 5 folds without moving the session's checkout
