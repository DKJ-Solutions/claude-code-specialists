## Development: `fix/missing-suite-note-escalation-v1` · 20260902-200402

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

Issue #1247 reported that since the org transfer GitHub was creating no workflow runs at all, and
inferred runner entitlement at the new `DKJ-Solutions` org. Both halves were checked against the repo
before anything was built, and both fell over -- but the state the report was standing in front of is
real, and it has a cause the tooling can name.

#### What the verification actually found

**The symptom is gone and was never repo-wide.** PR #1249 (17:54) and `docs/dropped-ship-cost-overstated-v1`
(18:03) each got three check suites, minutes apart, on the same repo. Actions allocates runners
(`GitHub Actions 1000000010`) and `Branch entry` completes in under 30s. The `main` run the report saw
"stuck `in_progress` 20+ minutes later" completed `success` in 14m56s -- an ordinary duration in this
repo, not a hang.

**The one PR that has no suite conflicts with `main`, and that is the whole mechanism.** A
`pull_request` workflow runs against `refs/pull/<n>/merge`, the commit GitHub builds by merging head
into base. A conflicting PR has no such commit, so no suite is ever created and a required check can
never be satisfied. Measured:

| PR | mergeable | `refs/pull/<n>/merge` | suites |
|---|---|---|---|
| #1243 | CONFLICTING | absent | 0 |
| #1249 | MERGEABLE | present | 3 |
| #1240 | (was mergeable when it ran) | present | 3 |

#1243 was opened at 16:15:10, 68 seconds after #1241 -- the org repoint, a tree-wide diff -- merged at
16:14:02. Its base was already conflicting by the time it existed, so it never had a merge ref to run
against.

**Both escalations were measured doing nothing.** The report established that `gh pr close && gh pr reopen`
did not help. This branch added the other one: a fresh head (`c4fc686b` -> `c496b3e7`) pushed to the
same branch, firing `synchronize` rather than `reopened`. Polled for 300s -- still no run, still no
merge ref. That is the controlled half the report was missing, and it is why the note now withholds the
reopen here instead of merely rewording it.

#### What this branch does NOT do

It does not repair #1243, and it files nothing about the org. The Actions outage the issue describes
does not exist, so there is nothing to escalate to an org owner; #1243 needs its conflict resolved,
which is its own branch's work and is superseded anyway by #1249, which carries the same `Closes #1242`.

### CREATE

- [x] `Get-MissingCheckSuiteNote` takes `-Mergeable`, GitHub's own word, and branches on `CONFLICTING`
      alone -- `UNKNOWN` is GitHub still computing and is read as no information, never as a conflict.
- [x] The conflict clause REPLACES the reopen rather than joining it. Printing both leaves the reader
      choosing between them with the cheap one listed first, and the cheap one is measured not to work
      here.
- [x] `ship-pr.ps1` reads `gh pr view --json mergeable` at the step-3 refusal, guarded on its own so a
      failed read still leaves the #1234 wording intact -- best-effort, like every other fact in that
      refusal.
- [x] The docstring records the measurement, both escalations included, so the next reader does not
      re-derive it from the issue.
- [x] Plugin mirrors rebuilt via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] 23 new asserts in `scripts/tests/pr-issues.tests.ps1`: the conflict wording, the withheld reopen,
      every other `mergeable` value leaving the note untouched, case/whitespace tolerance, and an
      existing Actions suite still short-circuiting ahead of all of it.
- [x] A byte-identity assert against the pre-#1247 note when nothing is passed, so the back-compat path
      every existing caller takes is pinned rather than assumed.
- [x] Call-site asserts that `ship-pr.ps1` passes `-Mergeable` and reads it from `gh` -- without them the
      conflict branch is unreachable in production and this whole suite stays green anyway.
- [x] `pr-issues.tests.ps1`: 415 asserts, all passing.
- [x] Full local gate before the push.

### DEPLOY: `fix/missing-suite-note-escalation-v1`

When `ship-pr` refuses because no check suite exists, it now names the one cause that is checkable
rather than guessed. A `pull_request` workflow runs against `refs/pull/<n>/merge`; a conflicting PR has
no such commit, so GitHub creates no suite for it and the required check can never go green. The
refusal now says so, and prescribes resolving the conflict.

What makes it worth more than an extra sentence is what it takes AWAY. The note used to offer
`gh pr close && gh pr reopen` as the cheapest thing to try, and against a conflict that is measured to
do nothing -- twice over on PR #1243: the reopen the reporter ran, and a fresh head pushed here, polled
300s, no run either time. Offering it there sends the reader round a loop that cannot terminate, so the
conflict clause replaces it rather than sitting beside it. The refusal itself is untouched for the
fifth time; only the diagnosis moved.

The fifth case of a distinction this file has now drawn four times before -- #943 (a red required check
vs a red advisory one), #1044 (a check that went red vs a run that never started), #1219 (a verdict vs
a dropped watch), #1234 (no run vs no suite at all). Each time the sentence sent the reader somewhere no
repair exists. This one had them auditing an org's runner billing.

**Score:** 3

#### What makes this deploy extra special

`ship-pr.ps1` and `pr-issues-lib.ps1` are both mirrored into `contributing-davekjohn`, so this reaches
every consumer running that workflow -- and a conflicting PR is a state any of them can reach, on any
repo, with no org transfer involved. What made it visible here was a tree-wide merge landing 68 seconds
before a branch cut from the older base; what makes it recur elsewhere is any PR left open across a
large merge. The consumer gets the repair named at the exact moment their ship refuses, instead of a
reopen that cannot work.

**Score:** 3

#### Pull Request

The missing-suite note names the conflicting PR, and withholds the reopen that cannot fix it
