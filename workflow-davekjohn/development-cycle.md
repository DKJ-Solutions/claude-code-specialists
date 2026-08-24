# Development cycle: `fix/a-lane-can-run-its-own-gates-v1` · 20260824-110428

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

Teach the source-repo guard that a git worktree of the resolved repo IS the repo, and have check 25 name a refusal as a cause, so a lane stops reporting an encoding failure it does not have.

Teach the source-repo guard that a git worktree of the resolved repo IS the repo, and have check 25 name a refusal as a cause, so a lane stops reporting an encoding failure it does not have.

## PLAN

- [x] Verify the finding against the tree rather than from the symptom: `Resolve-GuardRepoRoot` prefers
      `CLAUDE_PROJECT_DIR`, which in a session that opened a lane still names the primary checkout -- so
      condition 1 of `Get-OwnCopyPath` sees every lane path as outside the repo.
- [x] Establish what the lint gate was actually reporting, because it named the wrong subject: check 25
      has the sub-script's exit code and no `[mojibake]` line to attribute it to, so a REFUSAL came out
      as *"the mojibake gate could not complete"*. The guard's own explanation was reachable only by
      running the sub-script by hand.
- [x] Choose between the three directions the report offered, and take the one it called most correct
      rather than the cheapest: teach the guard about worktrees. The report's own argument for hesitating
      -- that this touches a load-bearing check -- is an argument for tests, not for a hint in the output.
- [x] Find the identity test before building on it, and MEASURE it rather than reason about it
      (2026-08-24, git 2.54.0.windows.1): `git rev-parse --git-common-dir` answers
      `.../claude-code-specialists/.git` for both the primary and a lane, and
      `.../marketplaces/claude-code-specialists/.git` for the plugin cache. So a worktree is allowed and
      a CLONE -- the released mirror this guard exists for -- is still refused.
- [x] Check that the writing scripts are safe to run from a lane before running one there:
      `build-shared-scripts.ps1` and the lint gate both resolve their root from `$PSScriptRoot`, not from
      `CLAUDE_PROJECT_DIR`, so a lane run writes into the lane. Verified before use, since the primary
      was mid-ship at the time.

## CREATE

- [x] `Get-GuardGitCommonDir` in `scripts/lib/source-repo-guard-lib.ps1`, and condition 1b in
      `Get-OwnCopyPath`: a script inside a worktree of the same repository is allowed. Both sides of the
      comparison must answer, because a `$null` means "cannot tell" and a guard that cannot tell must
      keep refusing.
- [x] Check 25 in `check-plugin-integrity.ps1` now quotes the child's own first line and names a refusal
      when it sees one, so an exit code without a finding stops being reported as an encoding problem.
- [x] `worktree-lane.ps1` says in its closing output that the gates run in a lane, since that is the line
      a person reads before they try it.
- [x] Mirrors regenerated: the guard lib for `workflow-davekjohn` and `team-shopify`, and
      `worktree-lane.ps1`.

## TEST

- [x] **The real end-to-end check, and it is the one that matters:** the lint gate run from the lane with
      `CLAUDE_PROJECT_DIR` still pointing at the primary -- no repointing, no workaround. Before this
      change that run reported 1 error about encoding; now it reports **0 errors**. That is the defect,
      reproduced and then gone.
- [x] 8 new asserts in `scripts/tests/source-repo-guard.tests.ps1`, on a REAL git repo with a REAL
      worktree and a REAL clone, because the question is what git answers and a stub would only test the
      stub. The pair is asserted together: worktree allowed **and** clone still refused. 20 asserts green.
- [x] All 52 suites in the lane: 51 green. The 52nd, `roster-sync`, failed one assert on my own
      invocation rather than on the change -- `Resolve-CheckRoot`'s git-root fallback reads the process
      **working directory**, and I ran the lane's suite from the primary. Re-run with the lane as the
      working directory: **329 pass, 0 fail**, identical to the primary's own run. The assert states that
      precondition in its own label, so this is not a defect and is recorded rather than filed.
- [x] The `Invoke-NativeCapture` pitfall, met and repaired inside this branch: the first draft of the
      worktree asserts died on `git worktree add` printing progress to stderr under `EAP = Stop` -- the
      #96/#97/#107 failure, on a command that had exited 0. Every git call in the suite goes through the
      shared capture now.

## DEPLOY: `fix/a-lane-can-run-its-own-gates-v1`

A lane exists so a branch can be built while another one ships -- and until now it could be built in but
not **checked** in. The source-repo guard resolves the repo from `CLAUDE_PROJECT_DIR`, which still names
the primary checkout, so every lane path read as a released snapshot and every gate run from a lane was
refused. Worse, it was refused in the wrong words: the lint gate has its sub-script's exit code and no
finding to attribute it to, so it reported *"the mojibake gate could not complete"* -- an encoding problem
in a tree that had none. So a lane-built branch was verified for the first time by CI, after the push,
which is the wait lanes exist to remove.

The guard now accepts a script inside a **worktree of the same repository**, compared on
`git rev-parse --git-common-dir`: a linked worktree shares one `.git` with the primary, while a separate
clone answers with its own -- so the plugin cache mirror this guard exists for is still refused, and that
pair is asserted together on a real repo. Check 25 quotes the child's first line and names a refusal when
it is one, and `worktree-lane.ps1` now says in its closing output that the gates run there.

**Score:** 4

### What makes this deploy extra special

Every consumer that opens a lane gets the same repair, and it removes a trap rather than adding a feature:
the previous behaviour did not just refuse, it reported the wrong subject, which is the shape that costs a
reader an afternoon. Nothing about the guard's reach is widened -- a released copy is refused exactly as
before, proved by an assert that runs against a real clone rather than a fixture.

**Score:** 3

### Pull Request

A lane can run this repo's own gates
