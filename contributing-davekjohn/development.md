## Development: `docs/portable-cycle-begins-at-the-issue-v1` · 20260830-094625

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

Restore step 1 NEW ISSUE / TASK in `CONTRIBUTING-portable.md`, fold `TICKETWORK-portable.md` into it, delete
that page and follow its four live references. Issue #1123.

#### The two decisions taken on the issue

**The `Claude` half is carried, and named as stated-not-owned.** Its rules ship with `team-alpha`, which a
repo can enable this workflow without — so a portable route that only pointed at a persona body would have a
step legible to nobody. The local page already made that call for the same reason.

**The two archived 4.5.0 documents are de-linked rather than repointed.** The dead-link check reads
`contributing-davekjohn/releases/` recursively, so the deletion has to be followed there; an archived note
keeps saying what was true on its day, and a label reading `TICKETWORK-portable.md` must not point at a page
that is not it.

#### The shape: a short step, and the rules as their own `##` section

The rules are 215 lines with `###` headings of their own. Nested under the step they would be `#####`; as a
top-level section below the cycle they keep their depth, and the page already works that way — `##
Significance` and `## Releases` are the expansions steps 2 and 6 point at.

### CREATE

- [x] `CONTRIBUTING-portable.md`: a new `### 1. New issue or task`, with `Human` and `Claude` as kinds
- [x] `CONTRIBUTING-portable.md`: renumber Branch→2 … Fold→6, including the two in-page back-references
- [x] `CONTRIBUTING-portable.md`: `TICKETWORK-portable.md`'s whole content in as `## Ticket work`, its own
      framing intact and its `#5-fold` anchor repointed
- [x] Delete `plugins/workflows/contributing-davekjohn/TICKETWORK-portable.md`
- [x] Plugin `README.md`: the pointer paragraph and the table row follow the content
- [x] `scripts/task/adopt-workflow-folder.ps1` + its mirror under `plugins/`: the scaffolded folder README
      stops promising a fourth page
- [x] `contributing-davekjohn/CONTRIBUTING.md` step 1: repoint at the merged section
- [x] De-link the two archived references in `releases/*/4.x/4.5.0.md`
- [x] `contributing-davekjohn/README.md`: this folder's own page said "four portable pages" — found by the
      copy-edit pass, not by a gate, since no check counts them

### TEST

- [x] `check-plugin-integrity.ps1` green — the dead-link and anchor scan is what judges this change
- [x] All suites green, the shared-scripts drift lint included (the mirrored script is edited in both copies)

### DEPLOY: `docs/portable-cycle-begins-at-the-issue-v1`

**The portable half of the cycle began at `new-branch`.** This repo's own page has opened at
`## 1. NEW ISSUE / TASK` since August 29, 2026 ([PR #1058](https://github.com/DaveKJohn/claude-code-specialists/pull/1058)),
so for a day the document every consumer reads described a cycle starting one step later than the cycle it
describes — and the step it was missing is the one that says where the work comes from.

`CONTRIBUTING-portable.md` now opens at `### 1. New issue or task`, with `Human` and `Claude` as **kinds
rather than sub-steps** — neither precedes the other, both end in one issue in the repo the branch will be
opened in — and Branch through Fold renumbered 2 to 6, in-page back-references included. It is the only step
that names no skill, and that is stated on the page: no script runs it, which is exactly why it was the step
the page went without.

**`TICKETWORK-portable.md` is gone, folded in whole** as `## Ticket work — the layer before the branch`,
which step 1's `Human` half points at. It had been a fourth portable page for three weeks, and what retired
it was reach rather than size: the cycle document never mentioned it once, and the plugin README framed it as
an optional extra — so a reader following the cycle end to end met neither the section nor the step it
belonged to. Nothing was dropped in the move; the ten rules keep their own headings one level down, and the
framing that makes them survivable (one repo, one day, rules rather than a format) travels with them.

Its four live references follow it: the plugin README's pointer paragraph and its table row, the folder
README both copies of `adopt-workflow-folder.ps1` scaffold, and this repo's own step 1. The two archived
`4.5.0` documents that linked to the file are **de-linked rather than repointed** — the dead-link scan reads
`releases/` recursively, and an archived note should keep saying what was true on its day rather than
pointing at a page whose name it does not carry.

**Score:** 2

#### What makes this deploy extra special

**A consumer's route no longer has a hole at the front.** The cycle they read starts where their work
actually starts, and the ticket-work rules are reachable from it instead of from a page the cycle never
named. Nothing to run and nothing to migrate: no script, gate or seam changed, and a repo where nothing
arrives from an upstream tracker skips that section exactly as it skipped the page.

**Score:** 3

#### Pull Request

The portable cycle begins where the local one does, and ticketwork moves into its first step
