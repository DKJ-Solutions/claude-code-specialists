## Development: `docs/testrun-series-tail-1168-v1` · 20260831-200934

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

**Goal.** Turn the four loose ends [#1168](https://github.com/DaveKJohn/claude-code-specialists/issues/1168)
carries into a durable, searchable record, so #1157 and #1168 can both close without losing anything —
and surface the one call that is Dave's (teardown). The testrun series has **no repo-doc home** today: it
lives entirely in GitHub issues, so its residue currently survives only as comments on closed issues.

#### The four items and how this branch handles each

1. **The residue probe (permission-classifier A/B).** Not resolvable from the source repo — it needs a
   Claude Code session opened *inside* `DaveKJohn/ccs-testrun-4`, out of auto mode, with the runner
   denying the next two commands (`adopt-config.ps1` under the deny-everything protocol). This branch
   only *records* the protocol durably; it cannot execute it. It is "a tightening, not a gate" — both
   halves of the classifier already read PASS.
2. **Teardown of `ccs-testrun-1..5`.** Recommendation below; Dave ticks. The deletions themselves are
   irreversible / outward-facing, so they wait for Dave's explicit word and run separately via `gh`.
3. **[`ccs-testrun-3#5`](https://github.com/DaveKJohn/ccs-testrun-3/issues/5).** Resolved as a
   consequence of item 2: if `ccs-testrun-3` is deleted it goes with it; if it is kept, a one-line
   correction comment on that issue closes it.
4. **The step-4 amendment** (name both permission layers and say they differ; measure by denying, not by
   asking). Currently only in [#1157's plan comment](https://github.com/DaveKJohn/claude-code-specialists/issues/1157#issuecomment-5470132039).
   This branch lifts it into the tree so the next step-4 runbook author finds it without spelunking a
   closed issue.

#### Teardown recommendation (item 2 — Dave's call)

| repo | recommendation | reason |
|---|---|---|
| `ccs-testrun-1` | **delete** | no references anywhere |
| `ccs-testrun-2` | **keep** | cited several times by `runlog-3.md`; deleting it breaks those citations |
| `ccs-testrun-3` | **delete** | #1127/#1128/#1130 closed; its tier-1 note already recorded in `runlog-4.md`. Takes item 3 with it |
| `ccs-testrun-4` | **keep** | only place the residue probe (item 1) can be measured; deliberately not a connector |
| `ccs-testrun-5` | **delete** once `runlog-5.md` has been read | no findings, cited by nothing; deliberately not a connector |

#### Open decision — the durable home for items 1 and 4

- **Option A (minimal, no new files).** Record the residue protocol and the step-4 amendment verbatim in
  this branch's DEPLOY section, so they fold into `CHANGELOG.md` (permanent, searchable). Then close
  #1157, and leave #1168 open tracking *only* the residue probe until a `ccs-testrun-4` session takes it.
- **Option B (new retrospective doc).** Add a short `contributing-davekjohn/testrun-series.md` capturing
  the series arc (runs 1–5, the exit criterion met at v4.27.0), the carried-forward residue protocol, and
  the step-4 amendment. Close both #1157 and #1168. Costs a new doc pattern the repo does not have yet.

### CREATE

- [ ] Dave picks Option A or Option B for the durable home (see PLAN), and confirms / adjusts the
      teardown recommendation
- [ ] Write the carried-forward record accordingly (DEPLOY section for A; new doc for B)
- [ ] Reflect the outcome in the changelog entry (DEPLOY below)

### TEST

### DEPLOY: `docs/testrun-series-tail-1168-v1`

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

Testrun series tail: closeout plan for the #1168 residue

