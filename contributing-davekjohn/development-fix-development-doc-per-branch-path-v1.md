## Development: `fix/development-doc-per-branch-path-v1` · 20260903-001413

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

Issue #1255. Every merge to `main` conflicted every other open PR on the single shared
`contributing-davekjohn/development.md`, and a conflicting PR gets no check suite at all -- so it could
never go green and never merge, which conflicted it again at the next merge.

#### The repair was chosen from three, and two were ruled out by measurement

The issue named three shapes and its reporter twice declined to pick one. Measured before choosing: a
simulated completed fold against all four open PRs cleared the two `add/add` cases and left the two
`modify/delete` cases conflicting, so the fold-side option does not work as stated. Detection-only reports
the loop without breaking it, by the issue's own comment. Per-branch naming is the only one that removes the
collision rather than reshaping it. Dave picked it.

#### And the reasoning being reversed was read first, not just the symptom

`entry-scaffold-lib.ps1` carried an explicit block arguing FOR the fixed name. Half of it is refuted --
"git already tracks this file per branch" is about checkout, not merge -- and half still holds: the
pre-August-2026 per-branch form cost a cluttered repo ROOT, which is about the directory and not the
filename, so these documents stay in the workflow's folder. A third trap, from `Test-BranchName`'s
docstring: that form coupled the fold to guessing the branch from the filename, which is what once banned a
`-v2` suffix. Not rebuilt -- the filename is a write convention and a read candidate, never the authority.

### CREATE

- [x] `entry-scaffold-lib.ps1` -- `Get-BranchFilePaths -Branch` names the document after the branch; `SharedFile` and `Pattern` added
- [x] `entry-scaffold-lib.ps1` -- `Resolve-BranchFilePath -Branch`, pattern discovery on the Tree arm, and an exact-branch pass so `-Branch` is authoritative
- [x] `entry-scaffold-lib.ps1` -- `Test-IsPerBranchDocumentPath`, one predicate for the two lint checks that each held a literal list
- [x] `new-branch.ps1` -- writes the per-branch name, with the shared name leading the legacy list so a branch already working in it is not split in half
- [x] `fold-changelog-entry.ps1` -- `-Branch` handed to the resolver (this runs on the trunk), and fold-all sweeps every per-branch document rather than one
- [x] `ship-pr.ps1` + `check-branch-entry.ps1` -- the two callers where HEAD is the wrong answer: the Reader arm resolves against another tree, and CI runs on a detached HEAD
- [x] `check-plugin-integrity.ps1` -- the scaffold gate (13b) sweeps the set instead of one fixed path, and both link/lifecycle checks gained the predicate
- [x] `check-plugin-integrity.ps1` -- the entry-heading gate (13) judges every branch document present, not only this branch's: a malformed heading in a leftover would otherwise reach `CHANGELOG.md` at ITS fold, and the run would report a clean pass over a document it never opened
- [x] `entry-scaffold.tests.ps1` -- its round trip derived the written path without a branch, so it asserted against the shared name while the writer had moved
- [x] The documents: `CLAUDE.md`, both CONTRIBUTING pages, both READMEs, `DEVELOPMENT-portable.md`, six skill pages, the PR template in all three places, four lenses, the adoption scaffold
- [x] The two documents stranded on the trunk by this very defect, migrated to their per-branch names rather than lost
- [~] Detection that a PR has silently lost CI -- dropped: it is the third option's half, and with the collision gone the cause it would report no longer occurs. Filed separately if it is still wanted for other causes.

### TEST

- [x] `scripts/tests/branch-document-path.tests.ps1` -- 24 asserts over the naming, the predicate, the resolver against a real tree, and the regression itself
- [x] `check-plugin-integrity.ps1` -- 0 errors; `[branch-template]` reports all three documents present instead of `absent`, and `[entry-heading]` reads 3 unfolded entries instead of 1
- [x] All suites via `open-pr`'s own gate, which is the authoritative run
- [x] `git merge-tree` against all four open PRs, before and after a simulated fold -- the measurement that chose the repair

#### One measurement was wrong before it was right, and it is recorded rather than quietly corrected

An ad-hoc `$LASTEXITCODE` loop used to check the suites mid-branch reported "0 failing" twice over a suite
that was red: `entry-scaffold.tests.ps1` died on a terminating exception before reaching its own `exit 1`,
and piping through `Out-String` left the exit code at 0. Six `[FAIL]` lines were in the output both times.
The repo's own gate (`Invoke-TestSuiteGate`) reads exit codes per child via `Start-Process` and was never
blind to it -- the defect was in the ad-hoc check, not in the gate, so nothing here needed repairing. Worth
recording anyway: this is the shape the repo keeps rediscovering, and the lesson is the one already written
down -- run the gate, do not reimplement it.

### DEPLOY: `fix/development-doc-per-branch-path-v1`

The branch's development document is named after its branch -- `contributing-davekjohn/development-<branch>.md`
-- so two branches never write the same path. It was one shared `development.md`, on the argument that git
tracks the file per branch and a checkout swaps them; that is true of checkout and says nothing about merge.
Every merge to `main` put the merged branch's copy on the trunk and left every other open PR conflicting on
it, and a conflicting PR has no merge ref, so the forge creates no check suite at all -- `lint-en-tests` could
never go green and the PR could never merge, which conflicted it again at the next merge. Measured on
September 2, 2026: all four open PRs conflicting, this document the only conflicting path in three of them.

**The fold was measured and is not the fix.** Simulating a completed fold against those same four PRs cleared
the two `add/add` cases and left the two `modify/delete` cases conflicting -- deleting the trunk copy changes
the conflict's shape, not its existence, which is why resolving a lap by merging `main` in never converged.
A `.gitattributes` merge strategy, which `DEVELOPMENT-portable.md` used to recommend as the cheap repair, was
declined for two reasons stated there: a forge computes mergeability with its own machinery, and a `union`
merge would produce a document declaring two branches.

**The trap the pre-August-2026 per-branch form set is not rebuilt.** That form made the fold guess the branch
from the filename, which is why a `-v2` suffix was once forbidden. Here the filename is a write convention and
a read candidate, never the authority: the resolver still identifies a document by the branch it DECLARES and
discovers candidates by pattern, so a renamed branch still resolves and `-v2` costs nothing. The half of the
old reasoning that was right is preserved too -- the documents stay in the workflow's folder beside
`CHANGELOG.md`, so the repo root is untouched and a relative link in a DEPLOY section still resolves.

Eight names were read before this change and ten are now: this branch's own, every other per-branch document
in the folder, then the shared name and the seven that came before it. `-Branch` is authoritative where a
caller names one, which is what stops a trunk carrying several documents from handing the fold somebody
else's entry -- the stranding hazard reported on the issue. Two silent gaps the naming would otherwise have
opened are closed with it: the scaffold gate read one fixed path and would have reported `absent` while a
stale document sat at a per-branch name, and two lint checks held literal LISTS of branch-document names that
a pattern cannot be added to. Fold-all sweeps every per-branch document rather than one, because a shared
path could only ever hold one and a trunk can now carry several.

**Score:** 4

#### What makes this deploy extra special

A consumer's branch documents change name, and every branch they have open on the day of the update keeps
working: the shared name is read and never written, so a document already holding work stays where it is and
is still found, folded and cleared. Nothing has to be migrated by hand and no branch is stranded. What a
consumer gains is the defect itself -- with more than one PR open, merges stop silently costing the others
their CI.

**Score:** 4

#### Pull Request

Name each branch's development document after its branch, so merges stop conflicting every other open PR
