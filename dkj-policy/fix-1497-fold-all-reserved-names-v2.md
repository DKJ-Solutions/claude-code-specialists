## fix/1497-fold-all-reserved-names-v2

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

A follow-up to #1498, which fixed #1497 and is merged. **That fix is correct and this branch does not
undo it** -- it takes the same defect one layer further in, to the mechanism that produced it, and closes
the one layout its test could not reach.

#### Why there is anything left to do

#1498 wired `Get-BranchFilePaths().ReservedNames` into the fold-all loop, exactly as the report proposed.
That works. What it leaves standing is the loop's own inline `Get-ChildItem` over the folder with the
`*.md` pattern -- and the exclusion it adds is the **sixth** copy of a guard that was extracted into
`Get-PerBranchDocumentRels` at #1335 precisely to stop being copied. That function's docstring predicts
this failure by name: *"a guard maintained in four copies is a guard that will hold in three."* The fold's
loop was the fifth caller nobody counted; #1498 makes it a sixth copy rather than a fifth conversion.

Verified before proposing it: after this change no `.Pattern` glob remains outside the lib, so the class
is closed rather than patched.

#### And one layout is still untested

#1498's fixture puts `CHANGELOG.md` **inside** the swept folder, which is this repo since #1437. There the
failure is loud -- the changelog is folded into itself and the run dies. The dangerous half is the other
layout: with the changelog at the repo root (every other fixture in that suite, and every consumer
predating #1437), the sweep folds `README.md`, deletes it, and **exits 0**. Nothing in the suite covered
that, and it is the case the issue itself called out as the one that "would not have failed loudly".

### CREATE

- [x] Route the fold-all discovery loop through `Get-PerBranchDocumentRels`, deleting the last
      hand-rolled sweep (`scripts/release/fold-changelog-entry.ps1`)
- [x] Keep #1498's measured evidence at that seam rather than replacing it -- it is the record of what the
      defect cost -- and add the third page it did not name: `CONTRIBUTING.md` declares `<branch>.md` off a
      backtick-quoted path placeholder and reads as filled, so it was in the same danger as the other two
- [x] Repair the stale count on `Get-PerBranchDocumentRels`: it said FOUR CALLERS and there are five. Named
      rather than counted now, because the number is the part that went stale
- [x] Mirror both files via `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `New-FoldFixture -CoLocated`: the co-location becomes a fixture switch instead of a hand-written
      re-patch of the seam. #1498's block un-patched `repo-config.ps1` itself, which was correct but put a
      second copy of the one substitution that knows that seam's literal shape in the same file that
      already owns it -- that block now passes the switch and the literal appears once
- [x] Its `-Commit` pathspec asserts are **kept** and renamed (`reserved commit:`), because they prove
      something no other block does: the reserved pages never enter the commit's own pathspec
- [x] New block, co-located: the fixture **proves itself** first -- all three pages asserted to declare a
      non-trunk branch and read as filled, with the real predicates -- so the name check is demonstrably
      the only thing saving them. Its changelog is built by **running the fold twice** rather than
      hand-written, because a hand-written stand-in is a guess that leaves the test green while
      reproducing nothing
- [x] New block, `reserved elsewhere`: the changelog OUTSIDE the swept folder -- the silent-success layout
      nothing covered. Pre-fix: `README.md is NOT deleted -- the silent-success case` fails while the run
      exits 0
- [x] Both reads guarded (`Test-Path` before `ReadAllText`): on an unfixed script the changelog is already
      gone by the fixture check, and an unguarded read aborts the suite instead of reporting
- [x] Asserted on the **source** too -- the sweep is `Get-PerBranchDocumentRels`, the inline glob is gone --
      so the fifth copy cannot be reintroduced with every behavioural assert still green
- [x] Measured in both directions against the pre-#1498 script: **226 pass / 0 fail** with the fix,
      **208 pass / 16 fail** without it
- [x] Full gate on the rebased branch: `check-plugin-integrity.ps1` + all suites

### DEPLOY: fix/1497-fold-all-reserved-names-v2

#1498 fixed #1497 by adding the `ReservedNames` exclusion to fold-all's own inline directory scan. This
replaces that scan with `Get-PerBranchDocumentRels` -- the shared listing that has applied the exclusion
since #1335 and that this loop simply never asked. Same behaviour, one guard instead of six, and the last
hand-rolled `*.md` sweep outside the lib is gone. Adds the regression case #1498 could not reach: with the
changelog outside the swept folder the fold deleted `README.md` and exited 0.

**Score:** 3

#### What makes this deploy extra special

The guard was never missing. It was extracted at #1335 with a docstring that names this failure in advance,
and the repair that shipped is the one that leaves that mechanism intact -- so the next widened glob finds
six copies to keep in step instead of five. This is the difference between fixing the instance and closing
the class, and it is checkable: no `.Pattern` glob remains outside the lib.

**Score:** 2

#### Pull Request

fold-all's sweep is the shared guarded listing, not a sixth copy of the guard

