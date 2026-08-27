## Development cycle: `feat/ship-in-the-background-by-default-v1` · 20260827-161426

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

#### What this branch is, and what it is deliberately not

Issue [#985](https://github.com/DaveKJohn/claude-code-specialists/issues/985) asks that a session stop
holding itself open for the length of `lint-en-tests` -- 11m48s on PR #980, against a local run of the
same suites minutes earlier at 292s. The merge genuinely cannot move before that check is green
(ruleset `main-ci-gate`, enforcement `active`), so the subject is the hand-off, not the wait.

**Two things were checked against the tree before this was scoped, and both changed the shape.**

1. The issue's own preferred shape -- "`session-status` would need to surface *PR #N is green and
   unmerged*" -- names a script that no longer exists. `scripts/task/session-status.ps1` was deleted
   from `main` at 15:03 CEST on August 27, 2026 (commit `94fc1c53`, PR #984, resolving
   [#957](https://github.com/DaveKJohn/claude-code-specialists/issues/957)); #985 was filed at 15:08
   CEST, five minutes later. Third inbound pattern: the proposed repair names a mechanism that is not
   there.
2. The subject already has a measured answer #985 does not list. `worktree-lane.ps1` (August 23, 2026)
   was built for this exact bill -- median 8m 01s over 65 blocking runs, 9h 45m per week at 73 PRs --
   and concluded *the worktree is where you build, the primary checkout is where you ship*. On
   August 27 `ship-pr` step 4's two merge gates were repointed at `refs/heads/<branch>`
   ([#970](https://github.com/DaveKJohn/claude-code-specialists/issues/970)) **specifically** so a
   backgrounded ship survives the session moving on, and `DEVELOPMENT-portable.md` already speaks of
   "any repo that ships from the background".

**So the mechanism is complete and the gap is that nothing declares it the default.** Backgrounding is
written down everywhere as a *hazard window that was hardened against*, never as the move to make --
and the one thing that makes it unsafe, step 5's `git checkout main`, has an answer (a lane) that
nobody is reminded of at the moment it matters.

**Scope, chosen by Dave on August 27, 2026** out of three: the rules plus one printed line. Not the
green-and-unmerged reporter (it would re-add, five minutes later, half of what #984 deliberately
removed) and not a detached merge watcher (it would fold onto the trunk with nobody reading the
output). Both were named and declined rather than overlooked; neither is filed, because #985 stays
open as their home if the smallest shape turns out not to be enough.

#### The one condition, because it is what makes this safe rather than merely faster

`ship-pr` step 5 runs `git checkout main` in the tree it was started from. So backgrounding the ship
is only safe while the session's *next* move is one of two things: open the next branch as a **lane**
(`worktree-lane.ps1 -Name`), or stop. Anything else in the primary checkout has HEAD pulled out from
under it. That condition travels with the default in every place the default is written.

### CREATE

- [x] `ship-pr.ps1` says it at the wait -- one printed line at step 3 naming the hand-off and its one
      condition, plus the comment that records why (#985) and why the script itself is unchanged
      otherwise. Mirror the plugin copy byte-for-byte (the shared-scripts drift lint).
- [x] The portable half: the `ship-pr` skill states backgrounding as the default, the `worktree-lane`
      skill states the lane as its other half, and `CONTRIBUTING-portable.md` section 4 carries the
      one-paragraph rule. Portable first -- this is a way of working, so the plugin is its home.
- [x] The repo's own halves: `contributing-davekjohn/CONTRIBUTING.md`'s PULL REQUEST step, and Derek's
      lens bullet that currently describes the hazard.
- [~] Deliberately NOT Chris's always-loaded lens: the close-out rule already forbids reporting an
      in-flight ship as an open point, and growing an always-on document to restate it is the cost
      Nolan measures. Record the decision here rather than making it twice.

### TEST

- [x] `check-plugin-integrity.ps1` clean -- 0 errors across all 30 checks, 291 links and 157 parses.
- [x] The two `ship-pr.ps1` copies are byte-identical (`Get-FileHash`), the file parses, and it stays
      pure ASCII.
- [x] Suites: **94 passed, 1 failed**, and the failure is pre-existing and not this branch's.
      `internal-note.tests.ps1` fails on `[FAIL] and the run warns about it out loud` -- the console-
      wrapping assert of [#959](https://github.com/DaveKJohn/claude-code-specialists/issues/959), open,
      green in CI, and reproduced here at a 300-column buffer. Nothing in this diff reaches that file,
      which is why `-SkipTests` is the right valve rather than a repair on this branch. Noting it because
      #985's own body names it: it is the evidence that the local run is the less reliable half of the
      pair, which is the argument this branch rests on.
- [~] No new suite. The script change is three `Write-Host` lines and a comment at a point no suite
      reaches -- `ship-pr.ps1` drives live git/gh and carries a documented test gap for exactly that,
      and a test asserting the text of an advisory line would pin the wording rather than the behaviour.
      Named as a gap, per the honesty rule, rather than covered for the look of it.
- [x] The three printed lines carry no issue number: a consumer reads that output, and the provenance
      belongs in the comment above it. Checked that no doc holds a captured sample of the wait output
      that this would drift from (`expected-output` check 15 had nothing to say either).

### DEPLOY: `feat/ship-in-the-background-by-default-v1`

Shipping a branch no longer costs the session the length of CI. `ship-pr.ps1` is started as a background
command and the session carries straight on -- the merge cannot move before `lint-en-tests` is green
whichever way the script runs, so a foreground wait only ever bought a second look at a result
`open-pr`'s own gates had given minutes earlier. Measured on PR #980 the same day: `lint-en-tests` at
11m48s against the same suites locally at 292s, and over 65 blocking runs a median CI leg of 8m 01s --
9h 45m a week at 73 merged PRs. Nothing about the wait itself changes, and no ruleset is touched: what
changes is who holds the session open while it runs.

**The condition travels with the default everywhere it is written**, because the invitation alone is
unsafe. Step 5 runs `git checkout main` in the tree the script was started from, so the next move after
backgrounding a ship is either a lane -- `worktree-lane.ps1 -Name`, the worktree is where you build and
the primary checkout is where you ship -- or nothing at all. `ship-pr` now prints both at the one moment
the reader is about to need them: three lines as the wait begins, naming the hand-off, the lane and the
`git checkout main` that makes it necessary. The rule itself is in the `ship-pr` and `worktree-lane`
skills, in `CONTRIBUTING-portable.md` section 4, in this repo's own PULL REQUEST step 2.4 and in Derek's
lens, where the same window had been documented as a hazard to harden against rather than as the move to
make.

Two larger shapes were named and declined rather than overlooked, and #985 stays open as their home: a
green-and-unmerged reporter at session start, which would have re-added half of the `session-status`
reporter #957 removed on purpose five minutes before #985 was filed; and a detached watcher that merges
when the check passes, which would put the merge and the fold -- a commit landing directly on `main`
under a named exception -- behind a process nobody is reading.

**Score:** 4

#### What makes this deploy extra special

Every consumer of this workflow pays this bill, and until now the workflow's own documentation told them
to pay it: backgrounding appears throughout the portable pages as a *hazard window that the gates were
hardened against*, never as the move to make, so a reader following the pages sat through CI on every
PR. The measurement is the part that travels -- a median 8m 01s CI leg is 9h 45m a week at this repo's
merge rate, and a consumer merging a tenth as often still loses an hour. The condition travels with it,
which is what makes this shippable rather than merely encouraging: `worktree-lane` already existed and
already carried the same measurement, and the two skills now point at each other as two halves of one
default instead of describing the same window from opposite sides.

It also closes a smaller gap the issue itself walked into. #985 proposed leaning on `session-status`,
which had been deleted from `main` five minutes before it was filed -- so the report a consumer would
read as the plan named a script no longer in the tree. Reading the two declined shapes beside the one
that shipped is what a consumer needs in order not to build the reporter again.

**Score:** 3

#### Pull Request

Backgrounding the ship is the default, and ship-pr says so at the wait
