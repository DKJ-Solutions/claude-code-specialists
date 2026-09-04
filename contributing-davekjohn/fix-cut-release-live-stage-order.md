## fix/cut-release-live-stage-order

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

#### What inbound #1378 asks, and what the verification changed about it

[#1378](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1378) reports that
`cut-release/SKILL.md` states **cut-then-push** as a rule for a live stage, while a live stage whose
push can *fail* needs **push-then-cut** — otherwise the tag, the GitHub Release and the audience
document describe a state that never reached a customer. It offers three shapes: (1) state both
orders and the condition, (2) a `Get-LiveStageCutOrder` seam, (3) declare cut-then-push universal
with the failure mode named.

The six-way inbound check passes — and it found something the report did not have. **The
contradiction is already inside this tree**, between two pages that ship from here:

- `plugins/workflows/contributing-davekjohn/skills/cut-release/SKILL.md` — *"Block 1 always runs
  first; Block 2 only follows it."*
- `plugins/teams/team-shopify/manuals/05-21-manual.md` — *"Executing the live push … only when
  the user decides to push; **the release is then cut** by the release manager."*

The second is the Shopify case the first forbids, and it is the same order the consumer runs as a
standing rule dated 2026-07-22. So **option 3 is refuted by this repo's own tree**, not merely by a
consumer's preference, and what is left is a craft choice between 1 and 2.

#### Why option 1 and not the seam

No script reads the answer. `Get-LiveStage` gates whether a whole *block* prints; the order is a
sentence inside that block, and the condition that picks it — can this push fail or be partial? —
is a property of the target the consumer already describes in `Get-LiveStage`'s own prose. A second
function would cost a `script-contract-lib.ps1` record, a blueprint entry and asserts, to carry a
value only a human reading a checklist consumes. The escalation stays available if a second
live-stage consumer ever disagrees with the default.

#### Scope

The rule lands in the **shared page**, per the source-is-the-default convention. This repo's
`CONTRIBUTING.md` 4.7 restates the fixed order for a repo that is not this one, so it is repointed
rather than left to contradict the page it layers on. `CONTRIBUTING-portable.md` is untouched — it
has no release chapters, correctly.

### CREATE

- [x] `cut-release/SKILL.md` Block 2: state both orders, the condition that picks one, and name the
      stranded-release failure mode; keep cut-then-push as the default
- [x] `cut-release/SKILL.md` "Order matters" bullet + the "in order" line under *What the skill does*:
      stop asserting a single order for a live stage
- [x] `cut-release/SKILL.md` marker step: say why the hand step is correct-by-construction under one
      order and wrong-by-construction under the other — the report's sharpest observation
- [x] `contributing-davekjohn/CONTRIBUTING.md` 4.7: repoint the live-stage clause at the shared
      condition instead of restating a fixed order

### TEST

- [x] `check-plugin-integrity.ps1` + all suites green via `open-pr.ps1`
- [x] `script-contract.tests.ps1` still finds `Get-LiveStage` in the real `SKILL.md` (it asserts on
      that text)

### DEPLOY: fix/cut-release-live-stage-order

The `cut-release` skill stated **cut-then-push** as a rule for a repo with a live stage — *"Block 1 always
runs first; Block 2 only follows it"* — and this repo's `CONTRIBUTING.md` restated it at 4.7. It is a
default now, and the repo picks the order from one property of its live target.

**The condition, stated where the block is walked:** a push that cannot meaningfully fail — it either runs
or errors loudly, nobody else writes to the target — cuts first, which is what most repos with a deploy
step want, because the audience document then exists before anything reaches a customer. A push that can
**fail or be partial** — no locking on the target, third parties editing it through a web UI while you
work, a drift check that legitimately refuses, a per-file rather than wholesale push — pushes first and
makes the cut the documented closing act of the push.

**What the default gives up, now named rather than left to be discovered.** Cutting first in front of a
fallible push produces a **stranded release**: the tag, the GitHub Release and the audience document all
exist, permanently, describing a state no customer ever saw. Nothing detects it — every artefact is
well-formed — and the only witness is whoever watched the push refuse. The `← LIVE` marker makes it
visible: its own reasoning is that *only the person who did the push knows it succeeded*, which under
cut-then-push makes the marker wrong by construction from the moment the cut lands until a human moves it.
In the repo that reported this, that marker sat two releases behind.

**No seam, deliberately.** `Get-LiveStageCutOrder` was the obvious shape and would have cost a script
contract record, a blueprint entry and asserts to carry a value no script reads — the order is a sentence
a person walks past in a checklist, where `Get-LiveStage` gates whether the block prints at all. It stays
available if a second live-stage consumer ever wants the checklist rendered in its order rather than told
which orders exist.

**This was already the tree contradicting itself, which is what settled it against declaring the old rule
universal.** `team-shopify`'s webshop-manager manual has documented push-then-cut for exactly this case
all along — *"only when the user decides to push; the release is then cut by the release manager"* — so
two pages shipped from one repo disagreed, and inbound
[#1378](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1378) found it from the outside.

**Score:** 3

#### What makes this deploy extra special

A checklist that imposes itself is only as good as its right to impose. This page had one rule it could
not justify, and the tell was that the repo shipping it already ran the other way somewhere else — the
kind of contradiction that is invisible from inside, because each page reads as correct on its own. It
took a consumer walking the checklist against a target that can refuse to surface it.

**Score:** 2

#### Pull Request

Block 2's cut-then-push is a default a live stage can answer differently
