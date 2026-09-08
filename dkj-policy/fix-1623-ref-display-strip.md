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
Whoever picks this up should measure it, not assume it."* Measured here, the class is **thirty-two
sites in the same four files**, and the extra fourteen are not a second subject:

| where | issue's count | measured | the fourteen it did not see |
|---|---|---|---|
| `scripts/release/ship-pr.ps1` | 11 | 15 | `$headNow` in the same sentence as a counted site; `$shipCycleRef` and `$shipProgressRel` in the two here-string refusals; the branch document path in the spent-branch note |
| `scripts/task/sync-main.ps1` | 6 | 20 | `$trunk` in nine progress sentences; four rows printing branch names read off `git ls-remote`; the sync-log line |
| `scripts/lib/remote-ahead-lib.ps1` | 1 | 1 | -- |
| `scripts/lib/worktree-lib.ps1` | (named via ship-pr:1177) | 1 | -- |

The issue read the scripts for `$branch`; the fourteen are the same name reached through a derived
variable or a second seam answer. **The sharpest of them is not `$branch` at all**: the three
four standing-branch rows in `sync-main.ps1` print names that came off `git ls-remote`, so whoever
pushed a branch matching the prefix chose that text -- and the operator reads those rows to decide
which PR to close.

**PR #1624 was open on the same two prose blocks while this branch was written, and it landed first.**
`fix/1617-ref-print-display-scope-reason` rewrites the `.DESCRIPTION` scope note and the
`Get-PasteableRef` strip comment -- the two paragraphs #1623's own subject makes stale. This branch
shrank its footprint there to the minimum rather than racing it: the reasoning is #1617's and was left
to #1617, and what this branch adds is the second function plus one appended implementation note. The
collision was filed as **#1630** before it could be discovered at the merge, with the resolution written
out -- and #1624 merged at 14:09, so this branch is the second one and carried it out:

- #1624's measured account stands verbatim -- the `--branch` exit codes, and the U+202E / U+200D link
  back to #1446. That is the accurate account of what git does and it is that issue's deliverable.
- Its **verdict** clause is what changed. *"The display axis is OPEN at the prose sites ... left open
  knowingly"* was true for a day and is not any more, so it now reads as the gap #1623 closed, and the
  narrow path it names (a branch created by hand, cloned or fetched) became the argument for why the
  strip **costs** nothing rather than for why the gap could be weighed and left.
- `git merge origin/main` reported exactly the two hunks #1630 predicted, in one file plus its two
  mirrors. Everything else auto-merged.

#### What was scoped out and filed

- **#1627** -- `sync-main.ps1` prints two paste-ready `gh` commands carrying a raw ref name #1594 never
  measured: `--base $trunk` and `--head $($s.Branch)`. That is the paste axis, so it wants a placeholder
  rather than a strip; stripping would hand the reader a command that runs with a different value than
  the one on screen.
- **#1629** -- the uncovered paths printed two lines under a row this branch strips come from another
  branch's tree, and that `git diff --name-only` sets no `core.quotePath`, unlike its neighbour.
- **#1630** -- the contradiction #1624 and this branch will leave in one `.DESCRIPTION` once both land.

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
      `Write-SyncPredecessorVerdict` and on the standing-branch line above it, at the twenty prose sites
- [x] the counts #1612 pinned two days earlier are moved rather than broken. That branch asserted
      **three** libs hand-type `[\p{Cc}\p{Cf}]` and stated the number in two more places, precisely
      because a stale count is what hid its own gap. This branch changes both halves of it, in
      opposite directions, and both are updated together:
      - the libs that **type** the class go from three to **two** -- `remote-ahead-lib.ps1` acquired a
        reason to load `ref-print-lib.ps1` for its own sake, and a private copy behind a loaded lib is
        pure drift surface. `pr-issues-lib.ps1` keeps its own, and the reason is written at the line:
        nothing there has a caller's reason to take the dependency;
      - the consoles this workflow prints somebody else's words to go from three to **four** -- the
        prose ref-name sites are the new entry, and #1623 was filed as the third counter-example to the
        very sentence that list replaced.
      The assert now pins WHICH libs carry it rather than how many, since the name is the part a reader
      can act on.
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
- [x] the ordering hazard this branch walked into is pinned: every display variable's FIRST mention
      outside a comment must be its own assignment. Both scripts run under `Set-StrictMode -Version
      Latest`, where reading an unassigned variable **throws** rather than printing nothing -- so
      `$branchShown` placed one line below its first use killed the whole run and cost 50 asserts in
      `sync-main.tests.ps1`. `ship-pr.ps1` has no suite at all, which is why the assert covers it too.
      The obvious index-comparison spelling of that assert does **not** catch it (the earlier use is
      inside a string, so it has no space after the name and the assignment sorts first); the shipped
      one reads line by line, and was verified by re-breaking the ordering and watching it go red.
- [x] full lint + test gate green

### DEPLOY: fix/1623-ref-display-strip

A branch name this workflow prints in a sentence can no longer read as a different branch. `git
check-ref-format` enforces `\p{Cc}` and **accepts** `\p{Cf}`, so a branch carrying U+202E, U+200B,
U+200D or U+2066 is creatable, checkout-able and returned verbatim by `git rev-parse` -- and
thirty-two printed sentences across `ship-pr.ps1`, `sync-main.ps1`, `remote-ahead-lib.ps1` and
`worktree-lib.ps1` put that name straight into a console. `Get-DisplayRef`, one definition in
`ref-print-lib.ps1`, now replaces every control and format character with a space, collapses the
runs and trims; the words stay, because a reader standing on that branch has to recognise it. The
paste axis is unchanged and stays distinct: a command gets a placeholder, a sentence gets a strip.

Two of the thirty-two are worth naming on their own. `ship-pr.ps1`'s go-ahead line is the one line
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

