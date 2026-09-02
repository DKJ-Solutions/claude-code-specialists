## Development: `docs/ticket-work-tracker-pickup-state-v1` · 20260902-142600

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

Inbound [#1217](https://github.com/DaveKJohn/claude-code-specialists/issues/1217), from
`BWJ-ecommerce/smartwatchbanden`. The **Ticket work** section of
`plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md` models the tracker as read-only:
"the tracker" appears three times and every one is a source you copy from, and the provenance-boundary
rule states the one-way flow as a premise. Nothing names the one moment the flow reverses -- when the
ticket layer takes a request IN, the source row moves on, and the person who filed it is watching that
column rather than the repo.

Verified against the tree at `8dcabdd1` (all six triage checks):

- **Symptom** stands. No rule anywhere in the section advances the source tracker on pickup; the
  `### Where the ticket lives` section added by #1218 treats every host-tracker field as one you read,
  never one that moves.
- **Reasoning** stands and is stronger than when filed. #1227 (today) built the automated form of this
  in the `bwj-codex` layer -- stage `Filed`, "the issue exists", moved by `report-issue` as it files --
  so the pattern is now proven at the pickup end as well as the close end, and the portable layer still
  names neither.
- **Repair** names structures that exist (`### The rules`, `### What your repo answers`).
- **Subject / size / repo** all check out; one stale detail -- "column" now appears once, added by
  #1218 in the sense of *reading* the host list -- changes nothing.

Scope: portable manual only. This repo takes no ticket work
(`contributing-davekjohn/CONTRIBUTING.md` L117-118), so there is no local answer to mirror.

### CREATE

- [x] Add `#### 14. Taking a request in is a move the requester can see` to `### The rules` --
      the source row advances when the ticket document is created (not branch, not ship); the "automatically"
      trap with the 2026-09-02 measurement; the two consumer answers (which column, and which board when
      the request is on several -- advance only the delivery board, not the requester's intake board).
- [x] Add a row to `### What your repo answers` pointing at rule 14.
- [x] Add a clause to `### The one structural rule` so read-only is not misread as "never write to the
      source at all" -- its state is the one field you change, and rule 14 covers when.
- [x] Update the "explicit decisions -- 2, 4 and 6" sentence in the intro to include 14 without
      claiming it came from the same five rounds.

### TEST

- [x] `check-plugin-integrity.ps1` -- manifests, frontmatter, dead links.
- [x] Full suite via `open-pr.ps1` (lint + `scripts/tests/*.tests.ps1`).
- [x] Re-read the section end to end: source vs host tracker stays unambiguous, rule 14 reads at the
      density of rules 5/11/12/13, cross-references resolve.

### DEPLOY: `docs/ticket-work-tracker-pickup-state-v1`

The **Ticket work** section of `CONTRIBUTING-portable.md` modelled the tracker as something you only
ever read from -- and the provenance-boundary rule stated that one-way flow as a premise. It said
nothing about the one moment the flow reverses: when the ticket layer takes a request in, the source
row moves on, and the person who filed it is watching that column, not the repo. An issue that exists
while the source still says *new* reads, to the filer, as a request nobody picked up.

New `#### 14. Taking a request in is a move the requester can see`: the source row advances **when the
ticket document is created**, not at branch and not at ship; "automatically" is how the step gets
described once it is habitual, with the 2026-09-02 measurement where a filed request left the board on
its intake column and nothing moved it. Two answers are the consumer's -- which column pickup advances
to, and which board when the request sits on several (advance only the board that tracks your delivery
state; a requester's intake board still describes the request accurately after pickup). A clause in the
structural rule keeps read-only from being misread as "never write to the source", and a row in
**What your repo answers** carries the two questions.

**Score:** 2

#### What makes this deploy extra special

A repo running the ticket layer against a host tracker now has the rule that pickup is a visible state
change, and the two questions it has to answer -- which column, and which board when the request lives
on more than one. The gap it closes is a silent one: the step is easy to skip because nothing prompted
it, and the cost lands on the requester, who cannot see the repo and reads the un-advanced row as "not
picked up". It is the pickup end of a symmetry whose close end some repos already run.

**Score:** 3

#### Pull Request

ticket work: taking a request in is a move the requester can see
