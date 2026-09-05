## docs/1396-bwj-codex-two-chapters

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

Fix inbound #1396: `README.md`:195 and `plugins/workflows/README.md`:17 still describe `bwj-codex`
as carrying one rule, made false by PR #1392 (the sync-log chapter). The wording model to follow is
`.claude-plugin/marketplace.json`'s own `bwj-codex` description, already updated by that PR.

### CREATE

- [x] Rewrite both table cells to name two chapters (ticket handling + the sync log) and to say
      what closing the GitHub issue actually does
- [x] Fix the same stale "extends only the ticket-work step" claim found alongside each table, in
      the surrounding prose of both files -- same root cause (#1382/#1392), same files, left
      unfixed it would have stood right next to the corrected table row contradicting it

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors
- [x] Confirmed the exact phrases quoted in #1396 ("resolve the Asana task", "resolves itself") no
      longer exist anywhere in the tree -- that half of the report had already been fixed by
      `4120e969`; only the "one rule" / chapter-count half remained

### DEPLOY: docs/1396-bwj-codex-two-chapters

Fixes #1396. The root `README.md` and `plugins/workflows/README.md` overview tables described
`bwj-codex` as carrying one rule; PR #1392 gave it a second chapter (the sync log) without updating
these two rows, and a second passage in each file repeated the same stale "ticket-work step only"
scope. All four spots now name both chapters, matching the wording already landed in
`.claude-plugin/marketplace.json`. Doc-only; no behaviour, script or manifest changes.

**Score:** 2

#### What makes this deploy extra special

N/A -- a documentation accuracy fix describing an already-shipped, already-released chapter; no
change to what any consuming repo experiences.

**Score:** N/A

#### Pull Request

README overview tables say bwj-codex has one rule; it now has two chapters

