## Development cycle: `docs/change-contributing-title-v1` · 20260826-164019

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

#### What this branch is

The one page in `contributing-davekjohn/` opens under a heading that names its POSITION in a stack --
`Contributing -- the contributing-davekjohn layer` -- rather than its subject. Retitle it, and check that
nothing was reaching for the old heading's anchor.

#### Where it was picked up

The branch and its PR ([#933](https://github.com/DaveKJohn/claude-code-specialists/pull/933)) were made by
hand, outside `new-branch.ps1` and `open-pr.ps1`, so this document did not exist and the `branch-entry` CI
gate refused the merge -- `lint-en-tests` and `claude-review` were already green. That refusal is the gate
working: it is the one of the four an author cannot skip by skipping the scripts. This document was
scaffolded onto the branch afterwards, which `new-branch.ps1` supports by design.

### CREATE

- [x] Retitle the H1 of `contributing-davekjohn/CONTRIBUTING.md`
- [x] Hold the new title against the handle used everywhere else -- it arrived as `DaveKjohn`, against
      `DaveKJohn` in 1530 places and nowhere else in the tree, so the capital was restored
- [x] Scaffold this document, so the branch declares what it does

### TEST

- [x] `grep -rn "contributing-davekjohn/CONTRIBUTING.md#"` across `.md`, `.ps1` and `.json`: no anchor link
      to the old heading anywhere, so the rename strands no reference
- [x] `grep -ro "DaveK[Jj]ohn" --include=*.md`: `DaveKjohn` reduced to zero occurrences
- [x] `check-plugin-integrity.ps1` + the suites, via `open-pr.ps1`
- [x] `check-branch-entry.ps1` on this branch, which is the check that refused the merge

### DEPLOY: `docs/change-contributing-title-v1` · 20260826-164019

The one page in `contributing-davekjohn/` opens under a new H1 -- **`Contributing as DaveKJohn`**, where it
read **`Contributing -- the contributing-davekjohn layer`**. The old heading described where the file SITS:
a layer over the two root documents. That is true, and it is the answer to a question a reader arrives with
only once they already know the page exists. The new one names the subject instead -- this is how work is
contributed in DaveKJohn's repos -- which is what the folder, the plugin and the page have each been about
since the folder's two pages merged into one on August 26, 2026
([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886)). The layering itself is not lost:
the page states it in its own opening paragraph, where it is prose a reader meets in context rather than a
heading standing in for a title.

**Nothing links to the old anchor**, checked across every `.md`, `.ps1` and `.json` in the tree, so the
rename strands no reference and needs no follow-up edit anywhere -- which is what makes a heading safe to
change at all in a repo whose lint gate scans for dead links.

**Score:** 1

#### What makes this deploy extra special

This page is the repo's own adopted copy, not plugin payload: the shipped document is
`plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md`, and it is untouched. No consumer
receives this heading, in this release or any other.

**Score:** N/A

#### Pull Request

Change title to 'Contributing as DaveKJohn'
