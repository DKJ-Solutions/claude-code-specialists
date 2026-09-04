## docs/contributing-layering-third-rank

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

Inbound [#1379](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1379): the layering
section in `CONTRIBUTING-portable.md` ranks the two **consumer** documents (the floor and
`contributing-davekjohn/CONTRIBUTING.md`) but never says where the plugin's own portable pages and
skills sit relative to either. A consumer (`BWJ-ecommerce/smartwatchbanden`) filled that vacuum the
wrong way up, declaring its `CLAUDE.md` supreme over the plugin's own shared law — measured concretely
in the divergence at [#1378](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1378).

The issue asks for three things "in increasing cost", and says outright that the first two close the
gap: (1) state the third rank, (2) add the operational corollary (point / answer the seam / say
nothing — never restate), (3) a prose equivalent of `check-script-contract.ps1` enforcing it. Doing 1
and 2 here; 3 is a standalone lint mechanism needing its own design (manifest schema, fuzzy-match
tolerance) and is left for a follow-up issue rather than improvised inside this docs branch.

### CREATE

- [x] Extend "The two contributing layers, and which one wins" in `CONTRIBUTING-portable.md` with the
      third rank (the plugin's own portable pages + skills outrank both consumer layers on matters it
      legislates) and the operational corollary (point / answer the seam / say nothing, never restate)
- [x] File a follow-up issue for item 3 (the prose contract check) so it is not lost — #1380
- [~] Close out #1379 pointing at the PR, and note the follow-up issue number -- a post-merge act (the
      PR does not exist until this branch reaches step 3.1), not a step this gate should hold

### TEST

- [x] Read the edited section back end to end — the new rank must not contradict the existing "which
      file carries the floor is yours" / "workflow's page wins" text, only complete it
- [~] Lint + tests via `open-pr.ps1` -- duplicates the standing gate that fires at the push itself,
      per 2.2's own rule against writing a gate as a step

### DEPLOY: docs/contributing-layering-third-rank

`CONTRIBUTING-portable.md`'s layering section ranked only the two consumer documents (the floor and
`contributing-davekjohn/CONTRIBUTING.md`), leaving nothing to say where the plugin's own portable pages
and skills sit relative to either — a vacuum a consumer had filled by declaring its own `CLAUDE.md`
supreme over the shared law itself. A new subsection states the complete three-rank order (the plugin's
law above both consumer layers, scoped to what the plugin actually legislates) and the operational
corollary that keeps it: a consumer document may point at, or answer the seam of, a shared law, but never
restate it — a restatement is a copy, and a copy diverges silently.

Closes [#1379](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1379). Item 3 of that
issue (a prose equivalent of `check-script-contract.ps1` enforcing the corollary automatically) is a
standalone mechanism and is filed separately as
[#1380](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1380).

**Score:** 3

#### What makes this deploy extra special

N/A — this repo already runs the ranking it describes (its `contributing-davekjohn/CONTRIBUTING.md`
already says it wins over its own `CLAUDE.md`); the change closes a documentation gap a consumer had
filled the wrong way, not a rule this repo itself was running incorrectly.

**Score:** N/A

#### Pull Request

State the plugin-law rank above both consumer contributing layers

