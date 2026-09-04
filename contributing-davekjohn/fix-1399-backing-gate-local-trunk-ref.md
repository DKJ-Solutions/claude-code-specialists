## fix/1399-backing-gate-local-trunk-ref

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

### CREATE

- [x] Fix `Get-GitParkBacking` (`scripts/lib/park-lib.ps1`) to prefer `refs/remotes/origin/<trunk>` over the bare local trunk name, falling back to the bare name only when no remote-tracking ref exists (#1399)
- [x] Applied Victor's review finding: reuse the remote-tracking ref's own `rev-parse --verify` result instead of re-verifying the same ref a second time

### TEST

- [x] Added regression coverage in `scripts/tests/backing-gate.tests.ps1` (sections 8-9): the exact false-negative repro (stale local trunk, branch caught up via `git merge origin/main`) and the fallback cases (no origin ref, no ref anywhere)
- [x] `backing-gate.tests.ps1` and `park-cycle.tests.ps1` both green after the fix and after the two review fix-ups
- [x] Victor (code review), Edith (copy edit), Sebastian (security review) ran on the diff -- no blocking findings; Edith's dangling test cross-reference and Victor's redundant-verify-call finding were both applied

### DEPLOY: fix/1399-backing-gate-local-trunk-ref

`open-pr`'s backing gate (issue #1026) is meant to refuse a push whose plan reads as finished with no
real work committed on the branch. It measured that by diffing against a bare local trunk name
(`main`), not the remote-tracking ref. The ordinary flow lets local `main` fall behind `origin/main`
for the length of a branch -- `new-branch` warns but does not refuse -- and the documented way to catch
up mid-branch is `git merge origin/main` (a rebase would need a force-push, which the safety rules
block). That merge advances the branch's merge-base against *local* `main` to include every commit it
just pulled in from origin, because local `main` itself never moves -- so those upstream commits were
counted as the branch's own committed work, and the gate went silent exactly on the branch it exists to
catch. Reproduced on PR #1398, where the gate stayed silent on a branch whose real work (two
documentation files) sat uncommitted, and those files had to be committed by hand afterward.

`Get-GitParkBacking` now prefers `refs/remotes/origin/<trunk>` when it exists (a local, no-network
read of what the last fetch already recorded), and falls back to the bare local name only when it does
not -- fixed inside the shared function, so neither `open-pr.ps1` nor `park-cycle.ps1` needed to change.
Closes #1399.

**Score:** 3 -- a clear improvement to the backing gate's own reliability, noticed the moment a branch
hits the scenario the gate exists to catch (a local trunk fetched behind `origin` and caught up
mid-branch), which is common enough to have already produced a real near-miss (PR #1398) rather than
a hypothetical one.

#### What makes this deploy extra special

N/A -- this is an internal correctness fix to a git-plumbing detail of the branch-workflow gate,
scoped to this repo's own maintainers running `open-pr`/`park-cycle`. It reaches no external audience.

**Score:** N/A

#### Pull Request

Backing gate measures against origin/<trunk> so upstream commits merged into the branch no longer silence it

