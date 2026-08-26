## Development cycle: `fix/refuse-only-on-a-required-check-v1` · 20260826-191832

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

Issue #943: ship-pr refuses to merge whenever `gh pr checks --watch` exits non-zero, which is any check failing -- while the `main` ruleset requires only `lint-en-tests`. One broken non-required workflow (claude-review, #942) therefore blocks the whole chain. Keep the wait exactly as #831 measured it and change only the verdict.

#### What the report got right, verified against the file

`scripts/release/ship-pr.ps1` step 3 refuses on `$checks.ExitCode -ne 0` from
`gh pr checks <pr> --watch`, and the comment above it reads *"Branch protection blocks the merge until
green, so a non-zero here means we must NOT merge."* Both quoted lines are in the file as reported. The
distinction the decision needs is already read one step lower -- `gh pr checks --required` -- purely to
LABEL the wait report (#831).

Measured on the open PR #937 while writing this branch, and it settles the mechanism:

| command | result |
|---|---|
| `gh pr checks 937 --json name,bucket,state` | three records; `claude-review` `fail`, `branch-entry` and `lint-en-tests` `pass` -- **exit 0** |
| `gh pr checks 937 --required --json name,bucket,state` | one record, `lint-en-tests` `pass` -- **exit 0** |

So `--json` mode reports the state in the payload and does **not** carry it in the exit code. The verdict
therefore has to be read from `bucket`/`state`, never from the exit code of the JSON read -- which is also
why the non-JSON `--watch` stays exactly where it is as the thing that waits.

#### Which of the issue's three directions this takes, and why

**Direction 2** -- keep waiting on every check, change only the verdict. It leaves #831's measured answer
(the wait governs 23% of the time at a median cost of 0s, so keep it) untouched, and it changes one
decision rather than the query. Direction 1 would also stop waiting on a *pending* non-required check,
which is a second change nobody measured. Direction 3, a flag, the issue itself rates weakest.

### CREATE

- [x] `Get-MergeBlockVerdict` in `scripts/lib/pr-issues-lib.ps1`: decide, from the two
      `gh pr checks --json` payloads, whether a *required* check is what failed -- the selection being
      the testable half, exactly the split `Get-CheckWaitReport` already uses
- [x] `scripts/release/ship-pr.ps1` step 3 consults that verdict on a non-zero `--watch` exit: refuse
      when a required check failed or has not finished, continue with a loud `NOT required` line
      otherwise -- and correct the comment carrying the wrong premise
- [x] mirror both files into the plugin with `scripts/sync/build-shared-scripts.ps1`
- [x] the SAME 5.1 flattening trap in the existing `Get-CheckWaitReport` required-name parse, found by
      walking into it here first -- same file, same required/not-required distinction, so repaired in
      this branch rather than filed

### TEST

- [x] asserts in `scripts/tests/pr-issues.tests.ps1` for the whole decision table, the
      unreadable-required fallback included, since that one must keep refusing
- [x] the full gate: `scripts/lint/check-plugin-integrity.ps1` plus every suite

### DEPLOY: `fix/refuse-only-on-a-required-check-v1`

`ship-pr.ps1` judged the merge on the exit code of `gh pr checks --watch`, which is non-zero when **any**
check fails. The `main` ruleset requires only `lint-en-tests`, so one broken advisory workflow refused
every merge in the repo: on August 26, 2026 `claude-review` was red on every PR (#942) while GitHub itself
reported those PRs as `MERGEABLE` / `UNSTABLE` -- its own word for "mergeable, with a non-required check
failing" -- and the script reported `BLOCKED`. Getting a branch out meant hand-running the two step-4
gates whose whole point is that forgetting them is impossible, which is the argument for repairing the
judgement rather than documenting the workaround.

The wait is untouched. #831 measured it (n=100, the non-required check governs 23% of the time at a median
cost of 0s) and Dave kept it; only the verdict moved. A failing required check still refuses exactly as
before, and so does an unreadable required-check list -- from inside the script, "this ruleset requires
nothing" and "the required checks have not reported yet" look identical, so that case keeps refusing
rather than guessing.

**Score:** 4

#### What makes this deploy extra special

A second, older defect surfaced while proving the first, in the same file and the same distinction.
`Get-CheckWaitReport`'s required-name parse walked into the Windows PowerShell 5.1 array-flattening
pitfall this very script warns about at its step 2: written inline as
`@(@($json | ConvertFrom-Json) | ...)` it collapses the payload into **one** element whose `.name`
member-enumerates to every name at once, so two required checks became the single string `a b`, `-contains`
never matched, and the wait was labelled `NOT required` for a check that was required. Measured both ways
on August 26, 2026. It had been there since #831 and was invisible here for a reason worth keeping: this
repo's ruleset requires exactly **one** check, and a one-element JSON array is handed through as the
object itself -- so the only shape anybody ever ran was the one shape that happens to work. A consumer
with two required checks had been reading a wrong label all along.

**Score:** 3

#### Pull Request

ship-pr judges the merge on the required checks, not on every check
