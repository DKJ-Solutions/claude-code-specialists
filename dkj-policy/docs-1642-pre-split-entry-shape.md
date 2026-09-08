## docs/1642-pre-split-entry-shape

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

#### What the report left open, and why it had to be answered first

Issue #1642 reported two comments in `../scripts/lib/entry-scaffold-lib.ps1` describing the same file
incompatibly, and said plainly what it had **not** established: which description the real
August-2026 file actually had. Both comments are the stated justification for live behaviour, so
repairing either one without that answer would have picked a winner by coin toss and left a citation
behind it. So the measurement came before the edit.

- [x] Read all four sites, not the two reported -- the claim also sits in the `NOR THE DECLARED
      BRANCH` block and in `cut-release-guardrail.tests.ps1`'s own comment.
- [x] Measure every pre-split root entry in this repo's history: opening heading level, and whether
      it carries a `**Branch:**` line.
- [x] Find what the `**Branch:**` shape actually belonged to, and whether the root scan could ever
      have read it.

### CREATE

- [x] Site A -- `Get-BranchFileDeclaredBranch`'s docstring: name the per-branch files, record the
      344/0/0 measurement, and keep the one justification that survives (the end-to-end anchor).
- [x] Site B -- the `NOR THE DECLARED BRANCH` block: same correction, and say why the near miss it
      describes is unaffected by it.
- [x] Site C -- `Test-BranchChangelogIsFilled`'s docstring: `AT AN ENTRY LEVEL` instead of `as an
      H2`, with the 334/10 split and the fact that this test accepts both.
- [x] Site D -- the fallback's test comment: the same shape correction.
- [x] Site E -- add the H3 assert, which pins 334 of the 344 real files and had none.
- [x] Mirror regenerated (`scripts/sync/build-shared-scripts.ps1`).
- [~] No behaviour change, so no code edit -- the report established that the code handles both
      shapes correctly and this branch's own measurement agrees.

### TEST

- [x] `cut-release-guardrail.tests.ps1` -- 108 asserts, including the new H3 one.
- [x] `entry-scaffold.tests.ps1` -- 760 asserts.
- [x] `shared-scripts.tests.ps1` -- 608 asserts, so the mirror is in sync.
- [x] Full lint gate and every suite, via `open-pr.ps1`.

### DEPLOY: docs/1642-pre-split-entry-shape

Four comments in `../scripts/lib/entry-scaffold-lib.ps1` and its guardrail suite described the
pre-split root changelog entry incompatibly -- an H2 title naming no branch in one place, an H1 title
with a `**Branch:**` line below it in the other -- and each was the stated reason a piece of live
behaviour survives. The history settles it: of the **344** pre-split root entries this repo has ever
had, **0** carry a `**Branch:**` line and **0** open with an H1 (334 open at H3, 10 at H2 in the flat
window of August 5-6, 2026). The `**Branch:**` shape was never a root entry at all -- it sat below the
H1 title of the pre-split **per-branch** files, `branch/branch-changelog.md` (`# Branch changelog`) and
`branch/branch-progress.md` -- and the release cut's root scan is non-recursive, so `branch/` was never
in its reach either. All four sites now name that file, cite the measurement, and keep the one
justification that survives it: the fallback's regex is anchored end to end, which is what makes it
safe to leave un-narrowed. `Test-BranchChangelogIsFilled`'s docstring reads `AT AN ENTRY LEVEL` rather
than `as an H2`, since it accepts both and both were written. Behaviour is unchanged -- the report had
already established the code handles each shape correctly, and this measurement agrees -- but the
guardrail suite gains the H3 assert it never had, which is the shape 334 of those 344 files actually
have.

The failure this prevents had not happened yet: a maintainer following the un-corrected comments would
conclude that a root entry declares its branch, therefore that the name test already answers for it,
therefore that the level test beside it is dead -- and removing it is exactly what would let the
release cut, whose guard is "no unfolded entry anywhere", cut straight over all 344.

**Score:** 2

#### What makes this deploy extra special

N/A. The corrected text travels to consumers in the `dkj-policy` mirror, but nothing a consumer runs
changes: this is comment prose and one added assert in the source repo's own suite.

**Score:** N/A

#### Pull Request

Name the legacy shape the '**Branch:**' fallback actually answers for
