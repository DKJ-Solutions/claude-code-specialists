## Development: `fix/asana-mirror-unused-workspace-gid-v1` · 20260902-084206

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

Drop -WorkspaceGid from the template script and ASANA_WORKSPACE_GID from both yml steps; then correct the four doc sites that call it a CI variable. Get-AsanaWorkspaceGid stays -- report-issue reads it session-side.

### CREATE

- [x] `templates/asana-mirror.ps1`: the `-WorkspaceGid` parameter is gone, and the docstring now
      states why there is none instead of naming it as one of the two values the script runs on
- [x] `templates/asana-mirror.yml`: `ASANA_WORKSPACE_GID` removed from the `env:` of both steps
- [x] `skills/adopt-bwj-asana/SKILL.md`: step 3 prints one variable, with a note against adding the
      other back and a pointer to the reader that does still want a workspace
- [x] `WORKFLOW-portable.md` and `README.md`: the setup line and the seam paragraph stop calling it
      a CI variable, while both keep `Get-AsanaWorkspaceGid` as the seam function it is

### TEST

- [x] `scripts/tests/bwj-codex.tests.ps1`: three asserts added to the block that already holds an
      absence over the source text -- no parameter in the script, no workspace variable in the
      workflow, and the project variable it does read still passed. Suite green at 70 asserts, up
      from 67.
- [x] Lint gate + all suites via `open-pr.ps1`, exactly as CI runs them

### DEPLOY: `fix/asana-mirror-unused-workspace-gid-v1`

The mirror's CI half stops advertising a value it never reads. `asana-mirror.ps1` declared
`-WorkspaceGid`, defaulting to `$env:ASANA_WORKSPACE_GID`, and named it in its own help as one of the
two values the script runs on -- while nothing in the script body ever read it. `asana-mirror.yml`
handed that variable to both steps, and `adopt-bwj-asana` printed it as a variable the CI needs. All
four statements are gone.

The parameter never had work to do: every call this script makes addresses a task or a project by
GID, and the Asana API wants no workspace for either. What stays is `Get-AsanaWorkspaceGid` in the
repo seam -- `report-issue` reads it session-side, where it CREATES a task and the API does want one.
So the seam is untouched and only the CI half stops claiming a reader it has not got.

Why this was worth a branch rather than a shrug: a wrong or absent value there produced no signal in
either direction, so it read as a plausible cause the next time a sweep reported `0 updated`. That is
not hypothetical -- the session that filed it had just spent real time ruling it out. Three asserts
now hold the absence, beside the four guarding the rule that automation never ticks a ticket off.

Consumers that already copied the templates keep a `.github/` copy carrying the dead parameter, and a
repo variable nothing consumes. Both are harmless and neither is touched from here: the copy is
per-repo by design, and re-copying is that repo's own move.

**Score:** 2

#### What makes this deploy extra special

A repo adopting `bwj-codex` now sets one Actions variable instead of two, and its setup checklist
stops naming a value the CI never reads. An existing adopter may delete `ASANA_WORKSPACE_GID` from
its Actions variables, and nothing breaks if they leave it standing.

**Score:** 2

#### Pull Request

the mirror's CI half stops advertising a workspace GID it never reads
