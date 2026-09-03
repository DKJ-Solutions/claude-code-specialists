## Development: `fix/new-branch-writer-legacy-reach-matches-resolver-v1` · 20260903-085941

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

#### The defect (#1259)

`new-branch.ps1`'s writer decides which document a rerun keeps writing to via a local
`Get-BranchFileTargetRel`, fed a hand-written `-Legacy` list of **three** names
(`SharedFile`, `LegacyCycle`, `OlderCycle`). `Resolve-BranchFilePath` -- the reader every gate
and the fold share -- reaches **seven** legacy names: those three plus `PriorNameFile`
(`contributing-davekjohn/development-cycle.md`, pre-#963) and the pre-#886
`workflow-davekjohn/` set (`PriorFolderFile`, `PriorFolderLegacyCycle`,
`PriorFolderOlderCycle`).

A branch working in one of those four unrecognised names -- created before Aug 27 (`development-cycle.md`)
or before Aug 26 (`workflow-davekjohn/`) -- gets a second document written beside its work on any
idempotent rerun (`-Intent`, `-Park`). Nothing errors; the reader still finds the older file, so it
is quiet. Verified against `main` at `57df1e95` (post-#1261), where the writer list is exactly the
three names above.

#### Root cause and the fix

The two lists are maintained by hand in two files; #886 and #963 grew the reader's and left the
writer's behind. Fix closes the class: one ordered source, `Get-BranchFileLegacyNames -Kind`, in
`entry-scaffold-lib.ps1`, consumed by both `Resolve-BranchFilePath` and the writer call. The writer
keeps its own strict `Get-BranchFileTargetRel` (declares-**this**-branch only, never a reset or
foreign file) -- only its input list is shared. The resolver is still deliberately not called from the
writer (its fallback loops would keep a reset legacy name alive).

#### Out of scope

The resolver's *discovered* set (other `development-*.md` files in the folder, #1255) stays reader-only:
it needs a directory listing, the writer's question is "does an old name declare this exact branch",
and a renamed branch's old document declares its old name regardless. Not part of #1259.

### CREATE

- [x] `Get-BranchFileLegacyNames -Kind <File|Cycle|Deployment>` added to `entry-scaffold-lib.ps1`
      (root + `plugins/workflows/` mirror), returning the ordered legacy-candidate list
- [x] `Resolve-BranchFilePath` consumes it in `$candidates` in place of the seven inline entries
- [x] `new-branch.ps1` writer call passes it to `-Legacy`; the two stale comments ("two old names")
      refreshed (root + mirror)

### TEST

- [x] Regression coverage: a branch whose document sits at `development-cycle.md` and at a
      `workflow-davekjohn/` name, each declaring the branch -> the writer keeps that file, no second
      document
- [x] `check-plugin-integrity.ps1` + all suites green (as CI runs them); shared-scripts drift lint clean

### DEPLOY: `fix/new-branch-writer-legacy-reach-matches-resolver-v1`

`new-branch`'s writer now reaches the same legacy document names its reader does. It chose which file
a rerun keeps writing to from a three-name list (`development.md`, `branch/branch-cycle.md`,
`branch/branch-progress.md`), while `Resolve-BranchFilePath` -- shared by every gate and the fold --
reads four more: `development-cycle.md` (pre-#963) and the pre-#886 `workflow-davekjohn/` set. A
branch working in one of those four got a second, empty development document written beside its work
on any idempotent rerun (`-Intent`, `-Park`); nothing errored, because the reader still found the
older file. Both lists are now one ordered source, `Get-BranchFileLegacyNames`, so the next rename
cannot leave the writer behind again -- the drift that opened the gap when #886 and #963 grew the
reader alone.

**Score:** 2

#### What makes this deploy extra special

N/A -- internal workflow tooling. A consumer inherits the fix through a plugin update, but only a
consumer holding a branch created before the late-August document renames could ever have hit the
split, and the reader's wider reach kept even that non-destructive.

**Score:** N/A

#### Pull Request

new-branch's writer reaches the same legacy document names its resolver reads

