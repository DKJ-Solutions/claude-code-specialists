## Development: `fix/branch-doc-per-branch-path-v1` · 20260902-232031

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

Issue #1255. Every branch wrote one shared `contributing-davekjohn/development.md`, so every merge to
`main` put that branch's copy on the trunk and left **every other open PR conflicting on it**. Since a
conflicting PR gets no check suite at all (#1247), the loop closed on itself: conflict -> no CI -> cannot
merge -> stays open -> next merge conflicts it again.

#### What was measured, September 2-3, 2026

| source of conflict | open branches hit | nature |
|---|---|---|
| `contributing-davekjohn/development.md` | **7 of 7** | pure workflow bookkeeping, no work in it |
| `CHANGELOG.md` | 3 of 7 | genuine -- two branches edit it deliberately |
| code, lenses, tests | 4 of 7 | genuine overlapping work |

One path caused 100% of them and carried none of the work. Eleven hand-made reconciliation merges appeared
on `main` in two days (3 on September 1, 8 on September 2) where the preceding weeks had none -- the
trigger being cadence: CI runs stayed at ~15 minutes while runs per day went 11 -> 46 -> 47, so almost every
CI wait now contains somebody else's merge.

#### The reasoning this reverses, and the half of it that still stands

August 23, 2026 retired the per-branch filename with: *"it cannot collide -- git already tracks this file
per branch, so each branch carries its own version of the same path and a checkout swaps them."* True of a
**checkout**, false of a **merge**: git tracking one path per branch is exactly what makes two versions of
it conflict when either lands. The rest of that sentence -- *"it cost a repo root that filled up with other
people's work"* -- still stands, and is answered by WHERE these go rather than by arguing with it: not the
repo root, but one directory the fold empties as each branch lands, so it lists exactly the live branches.

### CREATE

- [x] `Get-BranchFileWriterPath -Branch` composes `contributing-davekjohn/development/<safe>.md`, in one
      place, from branch-info's own `SafeName` rather than a second substitution.
- [x] `Resolve-BranchFilePath` takes `-Branch`, puts that file first, then **enumerates the directory** --
      which is what lets the fold, running on the trunk, find a document named after a branch this checkout
      was never on. Enumeration is Tree-arm only: the `-Reader` contract takes one path and returns text.
- [x] The shared `development.md` joins the names that are READ and is never written again -- the same
      "recognise N names, write one" rule the previous five renames used, so no branch in flight is
      stranded. Demonstrated by this branch: it was cut before the change, its document is still at the
      shared name, and the resolver still finds it.
- [x] `new-branch` writes the per-branch file, and sweeps an **inherited** document belonging to another
      branch -- removed when committed there, kept and named when it holds uncommitted work. That rule
      already existed; the per-branch name moved it one file over rather than removing the need for it.
- [x] `Test-IsBranchFilePath` replaces three ad-hoc "is this a branch document?" lists in the lint that had
      drifted to different subsets of the same table, and that a directory cannot be expressed in.
- [x] `ship-pr` and `check-branch-entry` pass `-Branch` explicitly: neither can guess it (a commit is not a
      checkout; a `pull_request` checkout is a detached merge commit).
- [x] The link base follows the file down a level. The scaffolder already had the "entry lands in a
      different directory" branch and it had never been reachable -- pointing `EntryDirRel` at the
      document's own directory is the whole repair, and the guidance it prints was already correct.

#### What this does NOT do

It does not touch the genuine conflicts -- code, lenses, a changelog two branches both edit. Those are real
overlapping work and no path scheme removes them. What is gone is the one collision that carried no work.

### TEST

- [x] All 58 suites pass in the lane, and the lint gate reports 0 findings.
- [x] `new-branch`: the stacked cases got new asserts -- the parent's committed document is **gone** from
      the child rather than left beside it, exactly one document in the directory, and the uncommitted
      parent is still kept and named.
- [x] `entry-scaffold`: the link fixtures moved one level deeper with the file, which is the assertion that
      the suggester's base actually followed it.
- [x] The migration is exercised by this branch itself rather than only by a fixture.

### DEPLOY: `fix/branch-doc-per-branch-path-v1`

The branch's development document gets a path of its own: `contributing-davekjohn/development/<branch>.md`
instead of the one `development.md` every branch shared. Two branches can no longer write the same path, so
one branch landing on `main` no longer leaves every other open PR conflicting.

That conflict was not occasional. Measured across the open branches on September 2, 2026, the shared
document accounted for **7 of 7** of them while all genuine code overlap together accounted for 4 -- and it
carried none of the work, only the workflow's own bookkeeping. It compounds with #1247, because a
conflicting PR gets no check suite at all: no CI means it cannot merge, staying open means the next merge
conflicts it again. Eleven hand-made `Merge branch 'main' into ...` commits landed on the trunk in two days
where the weeks before had none.

Nothing is stranded by the move. The shared name joins the names the resolver still READS -- the same rule
the five earlier renames of this document used -- so a branch already open keeps working in the file it has,
and only new branches get their own. The fold empties the directory as each branch lands, so what is in it
is the list of live branches.

**Score:** 4

#### What makes this deploy extra special

Every script this touches is mirrored into `contributing-davekjohn`, so this reaches every consumer running
the workflow -- and the defect is not this repo's. Any repo where two PRs are open at once has it; ours
merely merges often enough, at ~15 minutes of CI per PR, to hit it several times a day. A consumer adopting
the update gets the new path for new branches and no migration to perform, because the old name is still
read.

One reversal is worth naming for anyone who read the old reasoning: this document's own source said a
per-branch filename "was solving a problem version control had already solved". It was solving a different
one. Git's per-branch tracking is what keeps two branches apart in a checkout and what makes them collide
in a merge, and only the second matters to a PR.

**Score:** 4

#### Pull Request

The branch document gets a path of its own, so two branches never collide on it
