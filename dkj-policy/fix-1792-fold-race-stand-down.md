## fix/1792-fold-race-stand-down

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

#### What #1792 measured, and what it deliberately left open

Shipping PR #1789 on 2026-09-10, `fold-on-merge.yml` folded the entry first and `ship-pr.ps1`'s own step 5
lost the push by seconds. The fold script diagnosed it correctly -- entry upstream, present once, body
identical -- and exited `1`; `ship-pr` read `-ne 0`, reported *"the fold is NOT committed or NOT pushed"*,
and exited `1` over a ship that had merged, folded and closed its issues. The session was left on a local
`main` diverged 1/1 whose obvious remedies (`reset --hard`, a rebase on a shared branch) `CLAUDE.md`
reserves to Dave.

The issue explicitly did **not** choose between repairing `ship-pr` and removing one of the two runners.
Removing `fold-on-merge.yml` is settled against by the repo's own record: `CLAUDE.md` keeps both runners
*"whatever happens"* to the merge queue, because the GitHub UI merge button exists in every repo and a fold
depending on the shipping session is one such merge away from being skipped. So the repair is on the
`ship-pr` side, carried by an **exit code** rather than by prose -- #1586's own precedent, whose comment
says *"the code is the contract because the prose cannot be"* across two release boundaries.

#### The adjacent case that is deliberately not in this branch

`fold-on-merge.yml` can lose the same race at the same point (its pre-pass passes, its push is refused) and
then goes red on the new `3` exactly as it did on `1` -- no regression, and a pre-existing gap #1586 already
closed the wide half of. Filed as #1796 rather than folded in here: it changes a CI red/green semantic
documented across two boundaries, which is a second subject.

### CREATE

- [x] `fold-changelog-entry.ps1`: the redundant-commit verdict exits `3` instead of `1`, with the reasoning
      at the exit and the `EXIT CODES` header extended to name all three and to say why `2` and `3` must
      not be merged.
- [x] `ship-pr.ps1`: `$foldExit -eq 3` is a stood-down success -- the run carries on to steps 5b, 6, 7 and
      8 -- with the hard failure kept as the `elseif` for every other non-zero code. A new step 5c prints
      the two commands that realign this checkout (a `backup/fold-<branch>` ref, then `reset --keep` or
      `branch -f` depending on whether the trunk is still checked out here -- read from HEAD after 5b,
      detached included) and runs neither. No fetch line: the fold's own diagnosis had to fetch to reach
      the verdict. The header's step list and step 5b's comment say so.
- [x] Both mirrored byte-identical into `plugins/dkj-policy/scripts/release/`.
- [x] `fold-changelog` skill: the `3` half of the contract, and why it is not the pre-pass's `2`.
- [x] `ship-pr` skill: a section of its own for the race, what the old `-ne 0` cost, and why step 5c
      reports rather than repairs.
- [x] [Sylvester's lens](../.claude/specialists/lenses/05-15-extension.md): the measurement, beside
      #1543/#1586 -- the same race run the other way.

### TEST

- [x] `fold-changelog.tests.ps1`: the raced fold is pinned at `3` (it was pinned at `1`, which is what made
      the old behaviour tested rather than incidental), the ordinary divergence is pinned at `1` as the case
      that must **not** borrow it, and `exit 3` is asserted to come from exactly one place -- the same
      property the `2` block already asserts.
- [x] And the reader's half, pinned across the file boundary: `ship-pr.ps1` reads `3` specifically, its
      hard-failure arm is an `elseif` so `3` cannot fall through, and it cites the issue. That orchestrator
      has no suite of its own, which is how `-ne 0` stayed the tested behaviour on the caller side
      through #1586.
- [x] Full suite run + `check-plugin-integrity.ps1`: green.

### DEPLOY: fix/1792-fold-race-stand-down

**A fold lost to `fold-on-merge.yml` no longer fails the ship.** `fold-changelog-entry.ps1` returns a new
exit code **`3`** when it committed, its push was refused, and **every** entry that commit carries is
already upstream with an identical body -- "the fold happened, somebody else made it". `ship-pr.ps1` reads
that as a stood-down success and carries on through its remaining steps instead of reporting a hard failure,
and its closing line names who folded. Every other non-zero code is the failure it always was, and an
ordinary divergence keeps `1`, because that commit carries work. Fixes #1792.

**A new step 5c says what the race actually cost, which is local only:** the redundant fold commit still
sitting on this checkout's trunk. It prints a `backup/fold-<branch>` ref that preserves the commit, then the
one realignment the tree it finds can run -- `reset --keep origin/main` where the trunk is checked out here,
`branch -f main origin/main` where nothing holds it -- and **runs neither**. `--keep` is not `--hard`, but a
script that moves a trunk pointer has taken a power nobody granted it, and the fold script declines the same
thing one step below. What #1792 measured missing was never the authority; it was the sentence naming which
two commands.

**Score:** 3

#### What makes this deploy extra special

Measured shipping PR #1789 on 2026-09-10: the two fold commits had **identical trees** and `origin/main` was
correct, so nothing was at stake in the content -- and the shipping session was still told its ship had
failed and left holding a state its own constitution forbade every obvious route out of. That asymmetry is
the whole finding: a red CI job is read once and closed, while this ended a correct chain on a trunk the
operator was not allowed to fix.

**`2` and `3` are deliberately not one code.** After the pre-pass's `2` nothing was written and there is
nothing to clean up; after `3` a commit is on the local trunk. Neither script repairs it, so a caller that
conflated them would either invent a leftover that does not exist or stay silent about one that does -- and
silence is the one outcome worse than the hard failure this removes.

**Score:** N/A

#### Pull Request

The fold losing the race to fold-on-merge is a stood-down success, not a failed ship
