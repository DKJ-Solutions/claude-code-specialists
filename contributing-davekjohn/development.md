## Development: `fix/the-hook-rules-follow-their-own-entry-v1` · 20260828-143609

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

PR #1025 merged the entry without its content: open-pr commits the branch files only, and the manual edit was never staged. This branch carries the edit itself.

### CREATE

- [x] The two rules committed into `plugins/teams/team-alpha/manuals/05-15-manual.md` -- the edit
      itself, staged and committed by hand rather than left in the working tree.

### TEST

- [x] `git show HEAD:<manual>` carries both rules, which is the check that failed on #1025.

### DEPLOY: `fix/the-hook-rules-follow-their-own-entry-v1`

The two hook rules are now IN Sylvester's manual, where PR #1025's entry already said they were.
#1025 folded a changelog entry describing them while the edit sat uncommitted in the working tree:
`open-pr` commits the branch files -- the development document -- and nothing else, so a change made
outside them is pushed by nobody and merges as an entry with no content behind it. Nothing refused it,
because every gate reads that document rather than the diff. The lesson for the next branch is the
plain one: the author stages and commits their own work before `open-pr` runs, and the check is
`git show HEAD:<path>`, never the working tree.

**Score:** 3

#### What makes this deploy extra special

Without this the manual a consumer receives at the next release does not contain the rules this
repo's changelog says it gained -- the release notes would describe a page nobody can find.

**Score:** 3

#### Pull Request

The two hook rules land in Sylvester's manual, where PR #1025's entry already said they were
