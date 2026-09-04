## docs/fix-1386-step5-per-project-not-workspace

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

Fix #1386: `WORKFLOW-portable.md` step 5 explains a self-filed ticket's missing `Prio-Score` with a
workspace boundary, but the field is measured (via `get_project`) to be gated per-project instead --
`GitHub - WH` and `GitHub - SWB` sit in the SAME workspace and still differ, because
`custom_field_settings` is what decides. Restate step 5 (and its echo in step 7) in per-project terms,
keeping the workspace fact but naming the actual test. Refines #1213 rather than duplicating it.

### CREATE

- [x] Rewrite step 5's workspace paragraphs to state the per-project `custom_field_settings` test, with
      the `GitHub - WH` / `GitHub - SWB` measurement as evidence.
- [x] Fix the matching claim in step 7 (`Get-AsanaProjectGid` "has to sit in the board's workspace") the
      same way.
- [~] Distinguish "no score" from "field not on this project" in the sweep's own log
      (`Get-PrioScoreFromTask` returning `$null` for both) -- issue #1386 marks this optional, and it
      needs a second Asana call (`get_project`) per run plus a script/test change beyond this issue's
      doc-only scope. Left as a possible follow-up rather than done here.
- [x] Whether to add `Github Issue`/`Github Type`/`Prio-Score` to the `GitHub - WH` project itself --
      #1386 names this explicitly as Dave's call in Asana, not this issue's or this branch's.

### TEST

- [x] Lint + tests green (`check-plugin-integrity.ps1`), then PR + merge + fold.

### DEPLOY: docs/fix-1386-step5-per-project-not-workspace

`WORKFLOW-portable.md` step 5 blamed a self-filed ticket's missing `Prio-Score` on a workspace
boundary; measured against the real BWJ boards the two boards sit in the SAME workspace and still
differ, because a custom field also has to be added to the project (`custom_field_settings`), not
merely defined in a reachable workspace. Step 5 and its echo in step 7 now name that per-project test
instead, with the `GitHub - WH` / `GitHub - SWB` measurement as evidence -- a refinement of #1213 rather
than a duplicate.

**Score:** 3 -- corrects a step that reads as safe when it silently is not: a maintainer following the
old text would conclude a same-workspace project is fine, exactly where `GitHub - WH` shows it is not.

#### What makes this deploy extra special

A BWJ store repo troubleshooting why its self-filed tickets never gain a prio label now gets the test
that actually explains it (is the field added to this project?) instead of one that predicts nothing
useful once workspaces already agree.

**Score:** 2

#### Pull Request

Fix step 5 workspace framing: per-project custom_field_settings gates Prio-Score, not the workspace boundary

