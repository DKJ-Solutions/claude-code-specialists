## Development: `fix/contributing-page-points-at-the-release-list-v1` · 20260830-113211

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

Inbound [#1127](https://github.com/DaveKJohn/claude-code-specialists/issues/1127): one `-Apply` run of
`adopt-workflow-folder` writes two pages that contradict each other about where the release list lives.
`CONTRIBUTING.md` says `releases/README.md` **IS** the list; `releases/README.md`, written minutes later
by the same run, says in bold that it is not.

- [x] Verify the symptom against the tree -- the six inbound checks, not just the quote.
- [x] Establish which of the two sentences is the wrong one, from the script's own model rather than
      from the report's word for it.

### CREATE

- [x] Rewrite the `releases/README.md` bullet in the `CONTRIBUTING.md` scaffold
      (`scripts/task/adopt-workflow-folder.ps1`) so it points at the list instead of claiming to be it.
- [x] Regenerate the plugin mirror (`scripts/sync/build-shared-scripts.ps1`).

### TEST

- [x] `check-plugin-integrity.ps1` + every suite green (the shared-scripts drift lint is the one that
      would catch a mirror left behind).

### DEPLOY: `fix/contributing-page-points-at-the-release-list-v1`

The scaffolded `contributing-davekjohn/CONTRIBUTING.md` no longer claims that `releases/README.md` is the
release list. It now names the list where it actually lives -- `releases/history.md`, beside it -- says
that file is the one document the scaffold deliberately does not write, and states the consequence
outright: a row added by hand to `releases/README.md` is a row the cut will never see.

The verb was simply true until the list moved (#786/#885); the parenthetical `(at <path>)` bolted on
afterwards was doing a correction's work inside a sentence that still said the opposite. The script's
own header, its comment at line 122 and the sibling page it writes had all followed the move -- this one
bullet had not.

**Score:** 2

#### What makes this deploy extra special

A consumer scaffolding the workflow folder reads `CONTRIBUTING.md` as the page that holds the rules, and
stopping there was enough to send their release rows into a file `cut-release` never reads -- leaving
`history.md` empty while looking maintained, and the cut warning about a path the reader had been told
was the wrong one. Nothing refused, which is what made it worth repairing.

**Score:** 3

#### Pull Request

the scaffolded CONTRIBUTING page points at the release list instead of claiming to be it
