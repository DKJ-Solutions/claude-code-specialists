## Development: `docs/filing-rules-before-the-bootstrap-v1` · 20260829-192843

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

Inbound [#1094](https://github.com/DaveKJohn/claude-code-specialists/issues/1094): a consumer's
pre-bootstrap main loop has none of the orchestrator's filing and verification rules, and the one
governance model the bootstrap points it at forbids the inbound route outright.

#### What the four comments changed about the subject, and what re-measuring changed again

The issue was filed asking for one sentence about permission. Its own thread widened it twice, and both
widenings were checked here rather than inherited:

- **It is three rules, not one** (comment 4): filing needs no permission, search the tracker before
  proposing a fix, and verify an inferred constraint before obeying it. Three different outcomes were
  measured in one run -- filed late, filed then self-corrected, and not filed at all.
- **The search step is a correctness step** (comment 2), and our own wording says otherwise: the shared
  block frames it as duplicate hygiene while making verification a separate, emphatic rule that names
  *"the code, the script or the doc"* and not the tracker. A faithful reader does what the measured
  session did.
- **Two size corrections of my own.** The report cites `findings-become-issues.md` and
  `01-01-persona.md` as two places; they are **one source and its generated copy**, so this is a single
  edit plus a regeneration. And that regeneration reaches **30 files across four teams**, not the
  "15+ agent defs" the report names -- four of them personas, which is how the block reaches a main loop
  at all.
- **The constitution contradiction is real and lives in exactly ONE place** --- `CLAUDE.md`, this repo's
  own. The report's *"wherever the rule is stated as a model"* implies several; a tree-wide grep returns
  one hit.

#### Proposal 3's mechanism half is not built here, and the reason is a collision

Getting the rules into a main loop *before* the bootstrap needs a channel that reaches a pre-bootstrap
session: a SessionStart hook line, or the `orchestrator` skill page. `Get-ClaudeMdScaffold` is not one --
it runs *after* the bootstrap, which is the same side of the line as the `@`-import it would duplicate.
Both real candidates are being rewritten right now on `fix/adoption-handover-and-jsonc-caveat-v1`
(#1093/#1096), which touches the `[BOOTSTRAP]` message and `orchestrator/SKILL.md`. So this branch takes
the fallback the issue itself names -- say plainly that the rules are not in context until after the
restart -- and the mechanism half goes to its own issue, to be decided once that branch has landed.

### CREATE

- [x] `plugins/ADOPTION.md`: a named section under the reporting rules -- filing needs no permission, the three rules stated in full, the ordinary bar restated as a bar rather than a gate, and the structural gap named out loud
- [x] `CLAUDE.md`: the "publishing anything externally" bullet carves the inbound route out BY NAME, with why it matters most where this file is copied
- [x] `agent-shared/findings-become-issues.md`: the tracker joins the artefacts you read, because it is where a guardrail's intent lives -- and the bar's search clause points at it
- [x] Regenerate the 30 files carrying that block (`build-agent-defs.ps1`)
- [~] The pre-bootstrap channel -- deferred to its own issue, with the collision named above

### TEST

- [x] The lint gate covers what is coverable here: the dead-link scan over both changed docs, and the shared-block generation sync (an edited block with stale copies is a lint error)
- [~] No new content assert, deliberately -- and this is a stated test gap rather than an oversight. Pinning prose in `CLAUDE.md` or `ADOPTION.md` is the shape this repo measured and declined once already (the stale-path check, 124 findings all false); a regression here is a sentence someone deletes, which no cheap assert distinguishes from a rewrite

### DEPLOY: `docs/filing-rules-before-the-bootstrap-v1`

A consumer's session is now told, on the page it reads before adopting, that filing an inbound issue on
the source repo needs no permission -- and this repo's own constitution stops saying the opposite.

The rule already existed and was already well written. It was in the orchestrator's body and in the
agent-def bodies, and neither reaches the one reader who needs it: a pre-bootstrap main loop. Chris
arrives through the `@`-import `specialists-init` writes, so he is in context only after the bootstrap
and a restart -- one step later than the moment a consumer meets the most friction and has the most
worth reporting. Meanwhile `CLAUDE.md` listed *"issues on other repos"* among the acts needing explicit
permission, with no carve-out, and the bootstrap tells a consumer to expand their own governance from
the nearest model, which is that file. Both statements are ours and they disagreed about the same act.

So `ADOPTION.md` states all three rules a session needs before it has Chris -- filing needs no
permission, the tracker search is a correctness step and not tidiness, and an inferred constraint is
verified before it is obeyed -- says out loud that they are not in session context yet, and tells a
reader to check their own safety rules for the same contradiction. `CLAUDE.md` names the carve-out. And
the shared block that 30 agent defs and personas carry now counts the tracker among the things you read
before proposing a fix, because the code says what a guardrail does and only its issue says what it was
built to prevent.

**Score:** 3

#### What makes this deploy extra special

Everything a consumer's session finds during adoption -- the moment it is least equipped and most likely
to find something -- was being held back for a permission nobody was going to ask for. That cost is
unmeasurable by construction: the findings die in a local file in the consumer's own repo, and the
source repo never learns they existed. The measured instance is two verified defects in one run, in a
throwaway repo, that would have gone with it.

**Score:** 4

#### Pull Request

a consumer session is told, before the bootstrap, that filing an inbound issue needs no permission -- and the constitution stops contradicting it
