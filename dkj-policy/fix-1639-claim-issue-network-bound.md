## fix/1639-claim-issue-network-bound

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

`claim-issue.ps1`'s three `gh` calls were unbounded while every sibling script bounded its own
network calls. The finding's own diagnosis is the interesting half and it verified: the shared value's
comment opened *"THE BOUND A GIT NETWORK CALL PASSES"* and enumerated **three** sites, while six files
read it and two of them passed it to `gh`. That comment is where a script author goes to learn the
policy, so a `gh`-only script read it as being about somebody else.

So the repair is two-part: bound the calls, and stop the one place that states the policy from
describing itself inaccurately. The enumeration is removed rather than corrected -- a list in a comment
cannot be kept true by any gate, and it had already gone stale twice over.

#### The 120s figure, which the finding was right to question

It is not re-derived. Two minutes is sized off a git push (twenty times the slowest honest one
measured here), and that is now said out loud beside it: the reuse is sound only in the direction that
matters -- a `gh issue view` that has not answered in two minutes is stalled, not slow -- so it reads
as an upper bound on patience rather than a model of either command.

### CREATE

- [x] All three `gh` calls carry `-TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds`.
- [x] The pre-write read distinguishes a stall from the three verdicts it otherwise lists -- none of
      those three can produce a hang, so sending a reader down that list would misdescribe the bound.
- [x] **The write gets its own branch, ahead of the failure branch.** `gh issue edit` changes the
      tracker, so a write that reached the network and never answered may have landed: it reports
      *this run does not know*, never "the claim failed", and names re-running as the safe way out
      (an already-landed claim comes back as `already-yours`).
- [x] The read-back's `$why` gains the timeout reason. #1628 had written that branch with a note
      saying a `TimedOut` arm could never print because no timeout was passed -- true the day it was
      written, and this is the change that makes it reachable, exactly as #1639 predicted.
- [x] `native-capture-lib.ps1`: the bound's comment names `git OR gh`, drops the three-site list for a
      `grep` line, and states which command the number was sized off.
- [x] The `-TimeoutSeconds` docstring says "push, fetch" no longer -- it names `gh` too, which is the
      sentence a `gh`-only author actually read.
- [x] The skill page gains the bound, since a consumer has only that page.
- [x] Mirrors regenerated.

### TEST

- [x] `claim-issue.tests.ps1`: 64 asserts, 0 fail. The bound is asserted as an **equality** between
      the count of `gh` calls and the count of bounds, not as "three" -- a fourth call added later is
      the next instance of this defect, and a test pinned to 3 would pass while it went unbounded.
- [x] `native-capture.tests.ps1`: 70 asserts, 0 fail. The comment's accuracy is pinned, including a
      **measured** assert that more than three files read the bound -- so the paragraph's claim about
      the tree is a fact rather than prose.
- [x] Two text asserts were repaired rather than worked around, both found by this branch tripping
      them: one matched the word `exit` inside a comment when its subject was an `exit` statement, and
      one would have forbidden the lib from quoting its own old wording as history. A test a true
      comment can fail teaches the next author to write a worse comment.

### DEPLOY: fix/1639-claim-issue-network-bound

`claim-issue` bounds all three of its `gh` calls at the shared network timeout, so a stalled `gh` is
reported instead of waited out. This is the worst step in the workflow to hang in: the claim is the
first move of an issue-driven assignment, so a stall there is a session that never starts with nothing
printed to say why -- and the shape is not hypothetical, since the measurement behind #1628 is a
checkout where `gh` returned exit 1 intermittently while working fine from the shell, minutes apart,
in one session.

**A timed-out write is reported as an unknown rather than a failure.** The read and the read-back only
ask questions, so a stall costs nothing but the answer; `gh issue edit` changes the tracker, and a
write that never reported back may have landed. Saying "the claim failed" there would be a claim about
the tracker the run cannot make, so it says it does not know, stops, and names re-running as the way
out -- an already-landed claim comes back as *already yours*.

And the reason the gap existed is closed too. The shared bound described itself as *"THE BOUND A GIT
NETWORK CALL PASSES"* and listed three sites while six files read it and two passed it to `gh`. That
comment is the one place a script author learns the policy, so the policy read as somebody else's. It
now names both commands and points at a `grep` instead of carrying a list no gate can keep true.

**Score:** 3

#### What makes this deploy extra special

Every consumer of this workflow runs this claim step, and it is the first thing their session does
with an issue number. Unbounded, a `gh` that never answers there presents as a session that simply
sits -- no output, no verdict, nothing naming the cause -- which is the failure that costs an operator
the most time to diagnose and the least to fix once named. They also get the corrected policy comment,
which is what stops the next `gh`-only script in their tree from repeating this.

**Score:** 3

#### Pull Request

claim-issue bounds its three gh calls, and the shared bound stops describing itself as git-only
