## docs/1757-rename-merge-retired-names

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### The finding (issue #1757)

A branch cut before the [#1698](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1698)
`dkj-team-*` -> `dkj-subagents-*` rename and merged after it gets half the rename for free: git's
rename detection moves the *files* cleanly, and says nothing about retired names written **inside**
the lines the branch adds. Measured landing PR #1733: six new files still named the retired plugins,
in comments, docstrings and an `agent_type` test fixture, and no gate saw it. What #1757 asks for is
one line, in the place a session looks when it merges `main` into a stale branch, plus the by-hand
one-liner to check. It explicitly rules out a sweep and a gate -- the naive reading over-counted
pre-existing text more than fiftyfold.

#### The layer decision

The issue floated three homes (the repo-citation section of `CLAUDE.md`, Sylvester's lens, Tessa's)
and left the choice open. Chosen instead: **Derek's `05-05-extension.md`, the "`main` moves under a
long branch" bullet in "Branch & repo hygiene"** -- because the issue's own "what would actually
help" describes that bullet verbatim ("the place a session looks when it merges `main` into a stale
branch"), and that bullet already carries the sibling notes (re-run the gates on the merged tree; the
conflict shape). It is cross-linked to Tessa's dead-name-sweep section, which is the mirror hazard
(that one over-corrects a dated citation; this one under-corrects). Kept out of always-on `CLAUDE.md`
on cost, and out of the shared source because the trigger -- a parked branch cut before *this repo's*
plugin rename -- is repo-specific.

### CREATE

- [x] Add the "rename-detected merge is silent about retired names in the lines it adds" paragraph to
  the "`main` moves under a long branch" bullet in `.claude/specialists/lenses/05-05-extension.md`,
  with the #1757 / #1733 / #1698 measurement, the "no gate catches it" reasons, the cross-link to
  Tessa #16, the by-hand one-liner, the "deliberately no gate" note, and the one live instance
  (`feat/plugin-version-overview-review-b`).

### TEST

- [x] `open-pr.ps1` runs `check-plugin-integrity.ps1` (dead-link / anchor scan included) and all
  suites on the merged tree.

### DEPLOY: docs/1757-rename-merge-retired-names

A session merging `main` into a branch whose base predates a repo-wide rename now has a one-line
warning, in the exact spot it would look, that git's rename detection moves the files but not the
retired names inside the lines the branch adds -- plus the by-hand `git diff | grep` one-liner to
catch them before they land on the trunk. Prevents a repeat of the near-miss on PR #1733, where six
new files citing retired plugin names were caught only by hand.

**Score:** 2

#### What makes this deploy extra special

N/A -- the note lives in a repo lens under `.claude/specialists/lenses/`, which does not travel to
consuming repos, and the trigger (a branch parked across `dkj-team-*` -> `dkj-subagents-*`) is
specific to the repo that ships the plugins. No subscriber of a consuming repo is reached.

**Score:** N/A

#### Pull Request

Warn that a rename-detected merge into a stale branch is silent about retired names in the lines it adds
