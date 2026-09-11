## fix/1860-shared-fetch-freshness

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

claim-issue and new-branch fetch the same remote seconds apart; a shared freshness stamp lets whichever runs second skip, and halves the worst-case stall back to one network bound.

#### What was verified before building

Both call sites read against the tree, not against the report:

- `scripts/task/claim-issue.ps1` runs `git fetch --quiet` for the parked-fix scan (#1853), bounded at
  `$NativeCaptureNetworkTimeoutSeconds`.
- `scripts/task/new-branch.ps1:384` calls `Get-TrunkGap -FetchAllRefs`, which at
  `scripts/lib/entry-scaffold-lib.ps1:5707-5709` runs `git fetch origin --quiet`.

Both bounds are independent, so an unreachable remote stalls the opening of an assignment twice. The
report stands as filed.

#### The option taken, and why not the other two

The issue lists three. **One shared seam** is taken, because it is the only one that touches the half
the issue calls "the part worth fixing": a skip on a recent FAILED attempt is what halves the worst
case back to one bound. Dropping claim-issue's fetch was declined on #1853's own reasoning -- the
case that check exists for is a branch pushed by another machine, which a cold checkout would then
miss. Doing nothing leaves the doubled stall ceiling.

**And the option as filed turned out to be half right, which TEST records.** It reads as symmetric --
"origin was fetched N seconds ago, skip" -- and that half was built, measured and dropped, because a
skip on a recent SUCCESS blinds the very probes a push-by-another-session has to be seen by. What
ships is the failure half alone. This paragraph is the plan being corrected by the work rather than
the plan having been right.

#### The design, and the three things it must not get wrong

1. **Scope.** `git fetch origin <trunk>` is not `git fetch origin`. A record says which of the two it
   was, and the coverage is one-directional. *Sharpened by the narrowing:* the reason is no longer
   #1139's missing ref (nothing skips on a success any more) but that a narrow fetch can fail for a
   reason about that ref -- "couldn't find remote ref main" -- which says nothing about whether the
   remote would answer at all. A narrow failure must not invent an outage.
2. **The remote's identity.** claim-issue fetches the DEFAULT remote; `Get-TrunkGap` fetches
   `origin` by name. The issue's own "Not measured" section names this: in a checkout whose default
   remote is not `origin` they are different calls. The record is keyed on the resolved remote name,
   so that repo skips nothing and the premise never has to hold there.
3. **`.Fresh` may not start lying.** `Get-TrunkGap`'s `.Fresh` drives new-branch's "(git fetch
   failed -- the real gap may be larger)" label. *Answered by the narrowing rather than by a rule:*
   a skipped retry stands on a FAILURE, so `.Fresh` is `$false` and that label is accurate -- the
   field keeps the meaning it has always had, and the wording in `Get-TrunkGap`'s header is
   unchanged apart from naming the new case.

### CREATE

- [x] `scripts/lib/fetch-attempt-lib.ps1` -- the seam: the record in the git common directory, the scope model, and `Invoke-RecordedRemoteFetch` (consult, fetch, record) as one call
- [x] Register it in `scripts/lib/shared-scripts-lib.ps1` and give it its row in `plugins/dkj-policy/scripts/README.md`, so the plugin mirror carries it and the mirror-list gate stays green
- [x] `Get-TrunkGap` routes its fetch through the seam and gains `-RecentFailureSeconds` (0 = today's behaviour, so the fold and every other caller are untouched)
- [x] `new-branch.ps1` passes the window; `claim-issue.ps1`'s parked-fix fetch goes through the same seam and carries a skipped-on-failure note
- [~] The symmetric seam -- skip on a recent SUCCESS too, which is what would have removed the duplicated ~700ms -- was built, measured against this repo's own suite, and **dropped**. See TEST.
- [x] `scripts/tests/fetch-attempt.tests.ps1` -- the failure-only contract, the scope model, the remote key, the failure carry, and the worktree scope
- [x] The seven suites that copy `entry-scaffold-lib.ps1` into a fixture now copy its new sibling too -- reported by `fixture-lib-deps.tests.ps1` (#1693), which is the gate that exists for exactly this

#### The branch name is one word stale, deliberately not renamed

`fix/1860-shared-fetch-freshness` was cut before the measurement below, and the seam is an
attempt RECORD rather than a freshness window. Renaming the branch means a new branch, a new
development document and a deleted remote head, for a word; the document, the PR title and the
changelog entry all carry the accurate description, and the branch still names the issue.

### TEST

**The first design was wrong, and this repo's own suite is what said so.** #1860's first option --
one shared seam, so whichever of the two callers runs second is let off -- was built exactly as
filed: skip on any recent attempt, success or failure. It passed its own new suite (52 asserts) and
then took **eleven asserts** off `new-branch.tests.ps1`:

- case **(y1)**, the #1439 duplicate-branch collision: two runs seconds apart, with another session
  pushing to the same branch in between. The second run read `refs/remotes/origin/<branch>` from the
  first run's fetch, saw the old tip, and printed no warning.
- case **(v)**, the #1139 parked-branch resume, for the same reason one ref along.

Both reproduce *precisely* the interval a freshness window covers, and *precisely* the event those
two probes exist to see. So the symmetric seam buys ~700ms by blinding the checks whose entire
subject is a push somebody else has just made -- which is the same trade #1853's own review refused
when it declined to drop `claim-issue`'s fetch altogether.

**The failure-only skip trades nothing, and that asymmetry is the whole design.** A fetch that failed
refreshed no ref, so reporting it instead of repeating it removes no information from any check
downstream; what it removes is a second two-minute bound against a remote that was unreachable
seconds ago. So the branch ships the half of #1860 that costs nothing and leaves the half that costs
a guardrail -- stated as a decision in the lib header, in both call sites, and in case 3 of the new
suite, which is the assert a later "optimisation" would delete first.

**Measured on this checkout, live `origin`** (before the design narrowed; the numbers are what made
the duplicate visible):

| call | warm |
|---|---|
| `Get-TrunkGap -FetchAllRefs`, real fetch | 907ms |
| the same call, skipped on a record | 162ms |
| a narrow record against an all-refs request | 561ms -- a real fetch, as it must be |
| a recorded failure, carried | 48ms, `Fresh=False`, git's own line carried |

**Gates:** `check-plugin-integrity.ps1` green (0 errors, after the mirror-list row the
`[shared-script-list]` check correctly demanded). Suites re-run after the narrowing:
`fetch-attempt` 51/51, `new-branch` 255/255, `claim-issue` 137/137, `entry-scaffold` 820/820,
`fixture-lib-deps` 23/23. The full pool runs on the PR.

**Not covered, stated rather than papered over:** the stall itself. Every assert here drives a
reachable local remote or a hand-written record; nothing in the suite makes a remote hang for two
minutes, so what is proven is that a recorded failure suppresses the retry and carries its reason --
not that the wall-clock halves. That one is arithmetic over a bound the suite cannot spend.

### DEPLOY: fix/1860-shared-fetch-freshness

An unreachable `origin` no longer stalls the opening of an issue-driven assignment twice. `claim-issue`
and `new-branch` run back to back by design and both fetch the same remote, each bounded at two
minutes independently -- so a session that had nothing on screen yet could wait four. They now share
one record of the last fetch attempt (`scripts/lib/fetch-attempt-lib.ps1`, mirrored into the plugin),
and the second call reports the first one's failure instead of buying another bound.

**A recent SUCCESS never lets a fetch be skipped, deliberately** -- the symmetric version of this was
built first and refused by `new-branch.tests.ps1`, whose #1139 and #1439 cases reproduce two runs
seconds apart with another session's push between them. So the duplicated ~700ms #1860 also reports
is still paid: it is what those two probes are reading.

**Score:** 2

#### What makes this deploy extra special

The suite refused the design, not the implementation. The seam was built to the issue's own first
option, passed every assert written for it, and then took eleven off an unrelated file -- each one a
guardrail about another session's push, which is the event a freshness window is exactly wide enough
to hide. The half that survives is the half with no counterparty: a failed attempt refreshed nothing,
so standing on it blinds nothing.

**Score:** N/A

#### Pull Request

One shared fetch-attempt record, so an unreachable origin is not waited out twice
