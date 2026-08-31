## Development: `docs/ticket-rules-that-stayed-in-the-consumer-v1` · 20260831-100459

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

Three ticket-work lessons sit only in `BWJ-ecommerce/smartwatchbanden`'s local answers page and are craft
rather than that repo's answers: every consumer of this workflow would be served by them, and none is in the
portable half today -- measured, zero hits for the wording of each. They go up here, so the consumer page can
shrink to what only it can answer.

#### Why three rules and not five

Five lessons were identified. Two of them share a subject -- a message at the wrong gate, and a question in a
delivery message -- and splitting them would have restated rule 6 from the other end. They become one rule
with both measurements inside it, so the three below carry all five lessons.

#### What deliberately stays in the consumer

The tracker, the closed `State` vocabulary, the section names, the two dictated reply sentences, and where
research material sits. Those are seam answers, and the `What your repo answers` table already claims them.

### CREATE

- [x] Rule 11 -- the judgment lives at the gate, not with the evidence
- [x] Rule 12 -- every message lives at its own gate, and the closing message carries no question, with the question-mark measurement
- [x] Rule 13 -- the three rules for a message to a person, with the numbering measurement
- [x] Record the second harvest under `Where this comes from`, so the provenance stays stated rather than discovered
- [x] Correct `ticket folder` in that same paragraph -- the originating repo has run its ticket layer in issues since 2026-08-28

### TEST

- [x] `check-plugin-integrity.ps1` clean -- the new rules add anchors, and rules 12 and 13 link against existing ones
- [x] Every `scripts/tests/*.tests.ps1` suite green
- [x] No new rule restates an existing one: 6 (the reply at a *yes*) and 8 (one list, our own numbering) are the two nearest, and 12 and 13 name them instead of repeating them

### DEPLOY: `docs/ticket-rules-that-stayed-in-the-consumer-v1`

`CONTRIBUTING-portable.md`'s ticket-work section gains **rules 11, 12 and 13** — the judgment living at the
gate rather than with the evidence, every message living at its own gate with no question in the closing
one, and the three rules for a message to a person. All three were already in daily use, in
`BWJ-ecommerce/smartwatchbanden`'s local *answers* page, and none of them names a tracker: they were craft
sitting on the answers side of the seam, which is the one defect an inbound issue never reports, because a
rule in the wrong file is not wrong.

Each arrives with the measurement that produced it, in the style the ten around them already use. The one
worth reading twice is rule 12's: over six tickets, **five asked a question in their delivery message**, two
of them without a question mark anywhere, while two of the question marks that were present were `?page=`
and `?sort_by=` in a URL — so the check people reach for first does not work, and the rule says why.

**They are three rules rather than five lessons on purpose.** A message at the wrong gate and a question in
a delivery message share one subject, and splitting them would have restated rule 6 from the other end.
Rules 12 and 13 name rules 6 and 8 instead of repeating them.

`Where this comes from` records the second harvest beside the first, so the provenance of this section stays
stated rather than discovered later, and the same paragraph drops `ticket folder`: that repo has run its
ticket layer in GitHub issues since 2026-08-28.

**Score:** 3

#### What makes this deploy extra special

A consumer running a ticket layer gets three rules they did not have, one of which changes what a delivery
message may contain. It reaches no other consumer at all — the seam is unchanged, nothing is renamed, and a
repo whose work does not arrive from somebody else's tracker reads none of this section.

**Score:** 3

#### Pull Request

The ticket-work rules that never left the consumer
