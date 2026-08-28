## Development: `docs/trim-chris-persona-v1` · 20260828-095351

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

Chris's persona is 27,535 B / ~8,825 tokens and 35% of the always-on path. Lines 257-331 are GENERATED shared blocks (repo-way-of-working, findings-become-issues) and are out of bounds. The target is Chris's own two heavyweights: the fixed ritual (6,442 B) and the inbound route (6,531 B). Rules stay in the persona; the worked reasoning moves to a portable skill in team-alpha so consumers keep it.

### CREATE

- [x] Establish which of the persona is editable at all -- lines 233-307 are GENERATED shared blocks (`repo-way-of-working`, `findings-become-issues`, 6,977 B) and out of bounds by hand
- [x] Compress `## Chris's fixed ritual` -- step 6's close-out shapes, the receipt rule and the duplication test, no rule dropped
- [x] Compress `## Core improvements — the inbound route` -- the six failure modes were buried in five prose paragraphs; they are now enumerated as six, which is what every document referring to them already calls them
- [~] Move the worked reasoning to an on-demand half -- BLOCKED, and the blocker is the finding: check 6b refuses a manual to a specialist with no agent def, and Chris is deliberately a persona. Filed as #1017 with the measurement and the three candidate answers; choosing between them is a change to the way the system is structured and not this branch's call
- [x] Verify the shared-block markers and every `##` heading survived the splices
- [x] Re-measure with `measure-always-on.ps1`

### TEST

- [x] `check-plugin-integrity.ps1` green -- in particular `[shared]`, which walks personas as well as agent defs and would catch a hand-edited shared block
- [x] Every rule in the two rewritten sections is still present, checked one by one against the previous text

### DEPLOY: `docs/trim-chris-persona-v1`

Chris's persona is the one document on the always-on path that every consuming repo pays too, and it
was 27,535 B. It is now 25,674 -- **1,861 B / ~596 tokens, 6.8%** -- with no rule removed and no
generated block touched.

Two sections carried it. The fixed ritual's step 6 said the same thing about the close-out in four
paragraphs where two do. The inbound route described **six** ways a report fails on pickup across five
running prose paragraphs, while every document that refers to them -- the repo lens, the
`triage-inbound` skill -- already calls them "the six". They are a numbered list now, so the count in
the prose and the count on the page finally agree, and a reader checking a report against them can
find the fifth one.

**What this branch could not do is the more useful half, and it is filed rather than left implicit.**
The other fifteen specialists split into an always-listed agent def and a `manuals/` playbook read on
demand; Chris has no manual, because check 6b of the integrity gate refuses one to a specialist with no
agent def and he is deliberately a persona. So every rule he carries has to sit in the always-loaded
body, which is why he is ~35% of the path. Measurement, the inconsistency in the handbook that states
both halves of it, and the three candidate answers are in
[#1017](https://github.com/DaveKJohn/claude-code-specialists/issues/1017) -- choosing between them is a
structural decision and not a branch's.

**Score:** 2

#### What makes this deploy extra special

A consumer gets the same rules in a shorter persona, and the six inbound checks as a list they can work
through instead of five paragraphs they have to parse. No behaviour changes.

**Score:** 2

#### Pull Request

Compress the orchestrator's always-loaded persona without dropping a rule
