# Development cycle: `docs/development-portable-rename-v1` · 20260825-213146

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
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

## PLAN

Rename `plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md` to
`DEVELOPMENT-portable.md` (issue #888) and update every reference across the repo: the skills that
link to it, the folder docs (`README.md`/`CLAUDE.md`/`CONTRIBUTING.md`, both the plugin-native and
this repo's consumed copies), the two root scripts that name it in generated guidance text
(`entry-scaffold-lib.ps1`, `adopt-workflow-folder.ps1`) plus their regenerated plugin mirror, and
the archived release notes/audience notes that link to the old name (fixed as a plain link-target
update, not a rewrite of what they reported).

## CREATE

- [x] `git mv` the file; update every reference (docs, skills, root scripts + regenerated mirror,
      archived release notes) so no dead link remains

## TEST

- [x] Lint gate green (0 errors). Test-suite gate: 51 of 53 suites green; the other 2
      (`internal-note.tests.ps1`, `round-tally.tests.ps1`) fail on this machine only -- verified against
      the actual CI run for current `main` HEAD (green there) and filed separately as #892, unrelated to
      this branch's changes

## DEPLOY: `docs/development-portable-rename-v1`

Renamed `DEVELOPMENT-CYCLE-portable.md` to `DEVELOPMENT-portable.md` and repointed every reference
to it repo-wide, so the manual's name no longer contradicts the working file it describes
(`development-cycle.md`, not `development-cycle-cycle`).

**Score:** 1 — cosmetic naming cleanup; no behavior, script contract, or consumer-facing change.

### What makes this PR extra special

N/A — an internal doc rename, nothing a subscriber of the service would ever see.

**Score:** N/A

### Pull Request

Rename DEVELOPMENT-CYCLE-portable.md to DEVELOPMENT-portable.md and update every reference

