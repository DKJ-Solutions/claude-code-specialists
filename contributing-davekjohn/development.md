## Development: `docs/dropped-ship-cost-overstated-v1` · 20260902-200002

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

#### Context

Issue #1235. The folded DEPLOY entry for `fix/ship-pr-lost-watch-retry-v1` (PR #1233) overstates
what a dropped ship costs: it claims *"a re-checkout of the branch plus a full local gate run --
lint and every suite"*. `scripts/lib/gate-lib.ps1` keeps gate evidence keyed on the tree
(`Test-GateEvidence`/`Save-GateEvidence`, `GateEvidenceMaxAgeMinutes = 240`), so a same-tree resume
within four hours skips both gates -- the true, smaller cost is only the re-checkout step 2b (#1073)
had just handed back to the trunk. The DEPLOY lock (#884) meant #1233 could not fix it in place;
this is the ordinary `docs/` follow-up the issue prescribes.

### CREATE

- [x] Replace the overstated clause in `contributing-davekjohn/CHANGELOG.md` (the
  `fix/ship-pr-lost-watch-retry-v1` DEPLOY entry) with *"a re-checkout of the branch step 2b had
  just left"* -- the wording the issue proposes. Nothing else in the entry changes.

### TEST

- [x] Verified against `scripts/lib/gate-lib.ps1` that the lint and test gates both skip on a
  same-tree resume within `GateEvidenceMaxAgeMinutes` (240). No automated test -- prose-only
  changelog correction.

### DEPLOY: `docs/dropped-ship-cost-overstated-v1`

The folded changelog entry for `fix/ship-pr-lost-watch-retry-v1` no longer claims a dropped ship
costs a full local gate run. `scripts/lib/gate-lib.ps1` stores gate evidence keyed on the tree, so
a resume within four hours on an unchanged tree skips both lint and the suites -- what a dropped
ship still costs is the re-checkout of the branch `ship-pr` step 2b had just handed back to the
trunk. The diagnosis in the entry was accurate; only its impact clause was inflated.

**Score:** 1

#### What makes this deploy extra special

N/A -- a subscriber of the service does not read this repo's internal changelog entries; a consumer
who does now reads a sentence that matches the shipped behaviour, with nothing to act on.

**Score:** N/A

#### Pull Request

the lost-watch retry changelog entry no longer overstates a dropped ship's cost

