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

#### Decision (Dave, August 31, 2026)

- **Durable home: Option A** — record the residue protocol and the step-4 amendment verbatim in the
  DEPLOY section, so they fold into `CHANGELOG.md`. Close #1157; leave #1168 open tracking *only* the
  residue probe until a `ccs-testrun-4` session takes it. No new doc pattern.
- **Teardown: agreed** — `ccs-testrun-1`, `-3` (takes `ccs-testrun-3#5` with it) and `-5` are deleted;
  `-2` and `-4` are kept. The deletions need the `delete_repo` gh scope, which this session's token
  does not carry — so they are run by Dave (or after a `gh auth refresh -s delete_repo`), not on this
  branch. This branch records the decision.

### CREATE

- [x] Dave picks Option A / confirms teardown — done, see PLAN
- [x] Write the carried-forward record in DEPLOY (Option A)
- [x] DEPLOY reflects the outcome
- [~] Execute the three repo deletions — dropped from this branch: the gh token lacks `delete_repo`
      scope. Carried forward as a note on #1168, run by Dave.

### TEST

- [x] `check-plugin-integrity.ps1` clean (dead-link scan covers the new issue links) — run by `open-pr`
- [x] All test suites green — run by `open-pr`
- [~] No behavioural test — this branch is a docs/record change only

### DEPLOY: `docs/testrun-series-tail-1168-v1`

Close out the end-to-end testrun series ([#1135] → [#1157] → [#1168]). Run 5 met the series exit
criterion for the first time — **0 HARD, 0 FRICTION against `v4.27.0`, no inbound issue needed** — so
the series ends here. The residue the closed issues would otherwise have carried only as comments is
recorded below instead, in the changelog, where a future runbook author will find it.

**The one open measurement — the permission-classifier residue probe.** The same-shape A/B on the
permission classifier is one probe short. Both halves of the classifier already read PASS; this probe
only excludes *command shape* as an alternative explanation for one contrast. It is a tightening, not a
gate.

- **What:** `adopt-config.ps1` under the deny-everything protocol — deny the next two commands; a denial
  arrives back in the session, an `allow`-covered command simply runs.
- **Where:** a Claude Code session opened **inside `DaveKJohn/ccs-testrun-4`**, out of auto mode. A
  session in the source repo is structurally the wrong instrument — a model observes results, not
  prompts, so "asked and approved" and "never asked" are one event from its side unless the run is
  inside the consumer with the runner denying.
- **Status:** stays open on [#1168]. `ccs-testrun-4` is kept standing as the only place it can be
  measured.

**The amendment for the next step-4 runbook.** Run 5 did not walk step 4. Whenever step 4 is next
walked, it inherits this rather than re-deriving it:

1. **Name both permission layers and say they are different.** `permissions.defaultMode` in
   `settings.json` decides what a session **starts** in; the shift+tab toggle (*manual mode /
   auto-accept edits / plan mode*, where `default` is only the internal name for the first) is a
   separate layer. A runner who reads "manual" off the status line has recorded a true fact about the
   second and nothing about the first.
2. **Measure by denying, not by asking.** Asking the runner whether a prompt appeared does not work —
   where there are many prompts they get approved on autopilot. Deny everything for the next two
   commands and the outcomes become distinguishable with nothing resting on recollection: a denial
   arrives back in the session; a command covered by `allow` simply runs.

**Teardown of the test repos** (decision by Dave, August 31, 2026): `ccs-testrun-1`, `ccs-testrun-3`
(which takes [`ccs-testrun-3#5`](https://github.com/DaveKJohn/ccs-testrun-3/issues/5) with it) and
`ccs-testrun-5` are deleted; `ccs-testrun-2` (cited by `runlog-3.md`) and `ccs-testrun-4` (the residue
probe) are kept. The deletions are run outside this branch — they need the `delete_repo` gh scope.

[#1135]: https://github.com/DaveKJohn/claude-code-specialists/issues/1135
[#1157]: https://github.com/DaveKJohn/claude-code-specialists/issues/1157
[#1168]: https://github.com/DaveKJohn/claude-code-specialists/issues/1168

**Score:** 2

#### What makes this deploy extra special

N/A — internal QA bookkeeping; no subscriber of any consuming repo notices this.

**Score:** N/A

#### Pull Request

Testrun series tail: closeout plan for the #1168 residue

