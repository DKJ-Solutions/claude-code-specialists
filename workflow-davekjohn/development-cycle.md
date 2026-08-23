# Development cycle: `docs/probe-and-recency-lessons-v1` · 20260823-173808

<!--
     The plan for this branch. Every step must be resolved before the PR: open-pr and
     ship-pr both refuse while anything is still "- [ ]", and there is no -Force.

       - [ ] not done yet
       - [x] done
       - [~] dropped -- why it turned out not to be needed

     The dropped mark exists so nobody is pushed into ticking a box for work they did
     not do. It keeps its line and its reason, which is the half worth reading later.

     PLAN / CREATE / TEST / DEPLOY are the arc, not a quota: a phase with nothing
     under it is a statement that this branch had nothing there. The headings are
     invisible to the gate, which reads step marks only.

     DEPLOY takes no steps of its own. It is not a step but the result -- the
     section at the foot of this file, which is the part that travels verbatim into
     CHANGELOG.md at the merge. So a step written for after the merge is refused
     here: what happens after the merge is what DEPLOY describes, not a box to tick.
-->

## PLAN

Two lessons from the branch that made the development cycle branch-lifetime, recorded where they will be
read rather than left in a session.

**Both go to the portable half, not to a lens**, which is this repo's default: the lens is for what a
consumer would genuinely have to differ on, and neither of these is repo-specific. The first is a
PowerShell trap and belongs beside the four already in Sylvester's manual — the fourth of them is its
sibling, both being a command quietly declining to inherit the directory you are standing in. The second
is about how any specialist argues when the owner proposes a change, so it belongs in the shared block
every advising agent already carries.

**The measured instance stays with the rule** rather than moving to a skill. The convention that skills
carry the evidence is about the evidence behind a *procedure*; a trap's measurement IS the rule, because
what makes it worth writing down is that it happened and produced clean output while doing it.

## CREATE

- [x] `plugins/teams/team-alpha/manuals/05-15-manual.md`: a fifth trap -- a failed `Set-Location` writes a non-terminating error and the block runs on, in the previous directory, reporting success against the wrong tree. The remedy is stated as failing closed (`-ErrorAction Stop`, or asserting `(Get-Location).Path` before the first write) and generalised past `cd`: verify the aim, not the result.
- [x] The same section's heading and closing line said "four" while its intro still said "Both were measured" from when there were two. Corrected to five in all three places -- a stale count in a document about counting carefully.
- [x] `plugins/teams/agent-shared/repo-way-of-working.md`: a second bullet -- how recently something was decided is not an argument against changing it. Placed in that block because its existing bullet already ends on "proposing a different way of working is something you do when you are asked for it", and this is what to do when the owner does ask.
- [x] `scripts/agents/build-agent-defs.ps1` run: 30 carriers updated across all four teams.

## TEST

- [x] No script behaviour changed, so there is nothing to add a suite for. What holds this change is the lint gate: `[shared]` proves the 30 carriers match the block byte-for-byte, and `[link-scan]` proves the manual's new prose introduced no dead link.
- [x] Lint and the full suite green through `open-pr.ps1`.

## DEPLOY: `docs/probe-and-recency-lessons-v1`

Two rules learned while making the development cycle branch-lifetime, written into the layer that travels.

Sylvester's manual gains a fifth PowerShell trap: **a failed `Set-Location` does not stop the block that
follows it.** It writes a non-terminating error, execution continues in the directory you were already
standing in, and every later command succeeds against the wrong tree while its output reads exactly as it
would have been right. Measured here, expensively: a probe whose fixture path contained `$PID` — a value
that differs between processes — ran a fold against this repository instead of its fixture, deleting a
tracked file and committing. The remedy is that a throwaway probe fails closed, and it generalises past
`cd`: a probe pointed at the wrong target is indistinguishable from one that worked, so what has to be
verified first is the aim rather than the result.

The shared `repo-way-of-working` block, carried by 30 agent defs and personas across all four teams, gains
a second bullet: **how recently something was decided is not an argument against changing it.** Its
existing bullet already ends on "proposing a different way of working is something you do when you are
asked for it"; this is what to do when the owner does ask. Argue from mechanism, read whether the original
reasoning still holds, name the part that has expired — and do not treat an owner changing their mind as
something to be talked out of.

**Score:** 2

### What makes this deploy extra special

Every consumer's agents get the second rule, since it ships in a block all four teams carry. It changes
how a specialist argues rather than what any script does, so nothing to run and nothing to migrate — but a
consumer who has noticed their specialists pushing back on reversals will find that stops.

**Score:** 2

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

Two lessons: a probe that fails closed, and the age of a decision
