## fix/1623-ref-display-strip

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

#### The subject, and the recount this branch did before it wrote anything

#1623 reports that a branch name reaches eighteen prose print sites raw, and says in so many words
that the count is a measurement rather than a boundary: *"Not that 18 sites must each get a call...
Whoever picks this up should measure it, not assume it."* Measured here, the class is **thirty-one
sites in the same four files**, and the extra thirteen are not a second subject:

| where | issue's count | measured | the thirteen it did not see |
|---|---|---|---|
| `scripts/release/ship-pr.ps1` | 11 | 15 | `$headNow` in the same sentence as a counted site; `$shipCycleRef` and `$shipProgressRel` in the two here-string refusals; the branch document path in the spent-branch note |
| `scripts/task/sync-main.ps1` | 6 | 19 | `$trunk` in nine progress sentences; three `$r.Branch` rows from `git ls-remote`; the sync-log line |
| `scripts/lib/remote-ahead-lib.ps1` | 1 | 1 | -- |
| `scripts/lib/worktree-lib.ps1` | (named via ship-pr:1177) | 1 | -- |

The issue read the scripts for `$branch`; the thirteen are the same name reached through a derived
variable or a second seam answer. **The sharpest of them is not `$branch` at all**: the three
predecessor rows in `sync-main.ps1` print names that came off `git ls-remote`, so whoever pushed a
branch matching the prefix chose that text -- and the operator reads those rows to decide which PR to
close.

**What was scoped OUT, and filed instead.** `sync-main.ps1:1184` puts a raw `$trunk` into a printed,
paste-ready `gh pr create --base $trunk ...` -- that is #1594's axis (a command a reader is invited to
run) at a name #1594 did not cover, and it wants a placeholder rather than a strip. The uncovered
paths printed beside the predecessor rows come from a remote branch's tree and are the same class one
step further out. Both are filed rather than folded in here.

### CREATE

- [x] `Get-DisplayRef` in `scripts/lib/ref-print-lib.ps1` -- the one definition of the prose strip,
      beside the paste verdict that lib already owns, with the two axes stated as distinct
- [x] `Get-PasteableRef` reads its own note's strip from it, retiring the tree's second copy of the
      pattern -- and picking up the case that copy got wrong: an all-invisible name produced a note
      reading "The branch is:" with blanks after it
- [x] `remote-ahead-lib.ps1` strips `$BranchLabel`, the sharpest instance in the report -- it already
      stripped the commit subject two statements above and printed the label raw -- and reads the
      pattern from `ref-print-lib.ps1` instead of holding the second copy
- [x] `worktree-lib.ps1`'s `Get-TrunkReturnGoAheadLine` strips its own input, and the comment that
      argued "interpolated raw on purpose" is rewritten with what #1617 measured
- [x] `ship-pr.ps1`: `$branchShown` judged once beside the read, at the fifteen prose sites
- [x] `sync-main.ps1`: `$branchShown`, `$trunkShown` and a per-row strip in
      `Write-SyncPredecessorVerdict`, at the nineteen prose sites
- [x] the mirrors rebuilt via `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `ref-print-lib.tests.ps1`: a `Get-DisplayRef` block asserting git's acceptance of each of the
      four format characters as an explicit premise, the control class, the joiner-welding case, the
      all-invisible case, and that an ordinary name is returned untouched -- plus the structural half
      for the prose sites, in the same shape the paste sites already had
- [x] `remote-ahead-lib.tests.ps1`: a hostile branch label is reported and stripped, and the lib no
      longer carries its own copy of the pattern
- [x] `worktree-lib.tests.ps1`: the go-ahead line -- the one line the ship documents as safe to act
      on -- cannot print a name that reads as a different branch
- [x] the five fixtures that copy `remote-ahead-lib` or `worktree-lib` into a throwaway repo now copy
      `ref-print-lib` beside it, which the new dot-source needs
- [x] the two stale statements the suites carried -- *"prose is deliberately not a subject"* and the
      lib's own *"it does not sanitise for DISPLAY"* -- rewritten rather than left to be cited again
- [x] full lint + test gate green

### DEPLOY: fix/1623-ref-display-strip

A branch name this workflow prints in a sentence can no longer read as a different branch. `git
check-ref-format` enforces `\p{Cc}` and **accepts** `\p{Cf}`, so a branch carrying U+202E, U+200B,
U+200D or U+2066 is creatable, checkout-able and returned verbatim by `git rev-parse` -- and
thirty-one printed sentences across `ship-pr.ps1`, `sync-main.ps1`, `remote-ahead-lib.ps1` and
`worktree-lib.ps1` put that name straight into a console. `Get-DisplayRef`, one definition in
`ref-print-lib.ps1`, now replaces every control and format character with a space, collapses the
runs and trims; the words stay, because a reader standing on that branch has to recognise it. The
paste axis is unchanged and stays distinct: a command gets a placeholder, a sentence gets a strip.

Two of the thirty-one are worth naming on their own. `ship-pr.ps1`'s go-ahead line is the one line
the ship documents as safe to act on. And `sync-main.ps1`'s standing-predecessor rows print names
that came off `git ls-remote` -- text chosen by whoever pushed the branch, read by an operator
deciding which pull request to close.

The same movement retired the tree's second copy of the strip pattern: `remote-ahead-lib.ps1` had
been sanitising a commit subject and printing the branch label beside it raw, which is the sharpest
instance the report found.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing here reaches a subscriber. It changes what a console prints to whoever runs the
workflow's own scripts, and only for a branch name no ordinary repo has.

**Score:** N/A

#### Pull Request

A ref name printed as prose is stripped of control and format characters

