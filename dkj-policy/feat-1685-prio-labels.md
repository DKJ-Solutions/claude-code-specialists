## feat/1685-prio-labels

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Create the four labels, apply one to every open issue, and record the convention in the always-on
layer plus Derek's label lens.

#### Why the labels are created outside a gate

The four labels are repo state on GitHub, not files, so nothing in this branch can carry them: they
were created with `gh label create` and read back with `gh label list`. The same holds for the ten
open issues. What the branch carries is the **rule** — so that the next session filing a finding sets
a `prio-N` without being told, which is the half a tracker cannot enforce.

### CREATE

- [x] Create `prio-1` … `prio-4` on the tracker, colours escalating green → dark red, each with a
      description saying which rung it is.
- [x] Label all ten open issues, and read the labels back to prove none was missed.
- [x] Record the always-on half in Chris's lens under **The Dave rules** — five lines, because every
      session pays for them.
- [x] Record the detail in Derek's lens as its own section: the rung table, why it is a separate axis
      from the prefix→label mapping for a pull request, and why nothing enforces it.
- [~] A gate or session check that reports an open issue without a `prio-N` — dropped: it would put a
      network call to the tracker on the critical path of a local check, for a field only a person can
      fill in. Stated as a deliberate decline in Derek's lens instead, beside the `inbound` precedent.

### TEST

- [x] `gh issue list --state open` read back with a template that prints `MISSING` for any issue
      without a `prio-N`: ten issues, zero missing.
- [x] The lint gate and every suite, via `open-pr.ps1` — the two lenses are always-on prose and the
      new anchors have to resolve.

### DEPLOY: feat/1685-prio-labels

Every issue in this repo's tracker now carries exactly one priority, `prio-1` (lowest) to `prio-4`
(highest). The four labels exist on GitHub, the ten issues open on the day were labelled in the same
movement — a taxonomy applied only to new issues splits the tracker in two, and the older half is
where the backlog is — and the rule that a finding is filed *with* its priority is written down in
the always-on layer, so the next session does it without being reminded. It is a separate axis from
the prefix→label mapping that classifies a pull request, and Derek's lens says so, because those are
the labels this repo already had.

**Score:** 3

#### What makes this deploy extra special

N/A — nothing here reaches a consumer of the plugins. The labels are this tracker's own state and
both documents are repo-local lenses, which travel to nobody.

**Score:** N/A

#### Pull Request

Priority labels prio-1..prio-4 on every issue
