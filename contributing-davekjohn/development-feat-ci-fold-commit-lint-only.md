## Development: `feat/ci-fold-commit-lint-only` · 20260903-144856

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

Issue #1300, sized: after #1294 keyed every push to `main` on its own commit, `ship-pr`'s second
push (the `fold:` commit) runs a full ~15-minute suite over a tree whose only delta from the merge
commit is the changelog entry + the removed branch document -- neither executable. The entry is a
verbatim copy of the branch document's DEPLOY section, which `check-plugin-integrity.ps1` check 4
already link-scans on the PR and `branch-entry.yml` shape-checks there. Dave chose option B: the fold
commit keeps its lint run and skips the suites.

### CREATE

- [x] `.github/workflows/ci.yml`: `if:` on the Test suites step so it is skipped when the head commit
  of a push to `main` starts with `fold:`; lint step left unconditional; concurrency-block trailer
  updated from "deliberately not answered here" to point at this split.
- [x] `scripts/tests/workflow-concurrency.tests.ps1`: assert the suite step carries the commit-kind
  condition and is gated on the push event, the lint step does not, no `paths-ignore`, and ci.yml
  cites #1300.

### TEST

- [x] `workflow-concurrency.tests.ps1` green (19 asserts).
- [x] Lint gate + full suites green locally (0 errors; 62 suites, 91s).

### DEPLOY: `feat/ci-fold-commit-lint-only`

The `fold:` commit's CI run drops from the full ~15-minute suite to a lint-only run of about a
minute. That is roughly half of every ship's trunk runner time on `windows-latest` (billed at 2x),
recovered without giving back anything #1294 bought: every trunk commit still carries a green
`lint-en-tests`, and the folded `CHANGELOG.md` is still link-scanned by that lint run. The skip is
keyed on the commit message (`fold:`), not a path filter, so no merge commit can fall through it.

**Score:** 3

#### What makes this deploy extra special

N/A -- a CI-internal change to this repo's own `.github/workflows/`; no subscriber of any consuming
service sees it.

**Score:** N/A

#### Pull Request

CI on the fold commit runs lint only, not the full suites

