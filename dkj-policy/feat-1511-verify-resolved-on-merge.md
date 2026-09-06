## feat/1511-verify-resolved-on-merge

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

ship-pr step 6 has no home once the merge queue takes over; a new push-to-main workflow resolves the merged PR and runs verify-resolved-issues.ps1, repairing a missed closing keyword

#### The decision #1511 asked for, taken before anything was written

Dave, September 6, 2026: the runner **repairs**, it does not only report. Report-only was the cheaper
option and does not close the gap -- `verify-resolved-issues.ps1` exits 0 whatever it finds, so a
still-open issue would be one yellow line inside a green run and the repair would stay the manual step
the enqueue arm already prints. So `issues: write` is granted, and the workflow is its **own** file so
that scope never shares a job with the standing `FOLD_PUSH_TOKEN`.

### CREATE

- [x] `scripts/release/verify-pushed-merges.ps1` -- resolves the PRs a push to the trunk carried
      (`compare/{before}...{sha}`, then `commits/{sha}/pulls` per commit; merged-into-trunk only,
      deduped) and runs `verify-resolved-issues.ps1` against each
- [x] `.github/workflows/verify-resolved.yml` -- on every `push` to `main`; `contents: read` +
      `pull-requests: read` + `issues: write`, checked out with the default `GITHUB_TOKEN` and
      `persist-credentials: false`
- [x] `ship-pr.ps1`'s enqueue arm no longer frames step 6 as necessarily manual -- worded to stay true
      in a consumer that runs no such workflow; mirror regenerated
- [x] `plugins/dkj-policy/skills/ship-pr/SKILL.md` -- tells a consumer the step does not run under a
      queue, and that repair-vs-report is theirs to decide
- [x] `scripts/README.md`, `CLAUDE.md` and Sylvester's lens record the runner and the decision

### TEST

- [x] `scripts/tests/verify-pushed-merges.tests.ps1` -- 48 asserts, end to end against a fake `gh`
      with the real `verify-resolved-issues.ps1` underneath: the batch case, the repair, both
      must-not-verify filters, all three range fallbacks, partial and total lookup failure, the cap
- [x] Both defects the first smoke test found are pinned, and each was **mutation-checked**: putting
      `return ,@($shas)` back fails 7 asserts, putting the double-quoted jq filter back fails 1
- [x] Smoke-tested live in `-ReportOnly` against the real repo: the range
      `6b0b458..97dd16f` resolves PRs #1509 and #1510 from 6 commits, and the three degenerate paths
      (no `-Before`, all-zeros, unresolvable) each fall back as intended
- [x] Lint gate: 0 errors. All test suites green.

### DEPLOY: feat/1511-verify-resolved-on-merge

`ship-pr.ps1`'s step 6 -- the check that a merged PR really closed the issues its body declared, and the
repair when a closing keyword missed -- ran from exactly one place: the shipping session, right after its
own merge call returned. The merge queue took that call away, so on every queue-merged PR the step
silently did not happen. `verify-resolved.yml` now runs it off the **push** instead, which is the one
event that always sees a queue merge, and it repairs rather than only reporting.

**Score:** 3

#### What makes this deploy extra special

The permission this needed is the interesting part, and the answer was to move the job rather than to
argue for the scope. Closing an issue from CI means granting `issues: write`; the obvious home,
`fold-on-merge.yml`, checks out with a fine-grained PAT that lives up to a year and that
`actions/checkout` leaves in the workspace for every step -- so putting issue-write there would have
paired a standing credential with it. A separate workflow gets the same repair from the default,
hour-lived `GITHUB_TOKEN`, with `persist-credentials: false` because it never pushes. Widening the PAT
would have been the other route to a repair and the worse one.

**Score:** N/A

#### Pull Request

Verify a queue-merged PR's declared issues on the merge itself

