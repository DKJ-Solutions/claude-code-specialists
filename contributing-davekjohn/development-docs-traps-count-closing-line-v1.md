## Development: `docs/traps-count-closing-line-v1` · 20260903-140122

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

Issue [#1302](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1302): the traps section
in `plugins/teams/team-alpha/manuals/05-15-manual.md` closes with "the general shape behind all seven"
while its heading and opening paragraph both say nine.

#### Verified before repairing, because the issue asked for it

The issue's own note warns that a neighbouring count in this file was mis-corrected once, so the bullets
were recounted rather than trusted: nine `- **` bullets sit between `## Nine PowerShell traps that
produce well-formed wrong output` and the next `##`. The opening paragraph's own arithmetic agrees --
"Eight are PowerShell's own; the last is the same class one layer out" is nine. So the heading and the
opening are right, the closing line is the single stale word, and the repair is one word.

### CREATE

- [x] Correct the closing line to "all nine" in `plugins/teams/team-alpha/manuals/05-15-manual.md`.
- [x] Sweep the repo for other copies of the sentence and for further stale counts in that file: one
      occurrence only. The remaining `all seven` hits are archived release notes and one unrelated
      sentence in `connectors/README.md`, all out of scope.

### TEST

- [x] `check-plugin-integrity.ps1` plus the full suite run, via the gate `open-pr.ps1` runs.

### DEPLOY: `docs/traps-count-closing-line-v1`

Sylvester's manual said "Nine PowerShell traps" in its heading and "All nine" in its opening line, then
closed the same section with "The general shape behind **all seven**" -- the sentence that carries the
lesson out of the section and into the next problem. The section grew from seven traps to nine and the
closing line was not carried along. The bullets were recounted rather than the heading trusted, because
the file has a neighbouring count that was mis-corrected once before; the count is nine, so the closing
line is the only wrong number and the repair is one word.

A wrong count misleads nobody about the traps themselves -- all nine are still there and still correct.
What it costs is trust in the section's own bookkeeping, which is exactly what a reader leans on when a
list is too long to check by eye.

Closes [#1302](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1302).

**Score:** 1

#### What makes this deploy extra special

N/A -- a portable manual reaches consumers by plugin update, but the correction changes no behaviour, no
rule and no instruction. A reader who never noticed the number loses nothing.

**Score:** N/A

#### Pull Request

Sylvester's manual: correct the traps section's closing count
