## Development cycle: `fix/placeholder-tolerance-keeps-its-own-history-v1` · 20260827-200125

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

The rename in #886 rewrote the four historical strings in Get-PrDescriptionPlaceholderDefaults instead of appending, so the list now tolerates only paths a MIGRATED repo would have -- the one case needing no tolerance. Add the workflow-davekjohn forms back beside them, oldest first, written one last.

### CREATE

- [x] `scripts/lib/pr-body-lib.ps1`: the four pre-rename forms are back in
      `Get-PrDescriptionPlaceholderDefaults`, recovered verbatim from `8797f7a5^` rather than retyped,
      and placed by their real age -- after the folder-less string, before the `contributing-davekjohn`
      ones, so the written one is still last and `Get-PrTemplateCanonicalPlaceholder` needs no change.
- [x] Its docstring's own history line corrected. It said the entry path "moved under
      contributing-davekjohn/ on August 14, 2026", which is the rename rewriting the past as well: on
      August 14 that folder was named `workflow-davekjohn`. The rename is now its own dated step.
- [x] The four `contributing-davekjohn` forms for the retired filenames stay, and the docstring says
      why: no template ever carried one, and removing entries is the move this defect was made of.
- [x] `plugins/workflows/contributing-davekjohn/scripts/lib/pr-body-lib.ps1` held byte-identical.
- [x] `scripts/tests/pr-body.tests.ps1`: two new assert blocks -- the four forms by name, and the
      structural rule they are an instance of.

### TEST

The structural assert was proved to have teeth by re-running the defect: applying #886's substitution
to one entry turns the suite red on exactly the right three lines.

| run | result |
|---|---|
| after the repair | `OK: all 186 asserts passed.` |
| with one entry re-substituted the way #886 did it | `FAILS: 3 failed, 183 passed.` |

- [x] `pr-body.tests.ps1` green after the repair, red under the defect.
- [x] Both lib copies byte-identical, and the file is pure ASCII.
- [x] Full gate: `check-plugin-integrity.ps1` plus every suite.

#### What this branch did NOT do, and why it is worth saying

The issue reports that `scripts/tests/branch-info.tests.ps1` "keeps a deliberate copy of the list and
asserts exactly one hit", and that this is what caught the defect. That suite contains no placeholder
assert at all -- no copy of the list, no mention of a placeholder. The suite that does read the list is
`pr-body.tests.ps1`, and its asserts covered only the two pre-folder strings, which the rename never
touched. So nothing caught this: the defect was found in a consumer, and the assert that would have
caught it is added here rather than pointed at.

### DEPLOY: `fix/placeholder-tolerance-keeps-its-own-history-v1`

The list of PR-template placeholder lines `open-pr.ps1` recognises stops being a list of paths only a
migrated repo could have. `Get-PrDescriptionPlaceholderDefaults` is documented append-only -- "RECOGNISE
ALL, WRITE ONE" -- because a consumer's PR template is their file, and an unrecognised placeholder is a
PR body with no description at all. The rename in [#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886)
rewrote the four strings carrying the folder name instead of appending to them, which inverted the whole
purpose: a consumer who has not migrated is by definition still carrying `workflow-davekjohn` in their
template, so the four strings kept *for* them became the four that no longer matched them. Measured in
`smartwatchbanden` on the 4.20.0 update and before any migration: 0 matches out of 7. The pre-rename
forms are back beside the current ones, recovered from the rename commit's own parent so they are the
strings that were really shipped rather than a reconstruction.

Two things travel with it. The docstring's history line said the entry path moved under
`contributing-davekjohn/` on August 14, 2026 -- the rename had rewritten the prose too, and on that date
the folder was named `workflow-davekjohn`. The rename is now a dated step of its own, so the list's
shape and its explanation agree again. And `pr-body.tests.ps1` gains the assert nobody had: the four
forms by name, plus the structural rule behind them -- every entry naming the folder must exist under
*both* folder names, because a form present under one and absent under the other is a rewrite. That
second assert is what makes the next rename fail loudly instead of quietly, and it was verified by
re-applying the defect.

Closes [#952](https://github.com/DaveKJohn/claude-code-specialists/issues/952).

**Score:** 4

#### What makes this deploy extra special

If your PR template still says `workflow-davekjohn/...`, `open-pr` fills in your PR description again.
Between 4.20.0 and this version it did not: it warned and opened the PR with no description, because the
strings kept for exactly your case had been rewritten to the new folder name. Nothing to migrate --
adopting the new template remains optional, and both forms are recognised from here on.

**Score:** 4

#### Pull Request

The PR-placeholder tolerance list keeps the folder name each string was written with

