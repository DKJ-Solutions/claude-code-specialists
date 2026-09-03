## docs/merge-queue-decision

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

The merge-queue question on #1355 is a DECISION, not a defect: verify its claims, put the answer
in front of Dave, and record whichever way it goes so the reasoning is not left in a closed thread.
Answered September 3, 2026 -- no queue.

### CREATE

- [x] Verify #1355's four factual claims against the tree (settings, step 3b at `:885` vs the merge at
      `:1268`, queue-blindness across `scripts/**`, #1348's two prerequisites landed) -- all four stand;
      the readback is on the issue.
- [x] Put the decision to Dave with the price attached -- ~37s expected cost per merge against a
      settings change, a dead-code rebuild and an unresolved `--merge` unknown. Answer: no queue.
- [x] Record the decision in `.claude/specialists/lenses/05-15-extension.md`, in the merge-queue block
      that already carries #1325's history -- including the third prerequisite, deliberately unbuilt.
- [x] Repair the one claim the decision makes stale: `.github/workflows/ci.yml:92` said the decision
      "is still open".
- [x] Note in `scripts/tests/merge-queue-prereq.tests.ps1` that the suite stays -- a no is not a never,
      and guard 2 is right with no queue anywhere.
- [~] Build step-3b queue-awareness -- dropped on this repo's no-pre-emptive-fixes rule. It is dead code
      until a queue exists, and #1355's whole point was to write it down rather than build it. The shape
      is recorded in the lens so a future yes inherits it.
- [~] Flip the repo settings -- dropped: the answer is no, and it was never this branch's to flip.

### TEST

- [x] `merge-queue-prereq.tests.ps1` re-run directly -- 14/14 -- because this branch edits both that
      suite's own header and a comment in `ci.yml`, and its header is precisely the warning that on a
      page where every rule is also explained in prose, a substring match reads the prose.
- [~] The full lint + suite gate -- not run separately: `open-pr.ps1` runs it on the push, and a pre-run
      measures the same thing twice while recording nothing that gate will credit.

### DEPLOY: docs/merge-queue-decision

The merge-queue question for `main` is answered and closed: **no queue**. #1351's CI sharding took the
stale-certificate event from 31.9% at ~13 min to 12.3% at ~5 min -- an expected ~37 seconds per merge --
and against that a queue buys a repo-settings change, a `ship-pr.ps1` step-3b rebuild that is dead code
until the day of the flip, and a GitHub-side mechanism in the middle of a chain the repo's own scripts
own end to end. The throughput objection had been discharged by the same change, so this is a no on
price rather than on feasibility.

The reasoning lives in the merge-queue block of Sylvester's lens, beside #1325's history: the decision
and its price, the generalisable half (an option whose case rests on a measured cost has to be
re-argued the day that cost is measured away), the **third prerequisite left deliberately unbuilt** with
its three candidate shapes, two things a future flip should not learn the hard way (`--merge` may or may
not be accepted against a queue-backed branch; `allow_auto_merge` is `false`, so a yes is plausibly two
settings), and the condition that would reopen it -- fire rate back above ~25%, or CI past ~10 minutes.

Two stale claims went with it: `ci.yml` no longer says the decision is open, and
`merge-queue-prereq.tests.ps1` now says why its two guards stay despite the no.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing here reaches a consumer of the plugins. The lens is repo-local, and the two other edits
are a workflow comment and a test-suite header; no plugin payload changes and no released behaviour
differs.

**Score:** N/A

#### Pull Request

Record the merge-queue decision for main: no queue, and why
