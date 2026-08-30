## Development: `fix/prune-merged-no-checkout-borrow-v1` · 20260830-145327

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

Replace step 2's checkout+pull with a refspec fetch; borrow the checkout only to reap the start branch itself.

#### The issue, and the decision it left open

Issue [#1147](https://github.com/DaveKJohn/claude-code-specialists/issues/1147) filed the mechanism and the
trade, not the remedy: it named two shapes and said "not proposed which".

1. **Accept the loss** -- drop the borrow entirely and report a merged start branch as
   `Kept -- git branch -d refused: ...`, because `git branch -d` cannot delete the branch `HEAD` is on.
2. **Borrow only for that delete** -- fetch without a checkout, run the analysis, and take the checkout only
   when the start branch itself turns out reapable.

**This branch builds (2).** It removes the collision completely while losing no capability, and the borrow it
keeps can only ever happen on a branch that has just been *proven merged* -- so it cannot overlap a running
gate, whose branch is unmerged by definition. (1) would have been a visible behaviour regression on the
common route, reported as a keep for a reason the caller cannot act on without a second command.

#### Verified before building, not assumed

The report's mechanism was measured in a throwaway clone rather than taken on trust
(`git version 2.54.0.windows.1`): `git fetch origin main:main` from another branch fast-forwards the local
ref and exits 0; against a diverged remote it prints `! [rejected] ... (non-fast-forward)` and exits 1 with
the local ref untouched; and run while `main` *is* checked out it refuses with
`fatal: refusing to fetch into branch 'refs/heads/main' checked out at '<path>'`. That last one is why step 2
has two arms rather than one.

### CREATE

- [x] Step 2 fast-forwards with `git fetch <remote> <trunk>:<trunk>` -- no checkout, no working tree moved.
      A run already standing on the trunk keeps `git pull --ff-only`, because git refuses to fetch into the
      checked-out ref.
- [x] A refused fast-forward is a **warning**, not a refusal. That is the [#1069](https://github.com/DaveKJohn/claude-code-specialists/issues/1069)
      case: a second worktree holding the trunk used to make the checkout impossible clone-wide and this
      script *refused* -- unavailable in exactly the situation that produces stray branches. It runs now;
      only the fast-forward is lost, and the warning still names the holder and the way out.
- [x] Step 4c: the one move that survives -- step off a start branch that has just been proven merged,
      announced where it happens. `-DryRun` never reaches it.
- [x] `Restore-StartCheckout` reduced to that single case, gated on a `$steppedOff` flag. The detached start
      and the trunk start no longer need a sentence, because nothing moves them.
- [x] The docs that asserted the borrow: the `prune-merged` skill page, `CONTRIBUTING.md`'s single-occupancy
      block, `gate-lib.ps1`, `open-pr.ps1`, `ship-pr.ps1`, the `ship-pr` skill page, `shared-scripts-lib.ps1`,
      and Chris's lens (which is the instruction that produced the collision).
- [x] The `#1145` detection is **kept**, and each citation says the measured cause was repaired at the source
      rather than that the check is now pointless -- `new-branch.ps1` and `worktree-lane.ps1` still move this
      checkout, and a borrow-and-return is exactly the shape the fingerprint alone is blind to.
- [x] Plugin mirrors resynced byte-identical (`prune-merged.ps1`, `gate-lib.ps1`, `open-pr.ps1`, `ship-pr.ps1`).

### TEST

- [x] `prune-merged.tests.ps1`: 77 pass, 0 fail. Five cases inverted with the contract and two added.
      (e2) a held trunk is now exit **0**, still names the lane, and **still reaps** -- the assert that the
      refusal used to cost the tidy-up. (i) HEAD never moves, and asserts the **absence** of the switch and
      hand-back lines, which a script that borrowed and returned would fail while passing the HEAD assert.
      (j) gains a `-DryRun` half proving the step-off does not happen there. (k) asserts the pull path
      *succeeded* rather than only that HEAD stayed put. (l) a detached start survives on the same commit.
- [x] New structural case (n): step 2 -- the source between its own marker and step 3's -- contains no
      `'checkout'` call. Case (i) proves the run leaves HEAD alone; only this proves the source cannot take
      it back, which is the distinction a fixture assert on the final HEAD cannot make.
- [x] Lint gate green (0 errors), all suites green.

### DEPLOY: `fix/prune-merged-no-checkout-borrow-v1`

`prune-merged` no longer takes the checkout. Step 2 used to `git checkout <trunk>`, `git pull --ff-only`, and
hand the checkout back -- and a borrow returned within the second is still a tree that moves under whatever
else is running in the same checkout. That is the cause measured in
[#1145](https://github.com/DaveKJohn/claude-code-specialists/issues/1145): a file present on the branch and
absent on the trunk vanished and reappeared under a running test suite, turning a green gate red. It now
advances the trunk with `git fetch <remote> <trunk>:<trunk>`, which writes a local ref that `HEAD` is not on
and moves no working tree at all; the fast-forward guarantee is git's own, since it refuses a non-ff into
`refs/heads/` unless the refspec carries a leading `+`. A run already standing on the trunk keeps
`git pull --ff-only`, because git will not fetch into the checked-out ref.

**One move survives, and it cannot collide.** `git branch -d` can never delete the branch `HEAD` is on, so a
start branch that is *provably merged* is stepped off first -- announced where it happens, and the run then
ends on the trunk naming the sha it left. A branch under a running gate is unmerged by definition, so it
never reaches that line: what is left moves the tree only on work that is already finished.

**And the [#1069](https://github.com/DaveKJohn/claude-code-specialists/issues/1069) refusal went with it.**
A second worktree holding the trunk used to make the checkout impossible clone-wide, so this script refused
outright -- unavailable in exactly the situation that produces stray branches. git will not write a
checked-out ref either, but now that costs only the fast-forward: the run continues against the older trunk,
which errs towards *keeping* branches, and the warning still names the lane and how to release it. #1145's
detection stays untouched, because it is the right repair for the class and every other tree-mover in the
clone is still there.

**Score:** 3

#### What makes this deploy extra special

The workflow tells a consumer's session to run `prune-merged` mid-assignment and to background `ship-pr` so
the session can get on with something else -- two instructions that quietly collided in the shared checkout.
One of them stops colliding here, so a consumer gets fewer false reds from their own tooling without changing
anything they do. Their `prune-merged` also works in a state where it used to refuse: with a lane standing on
the trunk, it now reports instead of stopping.

**Score:** 3

#### Pull Request

prune-merged fast-forwards the trunk without borrowing the checkout
