## Development: `fix/new-branch-remote-resume-v1` · 20260830-132656

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

Fix #1139: `new-branch.ps1` decides whether a branch already exists by reading one ref,
`refs/heads/<name>`. That is the LOCAL namespace, so on a machine that has not fetched a parked branch
into a local ref the answer is no and `git checkout -b` forks a second branch of the same name at the
current base -- carrying none of the parked work. Since #900 this script pushes by default and
`cycle-autopark` keeps the branch current on origin, so a branch whose only copy is on the remote is the
NORMAL product of this workflow rather than an edge case, and the script documented as *idempotent* was
the one blind to it. `worktree-lane.ps1` inherits it whole through its step-4 delegation.

#### The reason was verified before the repair, not just the symptom

Read rather than assumed: `new-branch.ps1:327` really did ask `refs/heads/$Name` alone,
`new-branch.ps1:340` really did `git checkout -b` with no `--track` and no remote start point, and
`worktree-lane.ps1` really does add its worktree detached at `origin/<trunk>` before delegating. All
three still stood.

#### One thing the report left open, and one it did not see

**The report chose neither of its two repairs** -- resume at the remote tip with tracking, or refuse and
print the git command -- and said either is honest. **Resuming wins here** because this script is the
documented resume tool for a handoff the workflow creates on its own, so a refusal puts a hand-typed
`git branch --track` on the intended happy path. What the report actually rules out is a *silent*
adoption, and that is answered by naming it rather than by refusing.

**And the base check had to move.** #1046's warning counts `HEAD..origin/<trunk>` before the checkout, so
on a resume it reports whatever the operator was standing on -- the trunk, normally -- with the resumed
branch's name attached. That was already false for a local resume and my change would have added a second
case of it, so the resume question is now settled BEFORE anything is said about a base.

### CREATE

- [x] `scripts/task/new-branch.ps1`: read both namespaces (`refs/heads/<name>` and
      `refs/remotes/origin/<name>`) and resolve resume-or-cut before the base is discussed. Origin-only
      becomes `git checkout -b <name> --track origin/<name>` -- created at the remote tip -- and the run
      says which of the three things it did, plus what to type (`-v2`) if a new branch was meant.
- [x] The base measurement is skipped on a resume, with a dim line saying why, so no run is handed a gap
      that belongs to a branch it was never cut from.
- [x] The two ref reads moved to `Invoke-NativeCapture`, which the file's own comment already said the
      hand-written EAP dance should be. The checkout keeps that dance deliberately: its stderr is git's
      progress text, which is PRINTED rather than judged.
- [x] Docstring updated -- the `.DESCRIPTION` now states the resume rule beside the base rule.
- [x] `plugins/workflows/contributing-davekjohn/skills/new-branch/SKILL.md`: the numbered flow gains the
      resume question and states the three shapes; a new section carries the reasoning and the table.
- [x] Plugin mirror regenerated via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `scripts/tests/new-branch.tests.ps1`: new helper `Add-OriginBranch` (the other device's parked
      branch, built through a throwaway clone so the fixture never gets a local ref), plus sections (v)
      and (w).
- [x] (v) A branch that exists only on origin is resumed, not forked -- and the assert that matters is
      that the parked WORK is in the checkout, because every other signal reads identical on a fork: the
      run is clean (idempotence promises that) and the scaffold is byte-identical (the same script wrote
      both).
- [x] (w) A local resume is no longer told the trunk's gap is its own, with the first run of the same
      fixture as the positive control -- a genuine cut IS still warned, so #1046 is pinned rather than
      loosened.
- [x] Whole suite green: **163 asserts**.
- [x] **Red-checked**: with `scripts/task/new-branch.ps1` swapped back to its pre-fix version the same
      suite reports **9 failed, 154 passed**, all nine in the two new sections. The tests fail for the
      reason they were written.

#### What the red check measured that the report could not

The report said explicitly that it had NOT measured the far end -- whether the fork surfaces as a rejected
push or as a quiet divergence. The red check answers it: `parked branch: exit 0` is among the nine
failures, so the pre-fix run ends **non-zero**. Read from the code rather than inferred from that:
`Invoke-GitPark` returns `$false` when its `git push -u` fails (`scripts/lib/park-lib.ps1:442`) and
`new-branch.ps1` exits 1 on it. So the fork was not silent at the push -- but the line it printed says
*"is 'origin' configured and reachable?"*, which is the wrong cause for a non-fast-forward against a
branch that is already there. Filed separately rather than repaired here.

### DEPLOY: `fix/new-branch-remote-resume-v1`

`new-branch` now resolves *resume or cut* by reading **both** ref namespaces before it acts, so a branch
that exists only on `origin` is resumed at the remote tip with tracking instead of being forked at the
current base. That branch is this workflow's own cross-device handoff -- `new-branch` pushes by default
and `cycle-autopark` keeps it current on the remote -- so the script documented as idempotent, the one you
are told to re-run to resume, was the one that could not see the branches the flow produces. Nothing on
screen said so: the run reads clean because idempotence promises a clean run, and the scaffold written
into the fork is byte-identical to the one on the parked branch because the same script wrote both. What
was missing was the branch's work. `worktree-lane.ps1` inherited the whole failure through its
delegation and reported `Lane open` as on a genuine new branch.

The run now names which of the three things it did, and says the name is taken and to type `-v2` if a new
branch was meant -- a resume is adopted, never adopted silently. In the same movement the #1046 base
warning moved behind that question: its count is `HEAD..origin/<trunk>` measured before the checkout, so
on a resume it was handing over the trunk's gap under the resumed branch's name. A cut is still warned,
with the count, twice.

**Score:** 4

#### What makes this deploy extra special

`new-branch.ps1` is mirrored into every consumer's plugin cache, and the parked branch is their
cross-device handoff too -- so this is the fix arriving where the failure was silent and the work simply
was not there. The skill page that told them the script is idempotent now states all three shapes it
actually has.

**Score:** 3

#### Pull Request

new-branch resumes a branch that exists only on origin
