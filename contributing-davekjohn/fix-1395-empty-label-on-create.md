## fix/1395-empty-label-on-create

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

#### What was verified before anything was written

Inbound #1395, checked against the tree rather than taken from the report:

- **The symptom stands.** `scripts/release/open-pr.ps1` appended `'--label', $label` to the fixed
  `gh pr create` argument list unconditionally, on a path reached only when there is no existing PR --
  so `$label` is always resolved, and an empty resolution went out as `--label ''`.
- **The reason stands.** `scripts/lib/branch-info.ps1` answers `Label = $null` for a known prefix
  whenever the repo's own prefix table says so, which is a legitimate seam answer; `Get-MissingLabelNote`
  already reads an empty label as "nothing to check" and returns `''`.
- **The proposed repair names a mechanism that exists**, and this tree already runs it: `sync-main.ps1`
  composes `$labelArgs` and emits no `--label` when it has none (#1023).
- **The size is the size reported** -- one conditional, no seam or contract change.

#### What the repair adds beyond the report

Two things the report did not name, both on the same path and both wrong for the same reason:

- The `gh label list` call ran for a repo with no label to judge, and both of its failure warnings
  went on to name `''` as the label `gh pr create` would judge after the push.
- The success line announced `label gate: label '' exists in <owner>/<repo>.`

So the empty answer is recognised **before** the lookup rather than only at the create, and
`$label` is normalised to a trimmed string first -- `$null` in a native argument list is an empty
argument, not an absent one.

### CREATE

- [x] `open-pr.ps1`: recognise an empty seam answer above the `gh label list` call, and say so in one
      DarkGray line naming the prefix and the seam file
- [x] `open-pr.ps1`: normalise the resolved label (`$label = "$label".Trim()`), so `$null` and `' '`
      cannot reach `gh` as an argument
- [x] `open-pr.ps1`: compose `$labelArgs` and append it to the create, the way the optional assignee
      and milestone already are -- the fixed list carries no `--label`
- [x] `open-pr.ps1`: the label-gate paragraph in the script's own docstring names the case
- [x] Mirror to `plugins/workflows/contributing-davekjohn/scripts/release/open-pr.ps1` via
      `scripts/sync/build-shared-scripts.ps1`
- [x] `skills/open-pr/SKILL.md`: a bullet in the label-gate list, written against the
      "it refuses and does not fall back" bullet rather than beside it -- the two would otherwise read
      as a contradiction

### TEST

- [x] `scripts/tests/pr-issues.tests.ps1`: eight asserts on the create path -- the fixed list no longer
      interpolates the label, `$labelArgs` is composed in exactly one place, the normalisation sits
      between the resolve and the gate, and the empty answer is recognised before the `gh label list`
      call. Text asserts, for the reason the block above them already gives: this script is the one
      caller no suite gets to run.
- [x] The negative assert was checked against the old line rather than assumed -- it matches, so it is
      not a tautology.
- [x] `pr-issues.tests.ps1` green (628 asserts), and the corrected message on the existing
      empty-label assert -- it claimed the case belonged to the nameless-PR guard, which is about the
      title.

### DEPLOY: fix/1395-empty-label-on-create

`open-pr.ps1` sends no `--label` at all when the branch-prefix seam answers no label for a prefix it
knows. It used to append `--label` unconditionally, so a repo that has abolished PR labels -- the issue
**type** carries the classification there now -- had every gate pass, its branch pushed, and then the
whole `gh pr create` refused over a label named `''`. The empty answer is now recognised before the
`gh label list` call, so there is no lookup whose answer cannot matter and no success line announcing
that `''` exists in the repository; the resolved label is normalised first, because `$null` in a native
argument list is an empty argument rather than an absent one. Inbound #1395, measured in
`BWJ-ecommerce/smartwatchbanden` on September 4, 2026, which had been opening its PRs by hand in the
meantime.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's own prefix table names a label for all three of its prefixes, so nothing here
changes. The consumer that reported it gets its scripted PR route back.

**Score:** N/A

#### Pull Request

open-pr sends no --label at all when the seam answers none
