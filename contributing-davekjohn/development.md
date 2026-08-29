## Development: `docs/development-step-drops-new-task-v1` · 20260829-095301

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

#### What this branch is

`## 2. NEW DEVELOPMENT TASK` in `contributing-davekjohn/CONTRIBUTING.md` becomes `## 2. DEVELOPMENT`
(Dave, August 29, 2026). The word `NEW` dated from when this step opened the page and a development task
was the first thing that happened; step 1 has owned the arrival since earlier the same day, so `NEW` now
claims something the step above it does.

**One line changes, and that is the measurement rather than the hope**: `NEW DEVELOPMENT TASK` appears
exactly once in the whole tree -- no anchor, no script, no lens, no changelog entry points at it -- and the
step numbers are untouched, so every `step 2.x` reference on the page and in `README.md` stays true.

### CREATE

- [x] Rename the heading, and record the reason under it in one sentence -- this page states why its own
      structure moved, and a rename with no reason invites the next reader to undo it

### TEST

- [ ] `NEW DEVELOPMENT TASK` survives only as the deliberate note under the new heading -- no second
      heading anywhere, and nothing links to a `#2-new-development-task` anchor
- [ ] `check-plugin-integrity.ps1` clean and all suites green

### DEPLOY: `docs/development-step-drops-new-task-v1`

Step 2 of `contributing-davekjohn/CONTRIBUTING.md` is now `## 2. DEVELOPMENT` (Dave, August 29, 2026). The
word `NEW` dated from when this step opened the page and a development task was the first thing that
happened here; `## 1. NEW ISSUE / TASK` took over the arrival earlier that day, so the two headings had
started making the same claim two rows apart. One sentence under the new heading records why, because a
rename with no reason invites the next reader to undo it.

Nothing else moved: `NEW DEVELOPMENT TASK` appeared exactly once in the whole tree -- no anchor, no script,
no lens, no changelog entry pointed at it -- and the numbering is untouched, so every `step 2.x` reference
on the page and in `README.md` still resolves.

**Score:** 2

#### What makes this deploy extra special

N/A -- a heading on a contributor-facing page in the source repo. No shipped file, script or gate reads it.

**Score:** N/A

#### Pull Request

Step 2 is DEVELOPMENT, not NEW DEVELOPMENT TASK
