## Development: `fix/branch-file-paths-docstring-covers-1255-v1` · 20260903-100206

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

Add the #1255 paragraph (SharedFile + Pattern) to the Get-BranchFilePaths docstring and settle the stale 'Eight names read' count; then re-mirror via build-shared-scripts.ps1.

### CREATE

- [x] Read the docstring against the tree and confirm the gap #1265 reports still stands: the
      narrative ends at #963, and `SharedFile` and `Pattern` have no paragraph.
- [x] Settle the count question #1265 left open, from the history rather than by taste:
      `git log -S` shows `four` (August 19), `seven` (#886), `eight` (#963), and no basis
      reconstructs any of them from the table -- so it is replaced by a pointer at
      `Get-BranchFileLegacyNames`, not bumped to nine.
- [x] Write the two missing paragraphs (#1255, and `Pattern` as the row that is not a name) plus the
      paragraph retiring the count, and drop the stale `four` from the standing "recognise, write one"
      line above them.
- [x] Re-mirror to the plugin copy with `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `LC_ALL=C grep '[^ -~]'` over the edited lib: clean, so check 27's ASCII rule holds.
- [x] `check-plugin-integrity.ps1` plus every suite, via `open-pr.ps1`'s own gate.

### DEPLOY: `fix/branch-file-paths-docstring-covers-1255-v1`

`Get-BranchFilePaths`'s docstring narrative stopped at #963 and never explained the two rows #1255
added. `SharedFile` and `Pattern` are both load-bearing -- one is a legacy candidate
`Resolve-BranchFilePath` reads, the other drives its per-branch discovery sweep and
`Test-IsPerBranchDocumentPath` -- so a reader following the narrative to understand the returned table
found no reason for either. Three paragraphs now cover the sixth rename, `Pattern` as the one row that
is not a name, and why the read set is no longer counted in prose at all: the number had been `four`,
then `seven`, then `eight`, and #1255 added a name without touching it. Since #1259 there is one
ordered source -- `Get-BranchFileLegacyNames` -- so the docstring points at it instead of carrying a
count that goes stale on the next rename. No behaviour changed; the plugin mirror moved with it.

**Score:** 2

#### What makes this deploy extra special

N/A -- a docstring inside a shared script lib. No subscriber of a service reads it, and nothing about
what the scripts do changed.

**Score:** N/A

#### Pull Request

Get-BranchFilePaths's docstring reaches the per-branch rename

