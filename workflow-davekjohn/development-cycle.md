# Development cycle: `feat/filing-a-finding-needs-no-permission-v1` · 20260824-130839

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

## PLAN

- [x] Establish that the rule was missing rather than merely broken, because those need different
      repairs. `findings-become-issues.md` already says *"A finding becomes an issue, not a question at
      the end of the turn"* — so closing out with *"say the word and I'll file it"* broke a rule that was
      already written, in a repo whose own guide says a lesson is secured in the docs. What is NOT
      written anywhere is the second half below, and that is the part worth adding.
- [x] **Verify the finding that started this before filing anything — and it collapsed.** The claim was
      that `open-pr` builds a PR body with no closing reference and that the next branch would hit it
      again. `open-pr.ps1` has **`-Resolves '863'`** (writes one `Closes #<n>` per issue) and
      **`-NoResolves`** (declares the PR closes none), with a full decision table in
      `scripts/lib/pr-issues-lib.ps1`. Nothing is missing.
- [x] Establish why the gate then stayed silent, rather than assume it failed: it reads
      `$mentionText` — the branch's own cycle document plus any `-Body` (`open-pr.ps1:427-431`) — and
      blocks only where that text names an **open issue**. The previous branch's document cited no
      number at all; it said "the report" throughout. So the gate had nothing to detect and printed its
      informational line. **The omission was the author's, not the tool's.**
- [x] Decide not to file, and record why here instead: three claims, all three false — no scaffolding
      gap, no gate failure, and the cause was my own. Filing a weakened version of it would have put a
      citation on a defect nobody has, which is the failure this repo's inbound rules name directly.
- [x] Search the tracker before writing anything, per the bar the block itself sets: no existing issue
      covers the resolves gate or the filing rule.
- [x] Establish the layer: the rule is carried by the shared block `findings-become-issues`, which
      **30 files across all four teams** carry (`grep -rl`). So this is the portable half by construction
      — every specialist in the system, not one repo's lens — and it must be edited in the source and
      regenerated, never in a carrier.

## CREATE

- [x] Two bullets appended to `plugins/teams/agent-shared/findings-become-issues.md`. The first names the
      offer form — *"shall I open an issue for this?"* — as the same failure as not filing, since the
      finding still leaves the session as something the owner must answer.
- [x] The second is the one nothing in the tree said yet: **the question before filing is not "may I?"
      but "does it still stand?"**, because the permission question feels like diligence and substitutes
      for the check that matters. It names the sharpest case — a tool that appears to lack a capability,
      where the flag usually exists and what you met was the default — which is exactly the shape that
      produced it.
- [x] It also says what to do when a finding collapses: withdraw it with its reason rather than file a
      weakened version to justify having raised it.
- [x] `scripts/agents/build-agent-defs.ps1` run: **30 files updated**, every carrier rewritten from the
      source. No carrier edited by hand.

## TEST

- [ ] `check-plugin-integrity.ps1`: 0 errors, with check `[shared]` walking all 30 carriers and
      reporting no drift.
- [ ] All 52 suites green.
- [ ] The diff touches the source plus exactly the 30 generated carriers, and nothing else.

## DEPLOY: `feat/filing-a-finding-needs-no-permission-v1`

The shared block every specialist carries already said a finding becomes an issue rather than a question
at the end of the turn. It did not say that **asking permission to file is the same failure** — and that
gap is not theoretical: this branch exists because a session closed out with *"say the word and I'll file
it"*, which reads as courtesy and leaves the owner holding exactly the decision filing exists to remove.

The block now names the offer form outright, and adds the half nothing in the tree stated: **the question
to answer before filing is not "may I?" but "does it still stand?"** The permission question feels like
diligence and displaces the check that matters, so a finding that has never been held against the tree
arrives pre-approved. The measured instance is the one that produced this branch — the finding was that
`open-pr` writes a PR body with no closing reference, and it was false three times over: `-Resolves` and
`-NoResolves` both exist, the gate reads the branch's own document and blocks only where it names an open
issue, and the reason it stayed silent was that the author never cited the number. Approval would have
filed a defect nobody has. The block therefore also says what to do when a finding collapses: withdraw it
with its reason, rather than file a weakened version to justify having raised it.

**Score:** 4

### What makes this deploy extra special

It reaches **30 agent defs and personas across all four teams** through the shared-block generator, so
every specialist a consumer runs gets it at once rather than the orchestrator alone. And it closes a gap
in a guardrail rather than adding a preference: the rule it extends was already there and already
escapable through the one phrasing that sounds like good manners.

**Score:** 3

### Pull Request

Filing a finding needs no permission, and verifying it is the step that does
