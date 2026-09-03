## Development: `fix/open-pr-warn-issue-already-resolved-v1` · 20260903-110830

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

Fixes [#1282](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1282).

`open-pr.ps1`'s resolves gate already reads every `#<n>` the development document mentions, but it
only *blocks* on a mention that is still an **open** issue. The two states that mean the branch in
front of you may be a duplicate pass in silence:

1. the target issue was **CLOSED** while the branch was in flight;
2. another **open or merged** PR already carries `Closes #<n>` for it.

In #1282's own run a branch was cut to fix #1270, PR #1276 closed #1270 thirty-seven minutes later,
and the duplicate reached a gate-green PR -- discovered only at the merge conflict.

**Scope.** `open-pr` only. `new-branch.ps1` was considered and left out on purpose: it takes a
free-text name, has no issue parameter, and at creation the development document does not exist yet,
so there is nothing reliable to read a `#<n>` from. `new-branch` already warns about a stale base
"including an issue somebody else has just closed", which is this class from the other side.

**Advisory, never a block** -- the call #1282 asked for. A shared number, an issue reopened after a
wrong close, or a PR body quoting `Closes #<n>` as prose must never wedge a real PR; the author
reads one line and carries on.

### CREATE

- [x] New pure helper `Get-TargetIssueWarnings` in `scripts/lib/pr-issues-lib.ps1`: given the
  target numbers, the open-issue list (or `$null`), and a `gh pr list --search` payload, it returns
  one record per issue that has something to say (`IsClosed`, `ClaimingPrs`). Reuses
  `Get-ClosedIssueNumbers` so a bare mention in a rival PR body does not count, and skips CLOSED
  rival PRs (abandoned attempts) and this branch's own PR.
- [x] Wire it into `open-pr.ps1`'s resolves-gate block, after the existing typo warning: one
  `gh pr list --search "<n> OR ... in:body" --state all` call, only when the branch targets an
  issue; a failed query is said out loud and skipped, never fatal. Emits `Write-Warning` per
  record.
- [x] Mirror both files to the plugin (`scripts/sync/build-shared-scripts.ps1`).

### TEST

- [x] `scripts/tests/pr-issues.tests.ps1`: 18 new asserts on `Get-TargetIssueWarnings` (closed
  target, undeterminable open list, open/merged/closed rival, own-PR, mention-only, unparseable
  JSON, the full #1282 scenario, two-target split) plus 6 call-site asserts proving `open-pr.ps1`
  calls it before the push and asks for the right fields.
- [x] Full lint + test gate green (`open-pr.ps1 -GatesOnly`).

### DEPLOY: `fix/open-pr-warn-issue-already-resolved-v1`

`open-pr` now warns, before the push, when an issue the branch targets is already **CLOSED** or is
already resolved by another **open or merged** PR -- the duplicate-work #1282 carried to a
gate-green PR and found only at the merge conflict. The resolves gate was blind to it: it blocks
only on a mentioned issue that is still open.

A new pure helper `Get-TargetIssueWarnings` (`scripts/lib/pr-issues-lib.ps1`) takes the target
numbers, the open-issue list open-pr already fetches, and one extra `gh pr list --search
"<n> OR ... in:body" --state all` query, and returns one record per issue worth a word. It reads a
rival PR body with the same `Get-ClosedIssueNumbers` the gate uses, so a bare mention does not
count; a CLOSED rival PR (an abandoned attempt -- in #1282, the duplicate itself) and this branch's
own PR are never reported. `open-pr.ps1` calls it in the resolves-gate block and emits one
`Write-Warning` per record. Advisory only: a shared number or a reopened issue never blocks a PR.

`new-branch.ps1` is unchanged -- it has no issue reference to check at creation, and already warns
about a stale base "including an issue somebody else has just closed".

**Score:** 2

#### What makes this deploy extra special

N/A -- an advisory line in a workflow script; no subscriber of any service notices it.

**Score:** N/A

#### Pull Request

open-pr warns when the target issue is already closed or resolved by another PR
