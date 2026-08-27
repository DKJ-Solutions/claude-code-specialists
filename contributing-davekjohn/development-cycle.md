## Development cycle: `fix/ship-gates-read-pr-commit-v1` · 20260827-120913

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

ship-pr's step-list gate and DEPLOY lock read the cycle document from the WORKING TREE, so a checkout
that moved during the CI wait is what gets gated ([#970](https://github.com/DaveKJohn/claude-code-specialists/issues/970)).
Both must read the document belonging to the PR they are shipping -- which is the shipping branch's own
commit, `refs/heads/<branch>`.

#### Why the reported instance is not the dangerous one

It failed safe: an unrelated branch's open step refused a merge whose own branch had none. Reverse the two
documents -- the shipping PR carries an unresolved step, the checkout has since moved to a branch whose
steps are all ticked -- and the gate PASSES on someone else's document and merges. A gate with no `-Force`
satisfied by a file the PR does not contain reports the requirement as met while nothing checked it.

#### The remedy the report deliberately did not choose

Two shapes were on the table: resolve the document from the PR's head ref, or refuse when `HEAD` has moved
since the run started. This branch takes the first and declines the second: the report itself names a
backgrounded ship beside the next piece of work as "the ordinary shape of that window", so a refusal would
break the ordinary case in order to protect it. `refs/heads/<branch>` is provably what merges -- step 1's
`open-pr.ps1` pushes that branch on every path through the script, fresh PR and resumed PR alike -- and it
needs no network, which matters in a gate that must not refuse because a token expired.

#### The path must be resolved against the same tree, not merely read out of it

`Resolve-BranchFilePath` decides WHICH of seven candidate names holds this branch's work by reading each
one, so resolving against the working tree and then reading the answer out of a commit is the same class of
mismatch this issue is about -- and it fails in the dangerous direction: the resolver names a path the
shipping branch does not have, `git show` fails, and the gate reads that as "absent" and stays silent.

### CREATE

- [x] `Resolve-BranchFilePath` gains a `-Reader` parameter set, so one resolver answers for any tree
- [x] a shared `Get-GitFileTextAtRef` in native-capture-lib: one blob, decoded as UTF-8, `$null` when absent
- [x] ship-pr's two step-4 gates resolve AND read through that reader over `refs/heads/$branch`
- [x] the mirrors rebuilt, so a consumer runs the same script
- [x] the tests: the resolver's new arm, and the git read against a real commit
- [x] the docs that state what the gate reads name the commit rather than the working copy

#### The eighth PowerShell trap, met while writing this

A callback handed to a function reads THAT function's variables: PowerShell resolves a plain scriptblock's
names dynamically at the point of invocation, and names are case-insensitive. A reader saying `$repoRoot`
therefore binds `Resolve-BranchFilePath`'s own `$RepoRoot` -- which on the `-Reader` arm is declared and
**empty**. Measured rather than reasoned about: the block returned `[]` inside the function and
`[C:\the\real\root]` under a name the callee does not have. It then fails quietly one layer down, because
`git -C ''` is skipped rather than refused. The captured variables carry this script's own prefix as a
result, and the trap is written into the system-administration manual's list, which is now eight.

### TEST

- [x] `scripts/tests/native-capture.tests.ps1` -- 39 asserts, 0 fail. Eleven of them are new and run against
      a real fixture repository rather than a mock, because every property under test is git's: the committed
      text with a non-ASCII character intact, absent versus empty as two different answers, git's own
      `fatal:` line staying out of the document, a slashed branch name resolving as a ref, and the
      divergence itself -- the working tree overwritten and a second branch checked out, with the shipping
      ref still answering its own commit.
- [x] `scripts/tests/entry-scaffold.tests.ps1` -- 552 asserts, 0 fail, five of them new: the reader arm
      resolving to a name the on-disk fixture would NOT have chosen (asserted beside the tree arm, so the two
      have to genuinely disagree), one read per candidate though both loops ask, an empty document counting
      as present, and `-RepoRoot` with `-Reader` refused rather than silently resolved.
- [x] The full gate: `check-plugin-integrity.ps1` 0 errors over 28 checks, and all 53 suites green in 53s.
- [x] End to end on this branch's own state, which happened to be the exact shape under repair: the commit
      held the parked scaffold TODO while the working tree held six written steps, and the wired-up gate read
      1 open step from `refs/heads/fix/ship-gates-read-pr-commit-v1` where the old read would have found 6.
- [~] A `ship-pr` suite -- dropped: there is none, and this branch does not build one. `ship-pr.ps1` opens a
      PR, waits on live CI and merges, so covering it means a gh fake and a fixture remote; the 15 lines of
      glue this change adds there sit on top of two libs that are now covered assert by assert. Stated as a
      gap rather than papered over: the gates' WIRING is proven by the run above and by nothing automated.

### DEPLOY: `fix/ship-gates-read-pr-commit-v1`

`ship-pr`'s two gates before the merge -- the step-list gate and the DEPLOY lock -- now read the branch's
own commit, `refs/heads/<branch>`, instead of the file on disk. They read the checkout until now, on a
reasoning the script stated out loud: *"HEAD is still on the branch at this point -- step 5 is what moves to
main."* That is true of a foreground run and false of the shape this script invites, because it waits on CI.

The reason it needed doing is measured twice, and the second instance is what turned a written-down trap
into a defect. On August 20, 2026 two sessions shared one checkout. On August 27, 2026 it needed no second
session at all: one session backgrounded the ship and started the next piece of work while `lint-en-tests`
ran for 10m57s, and the gate refused PR #969 over `- [ ] TODO: the first step of this branch` -- the verbatim
scaffold TODO of a branch created *during* the wait, while PR #969's own document had no open step at all.
Both refusals were safe, and that is what made them easy to leave alone. **The same assumption fails the
other way in silence**: the shipping PR carries an unresolved step, the checkout has since moved to a branch
whose steps are all ticked, and the gate passes on somebody else's document and merges. A gate with no
`-Force`, satisfied by a file the PR does not contain, reports the requirement as met while nothing checked
it -- and the DEPLOY lock is the worse half of the pair, because the section it guards is what step 5 folds
verbatim into `CHANGELOG.md`.

Two things this deliberately does not do. **It does not refuse when `HEAD` has moved**, which was the other
shape on the table: the report itself names a backgrounded ship beside the next piece of work as the ordinary
shape of that window, so that guard would break the ordinary case in order to protect it -- and nothing
downstream needs the checkout to have stayed put, because step 5 checks out the trunk and folds from there
whichever branch it was standing on. **And it does not touch `open-pr`'s copy of the gate**, whose window is
the moment between reading and pushing rather than eleven minutes of CI; where an uncommitted tick gets past
it, the merge gate now catches it, which is the layering working rather than a hole.

For somebody maintaining this repo the gain is a merge gate that cannot be answered by the wrong file, plus
one behaviour worth knowing at the keyboard: a step ticked in the editor and never committed no longer gets
past it. Both messages have always said *"commit, and re-run"*, so the gate has caught up with what it asks.
It is a 3 rather than higher because it changes no chain and blocks nothing that was landing before -- but the
confusing half has now fired twice in eight days, and the silent half is on the merge path.

**Score:** 3

#### What makes this deploy extra special

The same repair, through a plugin update, and the exposure is identical: `ship-pr` waits on their CI too, and
a consumer with a long-running required check has the same eleven-minute window in which a session can start
the next branch. What arrives is `ship-pr.ps1` plus both libs it reads the commit through, so nothing has to
be configured -- and `Get-GitFileTextAtRef` is available to any other script of theirs that has to judge a
commit rather than a checkout.

The `ship-pr` skill page changes its claim rather than gaining a note: its section used to be titled *"The
step-list gate reads the WORKING TREE, and one thing breaks that"* and told the reader to compare
`git rev-parse --abbrev-ref HEAD` against the PR's head ref by hand when a refusal named a step they did not
recognise. That advice is now obsolete, and a page that keeps it would send someone hunting a mismatch the
script no longer has. The portable contributing page names the second read at the merge in the same movement.

A 3 there for the same reason as above, and no higher: nothing they have written stops working, and no
migration is asked of them.

**Score:** 3

#### Pull Request

The merge gates read the shipping branch's own commit, not the working tree

