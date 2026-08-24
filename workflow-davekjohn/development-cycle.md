# Development cycle: `feat/chris-owns-the-phase-transitions-v1` · 20260824-115743

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

- [x] Verify the report's symptom against the tree rather than accept it: `01-01-persona.md` names the
      cycle **nowhere** — no PLAN, no CREATE, no TEST, no DEPLOY, no "development cycle". The two grep
      hits are false positives (*"the reporter planned"*, *"thinks in plans and next steps"*), and the
      whole of `plugins/teams/team-alpha/` mentions the cycle in no document at all. The reader's
      impression is a fact about the text.
- [x] Correct the report's premise, which names the wrong plugin: it says the cycle is *"the core of
      every repo who installed the plugin"*. The cycle ships in **`workflow-davekjohn`**; a repo that
      installed the specialists and not that workflow has `workflow-default` — in its own README's words
      *"the deliberate absence of a method"*.
- [x] Establish the dependency direction before writing anything that crosses the two plugins, because
      the repair the report proposes runs against it. `workflow-davekjohn/README.md:124` states *"It
      requires the core team `team-alpha`"* and names the team six times; `team-alpha` names the workflow
      only in machinery and always conditionally — `bootstrap.ps1:505` reads *"are here because this repo
      enabled workflow-davekjohn; without that plugin nothing…"*.
- [x] Find the precedent rather than invent a shape: `workflow-sessioncheck` is workflow-aware and lives
      in **team-alpha** anyway, with `workflow-davekjohn/README.md:111` giving the reason. So a
      workflow-aware section in the core team is an established pattern here, not a new exception.
- [x] Locate the seam the join belongs in: the portable cycle leaves its actor deliberately open —
      *"whoever is working on the branch"* (`DEVELOPMENT-CYCLE-portable.md:9`). The workflow describes
      phases with no owner and the team an owner with no phases; neither is wrong, the join is simply
      unwritten.
- [x] Decide the layer with the requester rather than assume it: four options put, conditional prose in
      the persona chosen. Rejected alternatives recorded here — a section in the portable cycle (a session
      always reads the persona and reads that page only when the workflow folder is opened), and both
      halves at once (two places to keep in step, which is the duplication this repo keeps Ravi for).
- [x] Classify the branch by what actually changes, not by which files move: a persona is behaviour that
      ships to consumers, so `feat/` under Derek's rule *"`docs/` is purely documentation/text; `feat/` is
      a new or extended capability"*. The issue carries `enhancement`, which agrees.

## CREATE

- [x] `## Where a workflow ships a phase model` in `plugins/teams/team-alpha/personas/01-01-persona.md`,
      placed directly after the ritual and its two handover paragraphs so it sits with the steps it maps,
      and before `## Chris is lazy too`.
- [x] The mapping is a table of four phases against the ritual's parts: PLAN ← steps 1–2, CREATE ←
      steps 3 and 5, DEPLOY ← step 6. **TEST is stated as explicitly not Chris's** — verification belongs
      to the specialists he routed to, and a director who signs off his own team's work has removed the
      check rather than performed it.
- [x] Step 4 (Guard) is mapped onto no phase on purpose, and the section says why: guarding is not a
      stage but the check that runs at every boundary between stages.
- [x] The section is **conditional and inert by default**: its first paragraph states that the six steps
      stay method-independent and that a repo may have no method at all. A consumer on `workflow-default`
      reads a section that does not apply to them rather than an instruction they cannot follow.
- [x] The closing paragraph fixes the dependency direction in the text itself, so a later editor cannot
      quietly reverse it: a phase model may know its specialists, the specialists must never require one.
- [x] Written without a BOM and verified as such, since check 26 (`frontmatter-bom`) refuses one on a
      shipped persona and `ReadAllText` would strip it before any other check could see it.

## TEST

- [x] `check-plugin-integrity.ps1`: **0 errors**, run twice -- once on the persona alone and again with
      the cycle document in place, since that document is itself inside the mojibake set and the
      `[entry-heading]`/`[branch-template]` checks. The second run recognises the branch by name.
- [x] All **52 suites green**: 0 `[FAIL]` markers, no suite reporting a non-zero failure count. Checked
      against the whole log rather than the tail, because the first filter matched test NAMES containing
      the word "fail" and would have read as findings.
- [x] The persona carries **no shared block**, so nothing needs regenerating -- confirmed rather than
      assumed: check `[shared]` walks 30 files and covers agent defs AND personas, and reports no drift.
- [x] No BOM on the persona, verified as bytes (`head -c 3`), since `ReadAllText` strips one before any
      other check could see it and check 26 is the only thing that would catch it.
- [x] Diff scope: **26 insertions, 0 deletions** in one file, plus the branch's own document. No mirror,
      no generated artefact and nothing else in the tree moved.

## DEPLOY: `feat/chris-owns-the-phase-transitions-v1`

The orchestrator's fixed ritual and the development cycle described the same work and never referred to
each other: the persona named no phase, and the cycle left its actor open as *"whoever is working on the
branch"*. Each was complete on its own terms, which is why the gap survived — a reader met six steps with
no phases in one plugin and four phases with no owner in the other, and had to invent the join.

Chris's persona now carries `## Where a workflow ships a phase model`: a table binding PLAN to steps 1–2,
CREATE to steps 3 and 5, and DEPLOY to step 6, with **TEST named as deliberately not his** and step 4
(Guard) mapped onto no phase because it is what runs at every boundary between them. The section is
conditional — a repo with no method reads it as inert — and it fixes the dependency direction in prose:
a phase model may know which specialists it routes through, the specialists must never require one to
exist. That is the direction the tree already had (`workflow-davekjohn` requires `team-alpha`, never the
reverse), written down where the next editor will meet it.

**Score:** 3

### What makes this deploy extra special

Every consumer running a team gets an orchestrator who knows what a phase model is without being made to
depend on one, and the section that says so is the first place either plugin admits the other exists in
prose rather than in a script. It follows the `workflow-sessioncheck` precedent — the workflow-aware piece
lives in the core team — instead of opening a second pattern beside it.

**Score:** 3

### Pull Request

Chris owns the phase transitions where a phase model is installed
