## fix/1556-asana-mirror-get-issueclosure

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

#### What the inbound report said, and what verifying it added

Inbound #1556, measured in `BWJ-Development/smartwatchbanden` against `dkj-policy-bwj` 4.31.0:
`templates/asana-mirror.ps1` calls `Get-IssueClosure` and never defines it, so
`Invoke-ReconcileFromGitHub` dies on the first closed issue whose task has not been told -- and
`Invoke-ReconcileMode` aborts at the first crash, taking the prio-label and stage sweeps with it.

All six inbound checks pass. The symptom still stands here (the call is at line 1500 of the source's
1798, against the report's 1412 of 1695 -- the template has grown since 4.31.0, and the defect has
not moved). The **reason** the report infers is confirmed against the history rather than assumed:
`git log -S` puts the rename in `fa3a4e55`, which turned `Get-IssueClosure` into
`Get-IssueLinkState`, updated the event call site and missed the sweep's.

Verifying it added one thing the report did not have. Writing the gate it proposes surfaced **two
more** unresolved names, `Get-AsanaStageMap` and `Get-GithubStatusMap` -- and both are correct: they
are seams into the *consumer's* `scripts/repo-config.ps1`, dot-sourced at run time, each call guarded
by a `Get-Command` test immediately before it. That is what settled the gate's shape.

### CREATE

- [x] `Update-MirroredTask` calls `Get-IssueLinkState` with `-StatusField ''` -- the step writes a
      comment and moves no card, so the project status is not its question, and asking would spend
      the `projectItems` round trip on an unread answer and print the `GH_PROJECT_TOKEN` notice once
      per swept issue in a repo that has not set one. Commented at the call site.
- [x] `scripts/tests/template-selfcontained.tests.ps1` -- the gate the report asks for: every
      Verb-Noun name a shipped template calls is defined in the file, provided by PowerShell, or
      declared external by the file's own `Get-Command` guard.
- [x] The gate's shape and both PowerShell traps behind it recorded in Sylvester's lens, in the
      section that already documents how this repo's gate checks got their shapes.
- [~] Nothing patched in the consumer. Dropped on the reporter's own reasoning, which holds: it is a
      verbatim template copy there, so a local patch would create a second source and be overwritten
      by the next adopt. It arrives by release, and `BWJ-Development/smartwatchbanden#541` tracks it.

### TEST

- [x] The repaired template parses and no longer names `Get-IssueClosure`.
- [x] The new suite is green: 8 asserts, 5 of them fixtures proving the checker itself fires, so a
      green tree is evidence rather than a tautology.
- [x] **Fired against the real defect, not only the miniature.** The pre-fix template was dropped
      into `templates/` under a second name and the suite run unmodified: it reports exactly
      `Get-IssueClosure` on that copy and passes on the repaired one. Probe removed.
- [x] Lint gate + all suites, via `open-pr.ps1`.

### DEPLOY: fix/1556-asana-mirror-get-issueclosure

`dkj-policy-bwj`'s `asana-mirror.ps1` template called `Get-IssueClosure`, which nothing defines --
the rename in `fa3a4e55` updated the event call site and missed the sweep's. The reconciliation sweep
therefore crashed the first time it had a close comment to write, and because `Invoke-ReconcileMode`
aborts at the first crash, the prio-label and stage sweeps went down with it. `Update-MirroredTask`
now calls `Get-IssueLinkState`, and passes `-StatusField ''` because it writes a comment and moves no
card. A new suite, `template-selfcontained.tests.ps1`, holds every shipped template to the property
this broke: each Verb-Noun name it calls is one it defines, one PowerShell provides, or one it
declares external with a `Get-Command` guard -- which is how the template's two real seams into the
consumer's `repo-config.ps1` stay legal without an allowlist to maintain.

**Score:** 3

#### What makes this deploy extra special

A consumer running the Asana mirror had a daily reconciliation sweep that could not complete, and no
signal saying so: event runs stayed green, and a sweep with nothing to do stayed green too. Since a
project status change fires no `issues:` event at all, that sweep is the mechanism rather than a
backstop -- so cards stopped moving and closed tickets stopped being commented on, silently. Adopting
this release restores all three sweeps; nothing needs re-configuring.

**Score:** 4

#### Pull Request

The Asana mirror's reconciliation sweep no longer crashes on a renamed helper
