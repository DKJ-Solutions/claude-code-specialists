## `docs/ship-pr-reads-the-worktree` deployment

### What does the change on this branch deploy to main?

The `ship-pr` skill page names the assumption its step-list gate rests on, and the one thing that breaks
it. The gate opens `branch-cycle.md` **on disk**, which the script's own comment states is correct
"because that is where HEAD still is at this point" -- and that is an assumption rather than a check:
nothing compares the branch you are standing on against the branch whose PR is being merged.

Measured today in this repo. Two sessions were working in one checkout; one had `ship-pr` waiting on CI,
the other created a branch and moved `HEAD`. When CI went green the gate read the *other* branch's freshly
scaffolded step list and refused the merge over a step belonging to nobody's work on that PR, while the
PR's own list was complete and committed. Nothing was damaged and re-running from the right branch picked
up where it left off -- but the same assumption fails the other way too, letting an unfinished list
through when the tree stands on a finished branch, and that direction is silent.

**A guard is deliberately not built.** Refusing when `HEAD` and the PR's head ref differ is one
comparison, but it is a change on the merge path and one benign instance is not the evidence for making
it. What the trap needed was to be recognisable, which is a paragraph. The page also states the wider
rule none of these scripts could see: they assume one working tree per session, `/lock` is a note rather
than a claim on a checkout, and two things that really do run at once want a second clone or a worktree.

**Score:** 2

#### What makes this change extra special

Whoever hits this reads a refusal that names a step they never wrote, on a PR whose own step list is
finished -- and every instinct then points at the step list rather than at `git rev-parse`. The
consumer-facing cost is a run that looks broken and is not, on the command that merges; the page now
answers it in one line.

**Score:** 2

### Pull Request

ship-pr names the assumption its step-list gate rests on, and what breaks it
