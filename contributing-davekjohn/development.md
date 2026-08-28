## Development: `fix/park-cycle-resurrects-shipped-branch-v1` · 20260828-195324

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

Issue #1035: `cycle-autopark` re-creates a remote branch after its PR merged and GitHub deleted it, so
`git ls-remote --heads origin` -- the one read that surfaces a parked branch, because a parked branch
has no PR by design -- reports a branch that shipped hours ago as parked work.

#### The reason was verified before the repair, and one half of the report did not survive

The report's mechanism holds: BOUND 3 in `scripts/task/park-cycle.ps1` asked
`gh pr list --state open`, so the lock lifted at the merge; the gate above it reads a remote-tracking
ref without fetching, so a pruned `origin/<branch>` reads as absent and absent reads as "a local commit
nobody can see"; and `Invoke-GitPark` pushes with nothing to commit, deliberately (#175).

Its reasoning about the SECOND candidate repair did not. The report says a "HEAD is an ancestor of the
trunk" test "covers the closed-unmerged case of #992 too" -- read against #992, that branch sat **96
files divergent from `main`** (2896 insertions / 4377 deletions), so it is not an ancestor of the trunk
and an ancestor test would have pushed it back just as happily. Widening the PR query covers both cases;
the trunk test covers only the one that was measured here. That is why candidate 1 was taken.

#### One repair, not two

Only bound 3 is widened. The other two behaviours the report names are correct as they stand -- the
no-fetch gate is a deliberate cost decision, and #175's push-with-nothing-to-commit is the case park
exists for -- and a second mechanism guarding one measured defect is the pre-emptive fix this repo does
not build.

### CREATE

- [x] `scripts/task/park-cycle.ps1`: bound 3 asks `--state all` with `--json number,state`, and the
      refusal note names which of the three states refused, plus `park-branch.ps1` as the escape valve
      for a branch whose work genuinely resumed.
- [x] The header's bound-3 summary says EXISTS means ever, not just now, and points at the bound for the
      measurement and for why the other candidate was declined.
- [x] Mirrored byte-identical into `plugins/workflows/contributing-davekjohn/scripts/task/park-cycle.ps1`.

### TEST

- [x] `scripts/tests/park-cycle.tests.ps1`: the `merged` and `closed` gh shims are ARGUMENT-AWARE --
      they answer `[]` unless the command line carries `--state all`, so a query narrowed back to
      `--state open` turns them red. Proven: reverting the one flag failed 10 asserts, restoring it
      passed all 82.
- [x] Three new cases -- a merged PR (#1027, the measured one), a closed-unmerged PR (#969, #992's), and
      a payload carrying no `state` field at all.
- [x] That last case earned its place immediately: `$prRecord.PSObject.Properties['state'].Value`
      throws under `Set-StrictMode -Version Latest` when the field is absent, because `$null.Value`
      throws exactly as `$prRecord.state` does. The guard has to be the `$null` test, not the indexer --
      and a mid-bound throw would have broken this script's always-exits-0 contract, which exists so a
      hook cannot interrupt the work it was added to protect.
- [x] Full suite: `check-plugin-integrity.ps1` + every `scripts/tests/*.tests.ps1`, as CI runs them.

### DEPLOY: `fix/park-cycle-resurrects-shipped-branch-v1`

The Stop hook no longer puts a shipped branch back on `origin`. `park-cycle.ps1`'s PR bound asked
`gh pr list --state open`, so it lifted the moment a PR merged -- and on the machine that merged, a
pruned remote-tracking ref then read as "a local commit nobody can see", and the hook pushed the branch
back seconds after `deleteBranchOnMerge` had removed it. Measured on PR #1027: merged 12:56:25, deleted
12:56:27, re-created 13:05:30, at the PR's own head OID with nothing on it `main` did not already have.

That quietly undid the one setting cleaning the remote up, and it poisoned the read it collided with:
`git ls-remote --heads origin` is how a parked branch is found, since a parked branch has no PR by
design -- so the signal for real parked work started reporting shipped branches, each carrying a `park:`
commit whose `Backing:` line read *2 of 2 steps resolved*. A branch that reads as finished work waiting
to be picked up, hours after it landed.

The bound now asks `--state all`: the question it was always protecting is *has this branch been
published?*, not *is a PR open right now?*. The refusal names which state stopped it and points at
`park-branch.ps1` for a branch whose work genuinely resumed -- that judgement belongs to the deliberate
park, never the automatic one. It also covers the closed-unmerged head #992 left behind, which
`prune-merged.ps1` cannot see by design. The other candidate repair, refusing when `HEAD` is an ancestor
of the trunk, would not have: that branch sat 96 files divergent from `main`.

**Score:** 4

#### What makes this deploy extra special

N/A -- `park-cycle.ps1` ships to every consumer of the `contributing-davekjohn` workflow plugin, so the
resurrection stops there too, but this repo is not a subscribed service and has no such reader.

**Score:** N/A

#### Pull Request

park-cycle no longer resurrects a branch whose PR already shipped
