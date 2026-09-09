## fix/1710-refreshbody-recheck

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

The `branch-entry` CI check judges two things: that the branch document carries a written entry, and
that its DEPLOY section still matches what the PR published. **The second half is about the PR BODY**,
and the trigger was about pushes.

`on: pull_request:` with no `types:` list defaults to `[opened, synchronize, reopened]`. A body edit is
none of those -- and `open-pr.ps1 -RefreshBody`, the documented remedy for exactly the drift this check
reports, edits the body through the API and prints `Everything up-to-date`. So the one action that
repairs the finding could not make the check look again.

#### Measured on PR #1707, which is my own

| time | what happened |
|---|---|
| `11:55` | pushed a commit that legitimately changed the DEPLOY section |
| `11:57:26` | `branch-entry` ran and **correctly** reported drift |
| `~12:05` | ran `open-pr.ps1 -RefreshBody`; it republished the section and pushed nothing |
| `12:08:59` | `ship-pr` merged -- its own arm of the same lock read the refreshed body and **passed** |

The merge was right, and `ship-pr` said the right thing about the red check
(*"'branch-entry' failed, and the ruleset does not require it ... nothing here needs undoing"*). What
it did not say is that the check now described a state that had stopped being true eleven minutes
earlier. **Two arms of one lock reaching opposite verdicts on one PR** -- and `ship-pr.ps1`'s own
comment says why that matters: the two call `Test-DeployLock` deliberately *"so 'diverged' has one
definition rather than two"*. One definition, and only one of the two arms could be asked twice.

#### The repair, and the two routes not taken

Adding `edited` to the trigger makes it match the subject: the check reads the body, so it runs when
the body changes. One line.

- **Make `-RefreshBody` trigger a run** (`workflow_dispatch`, or an empty commit). Declined: it has
  nothing to push *by design*, and an empty commit would re-date the certificate `ship-pr`'s stale-CI
  gate reads -- repairing a cosmetic red by disturbing a real gate.
- **Have CI's arm stop reporting the lock**, leaving it to the merge, where the refusal actually lives
  and where there is no `-Force`. Defensible, and rejected as the bigger change: the CI arm exists for
  the PR merged from the GitHub UI, which meets no local gate at all, so removing it would reopen the
  hole it was added for (#884).

#### What it costs, stated because a trigger widening always costs something

`edited` also fires on a title change and a base change. A person editing the description therefore
pays one ~20 s job. That is the whole price. It does not fire on a comment, a label, or a review.

#### Verified live on this branch's own PR, not just asserted

The suite can only pin the workflow's **text**. Whether GitHub honours a `types:` list from the PR's
own head ref -- rather than from the base branch, where this change does not exist yet -- is a
different question, and it is the one the fix actually depends on. Measured on PR #1712:

| time | event |
|---|---|
| `12:32:58` | `branch-entry` ran on `opened` -- the baseline, one run on this branch |
| `12:34:00` | edited the PR **title**, which fires `pull_request: edited` and touches no body |
| `12:34:06` | **a second `branch-entry` run appeared**, six seconds later |

So the trigger takes effect from the PR that introduces it, and the fix works end to end. The title was
edited rather than the body on purpose: a body edit would have risked drifting the DEPLOY section from
what the PR published, which is the very finding this branch repairs -- and the title fires the same
event. It was restored immediately afterwards.

### CREATE

- [x] `types: [opened, synchronize, reopened, edited]` on the workflow, with the reason and the #1707
      timeline written beside it rather than only in the issue
- [x] Keep the three defaults explicitly: naming `types:` at all **replaces** the default list, so
      omitting them would have traded a body edit for every push

### TEST

- [x] `branch-entry-gate.tests.ps1` now reads the workflow -- it tested only the script until now and did
      not touch `.github/` at all: that `edited` is present, that each of the three defaults survived,
      that the `branches: [main]` filter survived beside the list, and that the reason is written at
      the workflow rather than only in the suite
- [x] The nesting asserted in the suite as GitHub reads it (`on`/`pull_request`/`types`/`branches` at
      columns 0/2/4/4) -- the one way this change fails silently, since every other assert passes on a
      `types:` at the wrong depth and GitHub then reads the workflow as having no list at all
- [x] Verified live on PR #1712 rather than only asserted: a title edit at 12:34:00 produced a second
      `branch-entry` run at 12:34:06, so GitHub honours the new `types:` list from the PR's own head ref
- [x] The lint gate (`check-plugin-integrity.ps1`) -- 0 errors

### DEPLOY: fix/1710-refreshbody-recheck

The `branch-entry` gate now re-runs when a pull request's body is edited, which is what
`open-pr.ps1 -RefreshBody` does. Half of what that check judges is the PR body -- whether the DEPLOY
section still matches what the review approved -- while its trigger listed only the push events, so the
documented repair for a drifting section could not clear the finding it was repairing. Measured on
PR #1707: the check reported drift, `-RefreshBody` republished the section, `ship-pr`'s own arm of the
same lock read the refreshed body and passed, and the merge landed with the CI arm still red on a state
that had stopped being true eleven minutes earlier. The two arms share one definition of "diverged" on
purpose; now they also share the chance to be asked twice.

**Score:** 2

#### What makes this deploy extra special

N/A -- the workflow is this repo's own and travels to nobody. A consumer running the shipped
`branch-entry` gate keeps whatever trigger their own copy carries, and nothing in the plugin changes.

**Score:** N/A

#### Pull Request

The branch-entry gate re-runs when the PR body is edited, which is what -RefreshBody does
