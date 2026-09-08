## fix/1628-claim-readback-three-states

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

#### The finding, and the one part of it that had to be decided rather than read

[#1628](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1628) reports that
`claim-issue.ps1`'s read-back holds a single `$landed` boolean standing for two opposite facts, and
prints the wrong one. Verified against the tree before anything was written: the block is exactly as
reported.

What the issue deliberately left open is whether the third state should **block**. It prescribes the
shape ("claimed, refused, and could-not-verify -- the last naming the exit code ... the way
`new-branch` already words its own unreachable-`gh` line") and `new-branch`'s line does not block. Two
facts settle it in the same direction: the write being checked returned 0, and the read *before* the
write answered normally -- the script exits earlier if it did not. So the protection against duplicate
work has already succeeded by that point, and a refusal there is a false stop on a live claim.

- [x] Verify the reported block against the current tree -- reported shape confirmed verbatim
- [x] Establish what the write and the pre-write read prove, since that decides whether state three blocks
- [x] Check whether `TimedOut` is a reachable reason here -- it is not; this script passes no `-TimeoutSeconds`

### CREATE

- [x] Split the verdict: `$readOk` (did the read answer) apart from `$landed` (what it said)
- [x] Gate the existing refusal on `$readOk -and -not $landed`, message unchanged -- it was only ever right about that state
- [x] Add the `-not $readOk` branch: a `[WARNING]` naming the measured exit code, saying the claim most likely landed, handing over the one command that settles it, and **not** exiting
- [x] Stop the closing `[OK]` asserting what the read-back could not measure -- it now says `(unconfirmed -- see the warning above)` in that state, while still pointing forward
- [x] Mirror every change into `plugins/dkj-policy/scripts/task/claim-issue.ps1` -- held byte-identical
- [x] Update the skill page's read-back section: the three states as a table, and why the third does not block

### TEST

- [x] `claim-issue.tests.ps1`: nine source-shape asserts, the class this suite exists for -- the defect is a *wrong message* on a path no behavioural test reaches
- [x] Prove the new asserts can fail: the `TimedOut` one first matched the comment explaining the decision rather than code, and was tightened to `[regex]::Escape('$after.TimedOut')`
- [x] End-to-end, `gh` stubbed to fail **only** the read-back: `[WARNING]`, the run proceeds, and the tracker confirms the claim did land -- #1628's own measurement, now handled correctly
- [x] End-to-end, `gh` stubbed to answer the read-back with an empty assignee list: `[ERROR]`, treat as unclaimed, exit 1 -- the refusal is unchanged
- [x] Full suite + lint gate via `open-pr.ps1`

### DEPLOY: fix/1628-claim-readback-three-states

`claim-issue` no longer reports a read it could not make as a claim the tracker refused. The read-back
held one boolean for two opposite facts -- "gh answered and your account is not there" and "gh never
answered" -- and printed the first for both, naming a cause it had not measured ("most often an account
with no write access") and telling you to treat the issue as UNCLAIMED. Measured on the claim of #1623:
that fired, and a plain `gh issue view` on the same checkout seconds later showed the claim sitting
there. Followed literally by a second session, it inverts the duplicate-work hazard the step exists to
prevent. There are now three states. A read that answered and found your account absent still refuses,
with the same message, because that is the one state it was ever right about. A read that did not
answer prints a warning naming the exit code, says the claim most likely landed and why, hands over
`gh issue view <n> --json assignees`, and **does not block** -- a claim is the opening of the work, so a
false stop costs the whole assignment. The closing verdict says `(unconfirmed)` in that state rather
than asserting a claim it could not confirm.

**Score:** 3

#### What makes this deploy extra special

A consuming repo runs this script as its claim step, and this is the failure mode it hits: an
intermittent `gh` on an otherwise healthy checkout. Before this, that session was told its claim was
refused and to treat the issue as unclaimed -- so it either stopped, or re-claimed work it already
held. Now it is told the claim probably landed, told how to confirm it, and carries on. Nothing
tightens: a genuine refusal refuses exactly as before, with the same words and the same exit code.

**Score:** 3

#### Pull Request

claim-issue tells an unverified claim apart from a refused one
