# Development cycle: `fix/settings-json-trailing-newline-v1` · 20260826-120435

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `##` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `###` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `## PLAN`** -- everything between the H1 and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `###`
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

## PLAN

### Why this is a branch and not a revert

The change was already in the working tree when the assignment arrived: `claude plugin install` wrote it
while installing `contributing-davekjohn` into this checkout. So the only decision was whether to keep the
newline or revert it, and keeping it is correct -- a file that ends without one is the defect, not the fix.

## CREATE

- [x] Keep the trailing newline `claude plugin install` added to `.claude/settings.json`. No other edit to
      the file: the diff is one line, and the only byte that changes is at the end of the last one.

## TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` reports 0 errors.
- [x] Every suite in `scripts/tests/` passes.
- [x] `git diff main` touches exactly one file besides this branch's own development-cycle
      document, and exactly one line in it.

## DEPLOY: `fix/settings-json-trailing-newline-v1`

`.claude/settings.json` did not end with a newline. Installing `contributing-davekjohn` into this checkout
rewrote the file and added one, which is the only reason anybody noticed: it surfaced as a one-line diff on
`main` that nobody had authored.

**The newline is kept rather than reverted, and that is the whole change.** A text file ending without one
is the defect: any tool that appends to it, and any diff that touches its last line, reports a change to a
line nobody edited. Reverting would have restored a file that produces a phantom diff the next time a
plugin is installed here -- and this repo consumes its own plugins, so that is a recurring event rather
than a hypothetical one.

**Score:** 1

### What makes this deploy extra special

N/A -- `.claude/settings.json` is this checkout's own harness config. It is not plugin payload, it ships in
no release, and no consumer of the specialists plugins ever reads it.

**Score:** N/A

### Pull Request

settings.json ends with a newline
