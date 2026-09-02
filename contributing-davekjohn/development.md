## Development: `docs/ship-pr-titled-annotation-page-v1` · 20260902-204137

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

- [x] Confirm the gap from #1251: `Get-AuthoredFailureNote` (pr-issues-lib.ps1) relays only a
      *titled* failure annotation, and that contract on a consumer's workflows is stated only in that
      docstring -- `grep annotation plugins/` hits three `.ps1`, zero `.md`. Confirmed against the tree.
- [x] Decide the home (technical writer's call): the substance goes in the `ship-pr` skill, beside its
      existing "no required check" / "required check never appears" subsections, since that is where a
      consumer meets the relay in `ship-pr`'s own output; a short pointer with the one-line form goes in
      `CONTRIBUTING-portable.md` step 5, which is the first thing a consumer reads.

### CREATE

- [x] New subsection in `plugins/workflows/contributing-davekjohn/skills/ship-pr/SKILL.md`: what the
      relay reads (`::error title=X::Y`), why "titled" is the selection rule (the runner's own
      annotations are untitled), and that an untitled failure is silent on purpose.
- [x] Pointer paragraph in `plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md` step 5,
      linking the new subsection.

### TEST

- [x] Lint gate green (`check-plugin-integrity.ps1`, 0 errors) -- link-scan and plugin-link resolve the
      new within-plugin anchor link. No script changed, so no suite is in scope; the doc gates cover it.

### DEPLOY: `docs/ship-pr-titled-annotation-page-v1`

`ship-pr` merges past a failing *not-required* check and relays the sentence that check wrote about
itself -- but only a *titled* annotation (`echo "::error title=X::Y"`), because GitHub's Actions runner
writes its own with an empty title and "titled" is what tells an author's diagnosis from exit noise.
That is a real contract on a consumer's own workflows, and until now it lived only in
`Get-AuthoredFailureNote`'s docstring -- so a consumer whose advisory check goes red past `ship-pr`
saw a blank reason line and concluded the relay was broken. The `ship-pr` skill now has a subsection
stating what the relay reads, the one-line form that satisfies it, and that an untitled failure is
silent on purpose; `CONTRIBUTING-portable.md` step 5 carries a short pointer to it.

**Score:** 2

#### What makes this deploy extra special

This is the half of #1245's workflow repair that a consumer inherits: their advisory CI (a linter, a
coverage job) can now be made to explain its own red mark in `ship-pr`'s console by emitting one
`::error title=…::…` line, where before the reason was reachable only by opening the run.

**Score:** 2

#### Pull Request

the shipped PR docs say what ship-pr's failure-note relay reads, and that an untitled failure is silent on purpose

