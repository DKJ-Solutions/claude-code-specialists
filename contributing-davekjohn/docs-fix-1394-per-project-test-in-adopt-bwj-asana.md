## docs/fix-1394-per-project-test-in-adopt-bwj-asana

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

### CREATE

- [x] Rewrite `adopt-bwj-asana/SKILL.md` lines 118-123 to the per-project test #1386 established,
  matching step 5's current wording and keeping the link to step 5.
- [x] Grep `plugins/` for `one-workspace|does not cross` per the issue's own suggested check --
  found and fixed two more instances of the same superseded workspace-only claim: the "propose one
  value" paragraph earlier in the same `SKILL.md` file, and `README.md`'s `Get-AsanaProjectGid`
  paragraph. Also found the same reasoning in `asana-mirror.ps1`'s `Get-PrioScoreFromTask` docstring
  and corrected it too, since it draws the identical (superseded) conclusion from the workspace fact.
  `release-lib.ps1`'s hit was unrelated (CRLF, not Asana).

### TEST

- [x] Re-read each corrected paragraph against `WORKFLOW-portable.md` step 5's current text
  (lines 267-296) to confirm the per-project test is stated accurately and the `#1386` citation is
  correct.

### DEPLOY: docs/fix-1394-per-project-test-in-adopt-bwj-asana

Fixed [#1394](https://github.com/DaveKJohn/claude-code-specialists/issues/1394): `adopt-bwj-asana/SKILL.md`
still stated the one-workspace test for whether `Prio-Score` reaches a task, in a paragraph that cited
step 5 of `WORKFLOW-portable.md` as its authority -- a test that step 5 stopped making once
[#1386](https://github.com/DaveKJohn/claude-code-specialists/issues/1386) replaced it with the
per-project test (`custom_field_settings`), so the citation pointed a reader at the opposite claim. The
same superseded workspace-only reasoning was also present, unflagged by the issue but found via its own
suggested `grep -rn "one-workspace|does not cross" plugins/`, in the "propose one value" paragraph
earlier in the same file, in `README.md`'s `Get-AsanaProjectGid` entry, and in `asana-mirror.ps1`'s
`Get-PrioScoreFromTask` docstring -- all three corrected the same way, to the per-project test.

**Score:** 1

#### What makes this deploy extra special

Corrects a citation that pointed maintainers preparing a board for `Prio-Score`/`Github Issue`/`Github
Type` at the wrong test, but only in reference material read before configuring the seam -- nothing in
the shipped script behaviour changed.

**Score:** N/A

#### Pull Request

correct adopt-bwj-asana's stale one-workspace citation to match step 5's per-project test

