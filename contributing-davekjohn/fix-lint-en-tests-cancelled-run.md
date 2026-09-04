## fix/lint-en-tests-cancelled-run

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

Issue #1356. The `lint-en-tests` summary job added in #1351 (PR #1352) uses `if: always()`, which is
documented to be true even when the run was CANCELLED. `cancel-in-progress` cancels the four shards
whenever a PR run is superseded by a newer push; the summary job then runs anyway, reads
`cancelled != success`, and reports the required check as `failure`. One `!cancelled()` fixes it and
keeps every fail-closed property the banner argues for.

### CREATE

- [x] `.github/workflows/ci.yml`: `if: always()` -> `if: ${{ !cancelled() }}` on the `lint-en-tests`
      job; rewrite the "`if: always()` PLUS AN EXPLICIT RESULT CHECK" banner paragraph to explain
      `!cancelled()` and why not `always()`, and fix the one-line cross-reference in the job's own
      header comment.

### TEST

- [x] `scripts/tests/ci-shard.tests.ps1`: the `if:` assert now checks `!cancelled()` AND the absence
      of a bare `always()` (one assert, count stays 46), and the `.DESCRIPTION` bullet names the
      `always()` reintroduction as the #1356 regression.
- [x] `scripts/tests/ci-shard.tests.ps1` run green -- all 46 asserts pass.

### DEPLOY: fix/lint-en-tests-cancelled-run

The `lint-en-tests` summary job -- the single required check, added in #1351 -- ran with `if: always()`,
and `always()` is true even when a run is CANCELLED. A PR run superseded by `cancel-in-progress` has its
four shards cancelled while the summary job runs on anyway, reads `cancelled != success`, and reports
the required check as `failure` on a commit nothing merges, plus one wasted runner per cancellation.
`if: ${{ !cancelled() }}` keeps every property the banner argues for -- true when a dependency failed
or was skipped, so a red shard still produces a red verdict -- and is false only when the run itself
was cancelled, so a superseded run now reports `cancelled`. This supersedes the `always()` choice
recorded in the `feat/shard-ci-suites` entry above. Pinned by `scripts/tests/ci-shard.tests.ps1`,
whose `if:` assert now requires `!cancelled()` and rejects a bare `always()`.

**Score:** 1 -- it prevents a failure that has not misled anyone yet: a superseded PR run reads
`failure` in the Actions list where nothing failed, the one place someone goes looking for a genuine
red. `cancel-in-progress` keys on `github.ref` so the red check sits on a head SHA no PR check list
reads; `ship-pr`'s check read is not affected.

#### What makes this deploy extra special

N/A -- CI run-history accuracy in the source repo. A subscriber of a consuming service never sees it,
and the workflow change is inert for any repo that has not adopted the sharded `ci.yml`.

**Score:** N/A

#### Pull Request

lint-en-tests summary job: !cancelled() instead of always(), so a superseded run reports cancelled not failure

