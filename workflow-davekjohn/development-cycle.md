# Development cycle: `docs/verify-a-constraint-before-obeying-it-v1` · 20260823-210020

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

Repair the reach of the disable-model-invocation rule: it exists only on new-branch/SKILL.md, which a session reads only by invoking that skill. Move the general form into Chris's portable persona, which every session loads.

## PLAN

- [x] Establish whether the rule was missing or merely unreachable. It exists, in exactly one place --
  `new-branch/SKILL.md` -- and in no always-loaded layer, so a session learns that a flagged skill is
  still runnable only by invoking the one skill that says so. That is the same 'right owner, wrong reach'
  failure inbound #731 already cost this workflow, so the repair is reach, not wording.
- [x] Site it in the shared block rather than one persona: every specialist can meet a refusal, and the
  block reaches all four teams' agent defs and personas, which are loaded rather than read on demand.

## CREATE

- [x] Add the rule to `plugins/teams/agent-shared/repo-way-of-working.md` and regenerate the 30 carriers
  with `scripts/agents/build-agent-defs.ps1`.

## TEST

- [x] Gates green: lint 0 errors with `[shared] checked 30`, `agent-shared` 27 asserts, and
  `workflow-exclusivity` 24 -- the three that hold the shared blocks verbatim across carriers.
- [~] No new assert. The subject is a sentence in a shared block, and the existing `[shared]` gate already
  proves it reaches every carrier byte for byte; an assert on its wording would test the wording, not the
  behaviour, and would have to be rewritten by anybody who sharpens the sentence.

## DEPLOY: `docs/verify-a-constraint-before-obeying-it-v1`

Twice in one session this repo's own tooling was treated as forbidden when it was not: a skill carrying
`disable-model-invocation` was read as a permission gate, and a branch sat waiting on a merge while
`worktree-lane.ps1` existed to build alongside it. Both are the same mistake -- a constraint assumed rather
than read -- and the rule that dissolves the first one was already written, in `new-branch/SKILL.md`, which
a session reads only by invoking that skill. The rule now sits in the shared block every specialist
carries, generalised past skills to any inferred limit.

**Score:** 4

### What makes this deploy extra special

Every consumer's specialists carry this block, and the flag it names is on 17 skills across the two
workflows -- so the reading that declines usable tooling is available in every repo that installs them, not
just here. The general form matters more than the example: a refusal arrives phrased as authority, while a
capability nobody looked for announces nothing at all, and only one of those two failures is visible
afterwards.

**Score:** 4

### Pull Request

A refusal is not policy: verify a constraint against the repo before it becomes a decision
