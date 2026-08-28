## Development: `fix/sync-sees-its-own-standing-branches-v1` · 20260828-143347

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

Inbound #1021: `sync-main` names a new branch per run without ever asking whether a previous sync branch
is still standing, so unmerged sync branches stack up silently. Two pure functions in `sync-rules.ps1`
plus wiring in `sync-main.ps1`, anchored on the branch-prefix **seam** rather than a literal `sync/`.

#### What the verification changed about the report

The report stood on all six checks, with two corrections that changed the work:

- **Its reason sharpens.** It says the script "never looks at its own previous output." It *does* — the
  naming loop checks `refs/heads/<branch>` and `refs/remotes/origin/<branch>` before settling on a name,
  so it sees the predecessor and draws no conclusion. The `-2` suffix in the measurement *is* that. What
  was missing was never the lookup but a verdict on what it found, which is why the guard is planted at
  that step rather than as a new stage.
- **Its proposed repair carried one defect**, and it is the failure this guard exists to end wearing the
  opposite face: it anchored on the literal `refs/heads/sync/`. `Get-ShopifySyncBranchPrefix` is a seam
  the README calls *"yours to set because it has to line up with whatever your PR guardrails and CI
  exempt"* — so a consumer answering it `theme-drift/` would get a scan that finds nothing and a guard
  that never fires. The shipped version takes the prefix from the caller.

Its two upstream questions are answered in the code rather than deferred: the merged test does **both**
halves (ancestry *and* `gh pr list --state merged`, as `prune-merged.ps1` already does) rather than
assuming `delete_branch_on_merge`; and the refusal is unconditional, with `-AllowStacking` as the
override, because a refusal costs nothing — the drift is already on the predecessor either way.

Its consumer-side counts (4 branches, 21 files, 37 -> 57 asserts) are measurements of *their* tree and
were not inherited.

### CREATE

- [x] `scripts/lib/sync-rules.ps1`: `Get-SyncBranchNamesFromRefs` — parse `git ls-remote --heads origin`
      into branch names, anchored on `refs/heads/<prefix>` so a `tooling/sync-...` branch cannot report
      itself as its own predecessor and a consumer's own prefix is what decides. Peeled `^{}` refs,
      warning lines and blanks dropped; a whitespace-only prefix throws rather than matching everything
      or nothing.
- [x] `scripts/lib/sync-rules.ps1`: `Get-SyncPredecessorReport` — per standing branch, whether this run's
      take set covers every path it captured, and which it does not. Supersession measured on **paths,
      never content**, stated in the docstring; ordinal comparison, chosen for its failure direction (it
      can decline a supersession, never claim a false one).
- [x] `scripts/task/sync-main.ps1`: the detection at step `[3b/6]`, **before the theme pull**, so a
      refused run costs no network. Two-part merged test; where `gh` cannot answer, a branch reads as
      standing — the opposite of `prune-merged`'s fallback and the same principle, each erring toward
      doing nothing.
- [x] `scripts/task/sync-main.ps1`: the refusal, with `-AllowStacking` and `-DryRun` as the two ways
      through, and `Write-SyncPredecessorVerdict` called at all three points where the take set is
      complete — the dry-run report, the pre-push report, and the "no third-party drift" exit, which is
      the most misleading place to stop quietly.
- [x] Docstrings, `.PARAMETER AllowStacking`, and the plugin mirrors rebuilt via
      `scripts/sync/build-shared-scripts.ps1`.
- [x] Docs: the `sync-main` skill page (step 4, the parameter row, the refusal row, and a new **Why a
      standing sync branch stops the run** section carrying the measurement) and Sandra's manual
      (three things to know becomes four).

### TEST

- [x] `scripts/tests/sync-rules.tests.ps1`: +37 asserts across the two functions — the self-report trap,
      the seam prefix, ordinal matching, the whitespace-prefix throw, and on the report side the
      superset/partial/none rows plus the **vacuous-truth trap** (a branch whose file set could not be
      read must not read as superseded). 74 -> 111.
- [x] `scripts/tests/sync-main.tests.ps1`: +25 asserts on the script's behaviour — the refusal, that it
      lands *before* the mirror step, the `-DryRun` exemption, `-AllowStacking`, the independent-path row,
      a merged branch not counting, the seam prefix, and that no predecessor stays silent. 55 -> 80.
      `Add-PredecessorBranch` pushes the branch and **deletes it locally**, which is the state that
      matters: a predecessor pushed from another machine has no local ref at all.
- [x] `gh` is never reached over the network: the script does `Set-Location` to the fixture, whose origin
      is a local bare repo, so `gh pr list` has nothing to answer for and the two-part test falls onto its
      ancestry half — deterministic, offline, and covering the fallback rather than skipping it.
- [x] Lint gate green (check 18 `[skill-param]` caught the undocumented `-AllowStacking` and was the
      reason the skill page was updated before the PR, not after).
- [x] Full suite run.

#### One trap worth keeping, found by these tests

The four asserts that failed on the first run were **fixture** bugs, not parser bugs: in PowerShell the
**comma binds tighter than `+`**, so `'a' + "`t" + 'b', 'c' + "`t" + 'd'` inside `@()` does not build two
tab-separated lines — it flattens into the fragments. Every assert then measures a fixture that looks
right in the source and is not. The lines are single double-quoted strings with an embedded `` `t `` now,
and the reasoning sits above them.

### DEPLOY: `fix/sync-sees-its-own-standing-branches-v1`

`sync-main` now asks `origin` whether a sync branch from a previous run is still standing, and refuses
before the theme pull if one is. Measured in a consumer at four unmerged branches in seven days — the
newest a strict superset of all three, two byte-identical — with every one of those four runs green,
because nothing in the script had ever looked at its own previous output. The exclusion rule was correct
throughout; the gap was downstream of it.

The guard anchors on **your** `Get-ShopifySyncBranchPrefix`, uses the same two-part merged test as
`prune-merged` so a repo without `delete_branch_on_merge` is answered too, and prints a per-branch verdict
saying whether this run supersedes each predecessor or holds paths it does not. `-DryRun` reports without
refusing; `-AllowStacking` runs anyway, for the one case where a third party reverted a path on live in
between and the predecessor holds the only copy.

**Score:** 4

#### What makes this deploy extra special

It closes the failure mode this script was hardest to see: not a wrong answer, but four *right* answers
nobody had a reason to compare. The whole justification for stopping before the merge is a moment where
somebody looks — and four competing candidates for one set of edits is not that moment.

**Score:** 4

#### Pull Request

The pre-task sync reads its own standing branches, and refuses to stack a fifth
