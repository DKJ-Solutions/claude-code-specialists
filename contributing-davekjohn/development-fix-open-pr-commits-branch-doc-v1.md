## Development: `fix/open-pr-commits-branch-doc-v1` · 20260903-100247

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

Fix #1269: a dirty development document opens a PR that branch-entry CI must fail.

#### What was measured, and what it costs

`open-pr` reads the branch's development document from the **working tree** -- five gates and the PR
body -- and then pushes **HEAD**. On a dirty document those are two different files, and all three
consumers of that document read the committed one: the `branch-entry` CI check, the fold, and
ship-pr's DEPLOY lock. So a dirty document is not a soft risk the `DIRTY tree` warning covers; it is
a guaranteed red check plus a PR body that describes a section the branch does not carry. Measured on
PR #1267: run 100563684253 failed on `7b783516`, run 100564770379 passed on `f1c02ea7` once the
document was committed by hand.

The backing gate is blind to it by design -- `Get-BranchBackingFinding` requires `Committed -eq 0`, so
a dirty document *alongside* committed code raises nothing.

#### The repair, and why it is a commit rather than a fifth refusal

`open-pr` is the documented owner of the step that publishes this document, and `park-cycle` already
commits exactly this one path automatically for the life of the branch -- so committing it here is an
act the system already performs, at the one moment it has to be true. A refusal would also cost a full
lint + test gate re-run, because committing moves HEAD and invalidates the gate-evidence fingerprint --
measured on this branch at 11.1s of lint plus 96s of suites against the ~150ms the commit itself takes.

Bounded exactly as `park-cycle`'s bound 1 is: the resolved document path(s) and nothing else, never
`git add -A`, and `git commit -- <paths>` leaves any other staged work staged.

### CREATE

- [x] park-lib: extract the stage+commit half of `Invoke-GitPark` into `Invoke-GitParkCommit` (no push), so open-pr shares the one implementation instead of a second copy of the staging dance
- [x] open-pr: commit the branch document(s) it derives the PR body from, immediately before the workflow gates and the push
- [x] document it where a consumer reads it: open-pr's own `.DESCRIPTION`, the `open-pr` skill page, `CONTRIBUTING-portable.md`, and this repo's `CONTRIBUTING.md` step 3.2
- [x] mirror the changed scripts to the plugin (`build-shared-scripts.ps1`)

### TEST

- [x] unit tests for `Invoke-GitParkCommit` against a real fixture repo: commits when dirty, silent when clean, leaves unrelated staged work staged, and reports a failure rather than throwing
- [x] the three existing park suites stay green (`park-branch`, `park-cycle`, `backing-gate`)
- [x] full local gate: `check-plugin-integrity.ps1` + every suite

### DEPLOY: `fix/open-pr-commits-branch-doc-v1`

`open-pr.ps1` read the branch's development document from the **working tree** -- the scaffold,
step-list, backing, impact and link gates, and the PR body it composes -- and then pushed **HEAD**. On
a dirty document those are two different files, and every downstream reader takes the committed one:
the `branch-entry` CI check, the fold, and ship-pr's DEPLOY lock. So the run published a PR body
describing a DEPLOY section the branch did not carry, and CI failed on arrival. It now commits that
document first, through the new `Invoke-GitParkCommit` in `park-lib.ps1` -- the stage-and-commit half
of a park, without the push, bounded to the resolved document path(s) exactly as `park-cycle`'s bound 1
is.

Measured on PR #1267: `branch-entry` run 100563684253 failed on `7b783516`, and run 100564770379
passed on `f1c02ea7` once the document had been committed by hand. The `DIRTY tree` warning (#1026)
covered it only as a soft risk, and the backing gate could not see it at all --
`Get-BranchBackingFinding` requires `Committed -eq 0`, so a dirty document *alongside* committed code
raised nothing.

Committing rather than refusing was the choice, because this script is the documented owner of the
step that publishes that document, `park-cycle` already commits exactly this path automatically for
the life of the branch, and a refusal would have charged the author a full lint + test gate re-run:
committing moves HEAD, which invalidates the gate-evidence fingerprint the next run would otherwise
reuse. Placing it above `Invoke-WorkflowGates` also makes that function's dirty-tree warning honest --
a remaining dirty count is now real unpublished work.

It is deliberately **not** called a gate. Its normal outcome is an act rather than a verdict -- it errors
only if git itself fails -- so naming it one would make the four-plus-one gate count in
[`CLAUDE.md`](../CLAUDE.md) and [`CONTRIBUTING.md`](CONTRIBUTING.md) wrong on the day it landed. It is
written up where a consumer reads it: open-pr's own `.DESCRIPTION`, a new section on the `open-pr` skill
page, `CONTRIBUTING-portable.md`'s PR step, and step 3.2 here.

One latent defect came with the extraction: `Write-Error` inside the commit arm terminates under
`$ErrorActionPreference = 'Stop'`, which every caller sets. Inline in a function returning a bare bool
that only ever fed an `exit`, that was harmless; in a function whose return value a caller reads, it
makes the return dead code -- and it broke `park-cycle.ps1`'s documented "ALWAYS EXITS 0" contract,
since it runs on a Stop hook. Both messages are now non-terminating, the same repair
`Invoke-WorkflowGates` carries for the same reason.

**Score:** 3

#### What makes this deploy extra special

Nothing a subscriber sees. The fix is entirely inside the workflow tooling: a consumer running
`open-pr` stops meeting a guaranteed red CI check on a branch whose document was written but not
committed, which they notice the first time it does not happen.

**Score:** N/A

#### Pull Request

open-pr commits the branch document it derives the PR body from, so what CI reads is what was gated
