## docs/fix-1394-asana-workspace-claim

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

Rewrite the per-field GID paragraph (and two more instances found by the same grep) to the per-project custom_field_settings test step 5 now states, instead of the superseded one-workspace claim it still cited.

### CREATE

- [x] Rewrote `adopt-bwj-asana/SKILL.md` lines 118-123 (the `Get-AsanaIssueFieldGid` paragraph) and
  lines 101-105 (the prio-labels bullet) to the per-project `custom_field_settings` test, matching
  `WORKFLOW-portable.md` step 5's current wording, and added the `#1386` citation alongside `#1213`.
- [x] Ran the grep the issue suggested (`one-workspace|does not cross`) and found two more instances
  of the same superseded claim: `README.md`'s `Get-AsanaProjectGid` entry and
  `asana-mirror.ps1`'s `Get-PrioScoreFromTask` docstring. Rewrote both the same way. Left the archived
  changelog entries and `WORKFLOW-portable.md` step 5 itself alone -- the changelog is a frozen
  historical record and step 5 already carries the corrected reasoning.

### TEST

- [x] Read `WORKFLOW-portable.md` lines 255-300 to confirm step 5's current wording before rewriting
  anything against it, rather than trusting the issue body's quotation.
- [x] Re-ran the grep after the edits -- the three script/doc hits left are the CRLF comment in
  `release-lib.ps1` (unrelated "does not cross" usage) and the two archived changelog entries
  (deliberately untouched).

### DEPLOY: docs/fix-1394-asana-workspace-claim

Fixes a stale citation in `adopt-bwj-asana`'s config-seam guidance: it told a maintainer that an
Asana custom field is usable anywhere in the same workspace, when the real (per-project
`custom_field_settings`) test had already been established in step 5 by #1386. Prevents a failure
that has not happened yet: a maintainer picking `Get-AsanaProjectGid`/field GIDs by workspace alone
could pick a project that is in the right workspace but never had the field added to it -- exactly the
`GitHub - WH` counterexample the issue measured -- and silently lose prio labels or custom-field
writes with nothing in a log to say why.

**Score:** 1

#### What makes this deploy extra special

Internal engineering documentation only -- no subscriber-facing behavior changes.

**Score:** N/A

#### Pull Request

adopt-bwj-asana still states the one-workspace test #1386 replaced

