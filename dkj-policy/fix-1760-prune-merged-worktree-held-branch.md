## fix/1760-prune-merged-worktree-held-branch

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

Step 4 attempts the delete on a branch checked out in another worktree; git refuses, and the caller gets git's message instead of this script's vocabulary and no way out. Classify it before the delete so -DryRun stops promising it too.

#### What the report got right, and the one thing it over-measured

Verified against the tree before the repair. The symptom stands: the candidate list at step 4 is
`refs/heads` minus the trunk and nothing filters a branch another worktree holds, so a lane-held
branch that IS provably merged reaches `git branch -d`/`-D` and takes git's refusal.

The report marked the consequence "inferred, not measured", and measuring it moved the size down.
The run does not die. The refusal lands on the delete, which step 4 already reports as
`Kept <branch> -- git branch -D refused: <git's text>`, and the run exits 0 with the branch intact.
Measured by running the new fixture case against the pre-fix script: 5 of its 14 asserts fail, and
none of them is about a lost branch or a non-zero exit. So this is a vocabulary and hand-back
defect, not a data-loss one -- which is why it is repaired at the classification rather than
guarded at the delete.

### CREATE

- [x] `scripts/task/prune-merged.ps1`: step 4d keeps a branch another worktree is standing on, with
      this script's own sentence and the `worktree-lane.ps1 -HandBack` command, instead of attempting
      a delete git will refuse. Asked AFTER the two proofs (a lane holding unfinished work keeps its
      own reason) and BEFORE the `-DryRun` branch (so the look-first run stops promising a delete the
      real run cannot perform).
- [x] `Get-WorktreePorcelain`: the worktree list is read at most once per run and shared with the
      #1069 fast-forward path, which read it inline. Lazy, so a run needing neither pays nothing;
      once, so the two answers cannot be taken at different moments.
- [x] Header step list documents 4d, so the doc and the code agree.
- [x] Mirrored to `plugins/dkj-policy/scripts/task/prune-merged.ps1` (byte-identical).

### TEST

- [x] `scripts/tests/prune-merged.tests.ps1` case (e3): a merged branch held by a lane -- the branch
      survives, the reader gets this script's sentence and the hand-back, `refused:` never appears,
      and `-DryRun` does not promise the delete.
- [x] Case (e4), the bound: an UNMERGED branch in a lane keeps its own "not an ancestor of the trunk"
      reason and is not reported as an obstacle.
- [x] Verified in both directions, the way #1191's stub was: 127 pass / 0 fail on the fix, and 5 of
      the new asserts FAIL against the pre-fix script. (e4) passes both ways by design -- it asserts a
      bound, not a regression.
- [x] Full suite + lint gate via `open-pr.ps1`.

### DEPLOY: fix/1760-prune-merged-worktree-held-branch

`prune-merged.ps1` no longer attempts a delete git is certain to refuse. A branch that is provably
merged but checked out in another worktree is reported kept in the script's own vocabulary, naming
the directory holding it and the `worktree-lane.ps1 -HandBack` command that frees it -- the sentence
#1069 already gives for a lane holding the trunk. `-DryRun` answers the same question, so the
look-first run no longer promises a delete the real run cannot perform.

The seam this closes: `worktree-lane.ps1` states that branch cleanup is `prune-merged.ps1`'s, and
`prune-merged.ps1` removes no worktree -- so a lane whose work had landed was owned by neither, and
the hand-back was a manual act nothing prompted for.

**Score:** 2

Small and only visible to somebody running lanes: it prevents a confusing report rather than a loss.
The failure it prevents, named because the tier asks for it -- a session reads `git branch -D
refused: error: cannot delete branch 'x' used by worktree at '...'`, which is git's vocabulary rather
than this script's proofs, and has to work out for itself that the way out is a hand-back.

#### What makes this deploy extra special

**Score:** N/A

Nothing reaches a subscriber: this is a maintainer's tidy-up command in the workflow plugin.

#### Pull Request

prune-merged: a merged branch held by another worktree is kept with the hand-back, not handed git's refusal

