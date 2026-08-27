## Development cycle: `fix/release-history-default-stops-branching-on-source-v1` · 20260827-182451

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

Issue #989: Get-DefaultReleaseHistoryPath still describes (and computes) a source that keeps its release list at the root. Since #980 the source keeps neither. Decide whether the source branch should exist at all -- the #914 precedent says the tree exists only BECAUSE the workflow does -- and either collapse both defaults to one shape or amend the docstrings, never silently flip.

### CREATE

- [x] Recount the finding in its own terms before scoping to it. Issue #989 names two functions in one
      file (plus the mirror). The premise it reports as expired -- *the source keeps its root files* --
      is stated at FOUR sites in `scripts/lib/seam-lib.ps1`, and one of them is a guardrail rather than
      prose: `Get-DefaultReleaseHistoryPath`, `Get-DefaultChangelogPath`, `Test-IsWorkflowSourceRepo`'s
      own docstring, and `Assert-WorkflowIsolatedSeamPath`'s outright exemption for a source repo.
- [x] Amend all four, following this repo's convention for a relocated seam: quote what the sentence
      used to say, then say what changed and when, never a silent flip.
- [x] Record what the fourth site actually rests on, since it is a guard: the exemption's stated reason
      has expired but the exemption has not, because it now covers a repo that publishes plugins AND
      keeps those roots at its root -- which is what the test detects, its name notwithstanding.
- [x] Mirror `seam-lib.ps1` into the plugin and verify the copy is byte-identical, which #989 requires
      by name.
- [~] Collapse the source branch out of the two computed defaults. NOT DONE, and filed instead -- see
      TEST for the measurement that decided it.

### TEST

- [x] `seam-lib.tests.ps1`: 37 pass, 0 fail. Behaviour is deliberately untouched, and the suite proves
      it: *"the changelog path still keeps a source at its own root file"* and *"the release history
      still keeps a source at releases/README.md -- it stayed behind at #914"* both still pass.
- [x] Read `Test-IsWorkflowSourceRepo` before answering #989's question, and that read is what settled
      it. The test is `Test-Path .claude-plugin/marketplace.json` -- it answers *does this repo publish
      plugins*, not *is this repo THIS workflow's source*. Under Dave's own one-product-one-repository
      rule the next product gets its own marketplace, so a repo consuming this workflow while publishing
      something else answers true. Collapsing the branch would move that repo's changelog under it
      silently, and the conflation is the thing to settle first -- so the collapse is a decision with a
      blast radius rather than the tidy-up it looks like from the outside.
- [x] The mirror is byte-identical to the source copy (compared as bytes, not as text).
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr`.

### DEPLOY: `fix/release-history-default-stops-branching-on-source-v1`

Four statements in `scripts/lib/seam-lib.ps1` rested on one premise -- *the workflow's source keeps its
changelog and its release list at its own root* -- and #980 retired that premise on August 27, 2026 by
moving both into `contributing-davekjohn/` and stating them as seams. All four now say what is actually
true, each quoting what it used to say rather than being flipped in silence, which is the convention
every relocated seam's record in this repo already follows. Nothing computes differently: the source
states both seams, so the branch that still exists in the computation is inert here.

**Score:** 2

#### What makes this deploy extra special

**One of the four is a guardrail, and that is the site the report did not reach.**
`Assert-WorkflowIsolatedSeamPath` exempts a source repo outright, and its reason read *"it deliberately
keeps these roots at its own root by its own decision (Dave, August 14, 2026), and Get-Default*'s own
computed answer for a source IS that root."* The first clause is exactly what #980 retired. The
exemption is still doing work -- it covers a repo that publishes plugins and does keep those roots at
its root -- so it stays, with the difference between its old reason and its real one written down. A
reader who deleted it on the strength of the stale sentence would have removed a live guard.

**The question #989 actually asked is filed rather than answered, and the reason is a measurement.**
It asked whether the source branch should survive at all, citing #914's precedent. `Test-IsWorkflowSourceRepo`
is `Test-Path .claude-plugin/marketplace.json`: it detects *publishes plugins*, not *is this workflow's
source*. Under Dave's own one-product-one-repository rule those two come apart on the next product, so
collapsing the branch would repoint a plugin-publishing consumer's changelog with nothing said. That is
a design decision touching a guard, not a docstring repair, so it leaves this branch as its own issue
with the mechanism attached.

**The branch name predates the answer and is left as it is.** It was created as
`fix/release-history-default-stops-branching-on-source-v1`, before `Test-IsWorkflowSourceRepo` had been
read and while collapsing still looked like the obvious repair. The defaults do still branch; the title
and this entry say so, and renaming a pushed branch to tidy that up would cost more than the wart.

**Score:** 2

#### Pull Request

four seam docstrings stop claiming the source keeps its changelog and release list at its root

Plugins: contributing-davekjohn