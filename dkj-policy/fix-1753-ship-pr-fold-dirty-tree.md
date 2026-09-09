## fix/1753-ship-pr-fold-dirty-tree

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Step 5 no longer checks the trunk out over an unclean working tree, and its post-merge failures say the PR is merged

#### What the report said, and what the code said back

Issue #1753, measured shipping PR #1752. Step 2b reads `git status --porcelain`, hands it to
`Get-TrunkReturnDecision`, and declines the trunk return because the tree is dirty -- "a checkout would
take them to the trunk or fail on them". Step 5 then ran `git checkout main` unconditionally, which is
that same checkout, made after the merge instead of refused before it. The path travelled to the trunk,
`git merge --ff-only origin/main` failed on it, and the run ended merged-but-unfolded.

Verified against the tree before anything was repaired: `ship-pr.ps1`'s step-5 preamble already carried
#972's measurement of both outcomes of that unconditional line -- the colliding edit and the one that
travels -- but chose its arm on **HEAD's location alone**, so both were still live on an ordinary
foreground run. That is a sharper statement of the defect than the report makes, and it is what decided
the repair.

#### Why not the step-0 refusal the report proposed

The report's suggested shape was a pre-flight refusal on this tree's "a refusal costs nothing before the
irreversible act" posture (#1405, #1417). Step 5 already holds an arm that does not touch this checkout
at all -- the throwaway worktree #1069 added for a HEAD that moved -- and it is available in exactly the
failing case: an unclean tree means step 2b declined, so HEAD is still on the shipping branch and the
trunk is free (step 0a refuses otherwise). So the fold completes rather than being refused, and the
condition the report itself named -- "the fold would have to ff-only past it" -- is false instead of
guarded. A refusal would have stopped a ship this repairs.

The one residual is narrow and unpreventable at step 0: a tree already ON the trunk (where step 2b puts
it) that something writes into during the CI wait. `git worktree add <path> main` is refused once the
primary holds main, so that arm stays in place -- and gets the second half of the repair instead.

### CREATE

- [x] `Get-FoldTreeDecision` in `scripts/lib/worktree-lib.ps1` -- a pure function of the two names git
      printed plus the porcelain status lines, answering which arm step 5 takes and the sentence that arm
      prints. The trunk exemption is checked first, so the dirt test cannot send a tree holding the trunk
      to a `worktree add` git will refuse.
- [x] `scripts/release/ship-pr.ps1` step 5 asks it -- reading `git status --porcelain` at step 5 rather
      than reusing step 2b's, because the CI wait sits between them. An unreadable status counts as dirty
      here (the opposite of step 2b's posture, and stated): the worktree arm is correct whatever the tree
      holds, so guessing toward it costs a temporary directory.
- [x] The worktree arm prints the decision's own sentence instead of a hard-coded "this checkout moved
      while CI ran", which is now false on two of the three ways to reach it. The #1623 strip travels with
      it into the composer.
- [x] The three post-merge failures all say the PR is merged. The timed-out fetch carried the full
      sentence; the plain fetch failure and the `ff-only` failure -- the arm that actually fired on
      PR #1752 -- did not. One `$mergedNotFoldedNote`, so only the first line differs between them.
- [x] `$foldScript` hoisted to one definition, rather than a third copy of the same line.
- [x] Plugin mirrors regenerated (`scripts/sync/build-shared-scripts.ps1`).

### TEST

- [x] `scripts/tests/worktree-lib.tests.ps1` -- new section 10, 25 asserts: the clean run still folds in
      place, an unclean one takes the worktree, untracked counts, blank capture lines do not (so step 2b
      and step 5 cannot disagree about what dirt is), the trunk arm stays exempt clean and dirty, the
      moved and unreadable HEAD arms keep their own sentences, the trunk name stays the caller's, the
      #1623 strip holds, malformed input answers rather than throws, and ship-pr actually calls it.
- [x] Suite green on its own: 100 asserts.
- [x] Lint gate: 0 errors.
- [x] Full test gate: all 87 suites passed.

### DEPLOY: fix/1753-ship-pr-fold-dirty-tree

`ship-pr.ps1` no longer loses the fold to an uncommitted file. Step 5 used to run `git checkout main`
whenever HEAD was where the script had left it -- the same checkout step 2b had already declined one
step earlier because the tree was unclean -- so an unrelated uncommitted path was carried onto the trunk
and `git merge --ff-only origin/main` then failed on it, leaving the PR merged and the changelog
unfolded. It now chooses the tree it folds in on the tree's cleanliness as well as on HEAD's location:
an unclean checkout folds in the throwaway worktree #1069 already built, so the fold completes, the
uncommitted path stays where its author left it, and nothing is refused. A tree already standing on the
trunk stays on the in-place arm, because git refuses a second worktree on a branch the primary holds.
The three failures that can still land after the merge now all say so -- the `ff-only` arm, the one that
actually fired, said only `git merge --ff-only of origin/main failed.` while its neighbour one branch up
carried the full merged-but-unfolded sentence and the by-hand fold command.

**Score:** 4

#### What makes this deploy extra special

`ship-pr.ps1` and `worktree-lib.ps1` are both shipped by `dkj-policy`, so every repo running this
workflow gets the repair. It matters more there than here: this repo recovers a skipped fold through
`fold-on-merge.yml` (#1493), and a consumer that has not adopted that runner is left with the entry
stranded on the trunk with nothing saying so until the next session's check reports it.

**Score:** 3

#### Pull Request

ship-pr folds a dirty tree in a worktree instead of dragging it to the trunk
