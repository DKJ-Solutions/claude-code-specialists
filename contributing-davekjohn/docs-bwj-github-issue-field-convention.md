## docs/bwj-github-issue-field-convention

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

Fixes #1377: `bwj-codex` neither writes nor reads the BWJ board's `Github Issue` Asana custom
field, so the full-URL convention Dave settled on September 4, 2026 drifts back to a hand-filled
state one card at a time. Scope held to the write-at-creation shape the issue itself recommends
(candidate 2, plus the doc it always needs); the read-side fallback (candidate 3) is explicitly
out of scope -- the issue notes it is only worth adding if the write side lands *and* sweep (b)
already covers the close-update gap from the GitHub side.

### CREATE

- [x] Document the `Github Issue` field convention (full URL, never a bare number, and why) in
      `WORKFLOW-portable.md`; propose the optional `Get-AsanaIssueFieldGid` seam in
      `adopt-bwj-asana/SKILL.md`; wire `report-issue/SKILL.md` to read that seam and set the
      field at task creation.

### TEST

- [x] No script changed (`report-issue` has no script of its own; the new seam is a proposed
      config stub, not executable code), so nothing here needs a test suite. Reviewed by Edith
      for language/consistency and by re-reading `Get-PrioScoreFromTask` in
      `templates/asana-mirror.ps1` to verify the name-vs-GID claim the new prose makes.

### DEPLOY: docs/bwj-github-issue-field-convention

Documents and closes the write-side of #1377: `bwj-codex` now states the `Github Issue` Asana
custom-field convention -- the full issue URL, never a bare number, because Asana only renders a
text field as a clickable link when its value is a complete URL. `adopt-bwj-asana`'s step 2
proposes an optional `Get-AsanaIssueFieldGid` seam (defaults to `$null`; addressed by GID rather
than by name, unlike `Prio-Score`, because writing a field at creation needs its GID where reading
one back can go by name), and `report-issue`'s step 2 sets that field on task creation when a repo
has configured it. The read-side fallback discussed in the issue is deliberately left out.

**Score:** 3

#### What makes this deploy extra special

A BWJ store repo running `adopt-bwj-asana` (or re-reading `report-issue`) now finds a documented,
optional convention for the board's `Github Issue` field instead of a silent gap filled in by
hand. Nothing changes automatically -- the seam defaults to `$null` and stays silent until a
maintainer sets it -- so no existing repo is affected unless it opts in.

**Score:** 2

#### Pull Request

Document and write the bwj-codex Github Issue Asana field convention

