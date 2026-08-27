## Development cycle: `feat/workflow-folder-holds-the-repo-documents-v1` · 20260827-131949

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

Move CHANGELOG.md, CONTRIBUTING.md and releases/ into contributing-davekjohn/ via the existing seams; repoint the lint gate, the tests and every doc link.

### CREATE

#### The three documents

- [x] `CHANGELOG.md` -> `contributing-davekjohn/CHANGELOG.md` (git mv, so the file keeps its history)
- [x] `releases/README.md` -> `contributing-davekjohn/releases/history.md`, and `releases/` leaves the root
- [x] root `CONTRIBUTING.md` folded into `contributing-davekjohn/CONTRIBUTING.md` and removed -- a merge rather than a move, because the folder already holds a page of that name

#### The seams that make the tooling follow

- [x] `scripts/repo-config.ps1`: state `Get-ChangelogPath`, repoint `Get-ReleaseHistoryPath`, state `Get-ReleaseInternalNotesRoot`
- [~] `scripts/repo-config.ps1`: `Get-ReservedRootMd` loses the two names that left the root -- DROPPED, and the attempt is why. That list is read by the PORTABLE cut-release to tell a permanent root document from an unfolded entry, so removing CHANGELOG.md had cut-release-drive's fixtures -- and any consumer keeping a root changelog -- refuse the release over their own changelog. The list is about the NAME, not about where this repo currently keeps one
- [x] `scripts/release/publish-to-business.ps1`: the published changelog path follows the file
- [x] `scripts/lint/check-plugin-integrity.ps1`: the hardcoded root `CHANGELOG.md` reads the seam instead

#### The prose

- [x] every link to the three documents repointed -- the root docs, `CLAUDE.md`, the lenses, the skills, the release notes that name them
- [x] the records that state WHERE these live are amended rather than silently flipped -- the August 19, 2026 answer at `Get-ReleaseHistoryPath` and the August 14, 2026 layering note the root contributing page carried

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` green -- it is the dead-link gate, so it is what proves the repoint
- [x] every suite under `scripts/tests/` green
- [x] `scripts/sync/check-script-contract.ps1` green -- the seam set changed

### DEPLOY: `feat/workflow-folder-holds-the-repo-documents-v1`

Every document the contribution cycle produces or governs now lives in `contributing-davekjohn/`.
`CHANGELOG.md` and the release list moved in -- the list as `history.md`, because that folder's
`releases/README.md` is its seam-answers page -- and the root `CONTRIBUTING.md` was folded into the
folder's own contributing page rather than moved beside it. The tooling followed through the seams that
already existed for exactly this: `Get-ChangelogPath`, `Get-ReleaseHistoryPath` and
`Get-ReleaseInternalNotesRoot` are now stated in `scripts/repo-config.ps1`, so this repo stopped being the
one repo answering them differently from every consumer. Nothing about a consumer changed -- those
defaults have pointed into the workflow folder since #885.

Three records were amended rather than silently flipped, because each one argued for the root and the
argument has to stay legible: the August 19, 2026 answer at `Get-ReleaseHistoryPath` (its premise, "a
folder a teardown removes", expired when #885 made that folder permanent), the August 14, 2026 layering
note the root contributing page carried, and the two contract records a consumer reads.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing published changes. The plugins, their skills and every seam DEFAULT are untouched; what
moved is where this one repo keeps its own documents. The one consumer-visible edit is a paragraph in
`RELEASES-portable.md` that had described the source's layout as if it were a rule, which it never was.

**Score:** N/A

#### Pull Request

the workflow folder holds the changelog, the contributing page and the release history
