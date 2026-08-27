## Development cycle: `feat/claim-the-issue-before-you-work-it-v1` · 20260827-172922

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

Issue #987: a session that picks an issue to work on claims it first, so a session on Dave's other
machine cannot pick the same one. The rule fires at **intake**, which is why it lands in Chris's
portable persona rather than on the workflow page: by the time a session reads a page about branches it
has already chosen.

#### Why not the generated shared block

`findings-become-issues.md` is the tracker cluster and is carried by 30 agent defs and personas. It is
about **filing**; this rule is about **choosing**, and only the orchestrator chooses. So the rule goes in
Chris's own prose beside that block rather than inside it -- 30 copies of a rule that 29 of them never
reach is exactly the always-on cost this repo measures for.

#### Why no script and no lens

Noticed once, so it is written down; automated the second time. And a consumer has nothing to differ on
here -- `gh issue edit --add-assignee @me` is not this repo's own mechanism -- so the rule has no repo
lens half.

### CREATE

- [x] Chris's portable persona (`../plugins/teams/team-alpha/personas/01-01-persona.md`) carries
      `## Picking up an issue -- claim it before you work it`, placed after the `findings-become-issues`
      shared block and before `## Personality & tone`.

### TEST

- [x] The rule applied to itself: #987 was assigned to the logged-in account (`DaveKJohn`) before this
      branch existed, and it is the only one of the 15 open issues carrying an assignee.
- [x] `check-plugin-integrity.ps1` + every suite green via `open-pr.ps1`.

### DEPLOY: `feat/claim-the-issue-before-you-work-it-v1`

A session that picks up an issue now claims it first, by assigning it to the account it is logged in as,
and reads the claim before choosing -- an issue that already carries an assignee is somebody's. Dave runs
this repo from two machines under one GitHub account, so the tracker is the only thing the two sessions
share: neither sees the other's branch or intent, and an unassigned issue is indistinguishable from an
untouched one. That is how the same issue gets repaired twice and found out at the merge.

**Score:** 3

#### What makes this deploy extra special

**The rule states what the claim does not prove, which is the half that would otherwise be learned the
hard way.** Where both sessions run under one account the assignee names the account and never the
machine -- so a claim is a binary *taken*, not a lock, and a claim with no branch and no recent activity
is a question for the owner rather than a closed door. Without that sentence the first stale assignment
teaches a session to treat the marker as authoritative and leave real work parked.

**It sits in the persona, not on the workflow page, because the trigger is intake.** Claiming is not a
branch mechanic a consumer opts into with Dave's method; it is what an orchestrator does the moment it
chooses what to work on. So any consumer whose repo has a tracker and more than one worker gets it, and
gets it before the choice rather than after.

**Score:** 2

#### Pull Request

Claiming an issue on pickup, so a second machine can see it is taken
