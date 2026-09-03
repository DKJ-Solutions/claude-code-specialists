## Development: `fix/park-write-error-terminates-eap-stop-v1` · 20260903-105257

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

Add -ErrorAction Continue to the three Write-Error sites in Invoke-GitPark (staging, committing, push) so the callers' own return-value handling runs; next: Tycho adds a park-cycle regression test for a rejected push -> exit 0.

`Invoke-GitPark` (`scripts/lib/park-lib.ps1`) writes its three failure summaries with a bare
`Write-Error`. All three callers -- `park-branch.ps1`, `new-branch.ps1`, `park-cycle.ps1` -- set
`$ErrorActionPreference = 'Stop'`, where `Write-Error` TERMINATES, so `return $false` is dead code and
no caller's `if (-not $ok)` arm runs. Worst case: `park-cycle.ps1` runs on a Stop hook whose header
promises *"ALWAYS EXITS 0"*, and a rejected push (the ordinary divergence case) makes it exit non-zero
instead. Reported in #1275; the push arm is the issue's stated subject, the staging and committing
arms carry the identical defect on `main` (the issue assumed #1269 owned them, but #1269 is open,
parked, and its tracked scope does not touch this).

#### Not folded in from #1269

The parked branch `fix/open-pr-commits-branch-doc-v1` (#1269) restructures `Invoke-GitPark` into
`Invoke-GitParkCommit` and carries an incidental copy of the staging/committing `-ErrorAction
Continue` fix. That branch already conflicts with `park-lib.ps1` regardless of this change; on rebase
it can drop its copy of this fix.

### CREATE

- [x] `scripts/lib/park-lib.ps1`: add `-ErrorAction Continue` to the three `Write-Error` sites in
      `Invoke-GitPark` (staging arm, committing arm, `Get-GitPushFailureMessage` push arm), so
      `return $false` is reached and each caller's own return-value handling runs.

### TEST

- [x] `scripts/tests/park-cycle.tests.ps1`: added case (o) -- a branch diverged from origin
      (non-fast-forward, via `commit --amend`), `park-cycle` must `exit 0` and print its
      "could NOT be pushed" line. Verified red before the fix (2 fails), green after.
- [x] `scripts/tests/park-branch.tests.ps1` (d3) and `new-branch.tests.ps1` still green -- their
      end-to-end asserts check the child exit code and merged output text, which the fix leaves
      unchanged for those two callers. (31 / 181 asserts pass.)
- [x] `check-plugin-integrity.ps1` green (0 errors); shared-scripts mirror re-synced via
      `build-shared-scripts.ps1` (root and mirror byte-identical). Every park-adjacent suite green:
      `shared-scripts` (483), `bootstrap-drift` (205, incl. lint-gate smoke), `worktree-lane` (35),
      `worktree-lib` (44), `prune-merged` (96), `backing-gate` (41), `entry-scaffold` (669),
      `gate-lib` (111). `open-pr` re-runs the full gate before the push.

### DEPLOY: `fix/park-write-error-terminates-eap-stop-v1`

A failed `park` now reports its reason and lets the caller own the exit code, instead of throwing a
raw terminating error past the message `Get-GitPushFailureMessage` was written to produce. The
`cycle-autopark` Stop hook keeps its "always exits 0" contract when a park's push is rejected.

**Score:** 3

#### What makes this deploy extra special

N/A -- workflow tooling internal to the park scripts. A consumer on the workflow plugin inherits the
fix on their next update, but only in the failure path of a park; nothing changes for anyone not
debugging one.

**Score:** N/A

#### Pull Request

Invoke-GitPark reports a failed park instead of throwing under EAP=Stop

