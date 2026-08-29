## Development: `fix/a-backgrounded-ship-ends-on-the-trunk-v1` · 20260829-123853

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

Issue #1073: two rules in Chris's portable body -- "parking is a state, not a promise to come back
within the turn" and "it ends on the trunk, which is what makes the session safe to clear" -- cannot
both hold for a backgrounded `ship-pr`. `HEAD` did not move until step 5, after the CI wait, so at the
moment the close-out was written the tree was necessarily still on the branch. The `ship-pr` skill took
the first side and never named the trunk condition, so the two documents disagreed as well.

#### The candidate that was declined, and why

The issue offered three shapes and left the choice open. **Shipping from a lane so the primary is
already on the trunk is impossible**, and the evidence was already written down: `worktree-lane`'s own
"Why the obvious fix does not work" probed it on git 2.54.0.windows.1 -- git refuses one branch in two
worktrees -- and since #1069 `ship-pr`'s step 0 refuses that arrangement before anything is pushed. The
other two were kept as the fallback and are not what shipped: wording the close-out honestly leaves the
owner exactly where he was, and waiting for step 5 buys the trunk back with the wait #985 removed on
purpose (median 8m01s per blocking run, 9h45m per week).

#### What made a fourth shape available

Two repairs that already landed, read together rather than separately: since #970 both merge gates read
`refs/heads/<branch>` instead of the working copy, and since #972 step 5 reads `HEAD` before it moves
anything. **Nothing after step 2 reads the content of the working tree** -- step 3 is `gh` over the
network, step 4 is the ref plus `gh`, step 5 folds wherever `HEAD` already is. Verified in the script
rather than inferred: the gates go through `Get-GitFileTextAtRef -Ref refs/heads/<branch>`, and
`$repoRoot` serves only as git's `-C` directory.

### CREATE

- [x] `Get-TrunkReturnDecision` in `scripts/lib/worktree-lib.ps1` -- the three conditions as a pure
      function of the porcelain plus `git status --porcelain`, returning a reason rather than a bare
      `$false`
- [x] Step 2b in `scripts/release/ship-pr.ps1`, between the PR lookup and the CI wait: hand the trunk
      back, never refuse, print which of the three it was when it declines
- [x] The three lines step 3 prints, and the two comment blocks (step 3's invitation, step 5's arm
      table) brought in line with a tree that is already home
- [x] Both plugin mirrors updated (`worktree-lib.ps1`, `ship-pr.ps1`)
- [x] Chris's persona: the two rules reconciled rather than one of them softened
- [x] The `ship-pr` skill gets step 2b in its step list and its own section; `worktree-lane` gets what
      changes for a lane; Chris's repo lens gets the widened branch-check trap

### TEST

- [x] `worktree-lib.tests.ps1` grew from 26 to 44 asserts -- all three conditions, both directions of
      the lane case, untracked-counts-as-dirty, the trunk name as a parameter, and everything git might
      hand over answering rather than throwing
- [x] The suite found a real defect while being written: `[Parameter(Mandatory)]` on a `[string]`
      rejects `''` at the binder, so the lib's own guard for an unreadable path was unreachable and
      would have thrown inside a step whose whole posture is "never a refusal". Repaired in the lib
      with `[AllowEmptyString()]`, not in the test
- [x] `check-plugin-integrity.ps1` green here (0 findings). The suites are deliberately NOT pre-run:
      `open-pr` runs all of them as its own gate and CI runs them again, so a third copy proves nothing
      either would have caught

### DEPLOY: `fix/a-backgrounded-ship-ends-on-the-trunk-v1`

A backgrounded ship now hands your checkout back to the trunk before it waits, so the session it hands
back is one you can actually close.

`ship-pr` merges and folds on the trunk, and until now it did not go there until step 5 -- after the CI
wait. Backgrounding the run was already the default, so the ordinary shape of a shipping session was: the
work is finished, the pull request is open, the close-out says the session can be cleared, and the tree
is standing on the branch. Chris's own body says both that an in-flight ship is a finished assignment and
that a chain ends on the trunk, and for this one shape those could not both be true.

**Step 2b hands the trunk back the moment the pull request exists.** It costs nothing, because nothing
after step 2 reads the working tree any more: since #970 the merge gates read the branch's commit and
since #972 step 5 reads `HEAD` before it moves anything, so `already on main` is an arm the fold has had
all along -- now taken on purpose rather than by luck. Three conditions guard it, and none of them
refuses a ship: the primary checkout only (a lane would hold the clone-wide lock of #1069 for the whole
wait, which is worse than the defect that repair closed), nobody else holding the trunk, and a clean tree
(#972's two outcomes, met one step earlier). A tree that cannot go home stays where it is and says which
of the three it was.

One thing falls out that was not the point: a lane that would have collided with the primary's step 5 --
the narrow window step 0 cannot cover -- now meets step 0's refusal instead. A post-merge half-state
becomes a pre-push refusal.

The decision is `Get-TrunkReturnDecision` in `worktree-lib.ps1`, so it is asserted rather than only
exercised by a live ship: the suite went from 26 to 44 asserts, and found a binder defect in the lib
while it was being written.

**Score:** 4

#### What makes this deploy extra special

Chris's portable body no longer asks the reader to choose between two of its own rules. It now says what
to do when a tool makes them fight -- the trunk wins, and the tool is what changes -- which is the
general form of this repair rather than a note about `ship-pr`. That travels to every consumer, whether
or not they run this workflow.

**Score:** 3

#### Pull Request

A backgrounded ship gives the trunk back before it waits
