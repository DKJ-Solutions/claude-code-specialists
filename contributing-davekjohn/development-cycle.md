## Development cycle: `feat/release-changelog-seam-rename-v1` · 20260826-214846

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### What issue #947 asked for, and what it deliberately did not

#914 renamed the tier-0 note directory `development` -> `changelog` and left the seam FUNCTION alone,
on the reasoning that renaming a seam is a contract change a consumer has to act on. #947 is the
argument that the reasoning was right about the cost and wrong about who pays it: `Get-SeamValue`
takes an ARRAY of names precisely so a renamed seam keeps answering under both, so no consumer acts
on anything.

The issue's own repair list is the scope, and it does **not** include the local variables
(`$devNotesRootRelPath`, `$devRootRel`). Its wording is explicit -- "both are correct in their own
file" -- so a variable sweep was started, measured against that sentence, and reverted. What is wrong
is the seam sitting between the two, not either end of it.

### CREATE

- [x] Both read sites read `'Get-ReleaseChangelogNotesRoot', 'Get-ReleaseDevelopmentNotesRoot'`,
      current name first: `scripts/release/cut-release.ps1` and
      `scripts/release/new-internal-note.ps1`, plus the `-SeamName` each passes to
      `Assert-WorkflowIsolatedSeamPath`
- [x] The contract record's `Function` renamed in `scripts/lib/script-contract-lib.ps1`, with the
      rename comment above it in the shape the `Get-ReleaseHighlightsBumps` ->
      `Get-ReleaseConsumerBumps` record already uses, and the `AdoptWhy` amended rather than silently
      flipped
- [x] The four cross-references in sibling records, and the one in `scripts/lib/seam-lib.ps1`'s
      `Assert-WorkflowIsolatedSeamPath` docstring
- [x] `contributing-davekjohn/CONTRIBUTING.md`, `RELEASES-portable.md` (with a line telling a consumer
      their existing config still answers) and the `cut-release` skill page
- [x] The blueprint and the plugin mirror regenerated from their generators, not by hand

### TEST

- [x] The retired name is asserted as BEHAVIOUR, not as text: two fixtures in
      `scripts/tests/internal-note.tests.ps1` plant the notes where only one of the two names points
      and require the script to find them. `New-Fixture` gained a `-NotesRoot` parameter for it
- [x] Negative check run: dropping the fallback from `new-internal-note.ps1` turns those two asserts
      red (2 failed, 93 passed), so they bite rather than pass vacuously
- [x] The order assertion on `cut-release.ps1`'s code view, mirroring the precedent block directly
      above it in `scripts/tests/cut-release-guardrail.tests.ps1`
- [x] `check-plugin-integrity.ps1`: 0 errors. `check-script-contract.ps1`: 0 errors, and the report
      now names `Get-ReleaseChangelogNotesRoot`. Every suite green

### DEPLOY: `feat/release-changelog-seam-rename-v1`

The tier-0 release-notes seam is now `Get-ReleaseChangelogNotesRoot`, matching both the directory it
points at (`contributing-davekjohn/releases/changelog/`) and the computed default behind it
(`Get-DefaultReleaseChangelogNotesRoot`). #914 renamed the directory and deliberately left the seam,
so the two halves of one mechanism disagreed by name inside `scripts/lib/seam-lib.ps1`, and the
contract record's `Returns` text carried a sentence that existed only because the name was wrong.

**Nothing in a consumer's repo has to change.** Both read sites -- `scripts/release/cut-release.ps1`
and `scripts/release/new-internal-note.ps1` -- pass the current name and the retired one to
`Get-SeamValue` in that order, which is what that parameter takes an array for. A repo that already
defines `Get-ReleaseDevelopmentNotesRoot` keeps answering under it; a repo that defines both is
answered by the current name, so a mid-migration config moves rather than staying. Both cases are
asserted as behaviour rather than as text, and a negative run confirms the asserts fail without the
fallback.

**Score:** 2

#### What makes this deploy extra special

The rename it reverses was itself argued, and this reversal names the part of that argument that was
wrong rather than quietly replacing it. The detail worth keeping is the scope discipline: the issue
named a local variable while explicitly calling it correct, a rename of it was started anyway, and
reading that sentence again is what stopped a twenty-site diff that would have repaired nothing.

**Score:** 1

#### Pull Request

Rename the tier-0 notes seam to Get-ReleaseChangelogNotesRoot
