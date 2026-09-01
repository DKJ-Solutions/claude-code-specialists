## Development: `fix/merged-pr-proof-shared-v1` · 20260901-160555

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

#### Issue [#1194](https://github.com/DaveKJohn/claude-code-specialists/issues/1194)

The merged-PR proof -- *was THIS ref merged, or only a branch that once wore its name?* -- existed
twice. Two branches were open at the same time on September 1, 2026, neither knew about the other,
and both repaired the same defect class correctly: inbound #1190 in team-shopify's
`sync-main.ps1` (via `scripts/lib/sync-rules.ps1`) and #1191 in the workflow plugin's
`scripts/task/prune-merged.ps1`.

By the evening the copies had already diverged, on the guard that costs nothing today:
`sync-rules.ps1` keyed its map with `[System.StringComparer]::Ordinal` and said why -- git refs are
case-sensitive, a PowerShell hashtable's default comparer is not -- while `prune-merged.ps1` used a
bare `@{}`. Verified before repairing anything: `ContainsKey('feat/x')` answers `True` on the
default hashtable and `False` on the ordinal dictionary.

**The placement question the issue left open is answered by precedent, not by a new decision.**
`sync-rules.ps1` belongs to `team-shopify` and `prune-merged.ps1` to `contributing-davekjohn`, so
neither can host the other's copy -- but `check-report-lib.ps1` (August 8, 2026) and
`native-capture-lib.ps1` (inbound #1181) both already solve exactly that: one source in
`scripts/lib/`, registered TWICE in `Get-SharedScriptPairs`, mirrored into both plugins. The two
plugins are separately versioned and separately installed, so reaching across from one cache into
the other would be a dependency a version mismatch breaks silently.

**What is shared and what is not.** The map and the two-part test are shared. The gh transport is
not: each caller documents its own reason at its own call site -- `sync-main.ps1` wants
`--jq ... @tsv` because a tab-separated row is a stronger filter against a gh status line leaking
into data it compares refs against, `prune-merged.ps1` wants plain JSON because `ConvertFrom-Json`
is already in the shell and needs no quoting through PowerShell into gh on Windows. Neither reason
travels, so neither transport does.

### CREATE

- [x] `scripts/lib/merged-pr-lib.ps1` -- `Get-MergedPrTips` (pairs in, ordinal map out),
      `Get-MergedPrTipsFromTsv` (the tab-separated transport on top of it), `Test-RefMergedByPr`
      (the name+tip proof) and `Test-MergedPrNameKnown` (the middle answer that earns
      prune-merged's *"the name was recycled"* sentence, and is deliberately a separate function so
      a caller cannot read it as a proof).
- [x] `scripts/lib/sync-rules.ps1` -- `Get-SyncMergedRefTips` and `Test-SyncRefMergedByPr` removed;
      header says where the proof went and why it is not dot-sourced from there (that file is
      deliberately dependency-free, which is a property of the file rather than of the rule).
- [x] `scripts/task/sync-main.ps1` -- dot-sources the new lib beside `sync-rules.ps1`, unguarded;
      calls `Get-MergedPrTipsFromTsv` / `Test-RefMergedByPr`. Its comment claiming prune-merged
      *"still"* has the name-only defect was stale the moment #1193 merged and now describes the
      shared repair.
- [x] `scripts/task/prune-merged.ps1` -- dot-sources the new lib; the bare `@{}` is gone, the map is
      `Get-MergedPrTips -Pairs`, and `Get-MergedProof` asks the lib's two questions in the order
      that matters (the proof first -- a name-known check that short-circuited would be the
      name-only proof back).
- [x] `scripts/lib/shared-scripts-lib.ps1` -- two entries, `merged-pr-lib` and
      `merged-pr-lib-shopify`, on `check-report-lib-workflow`'s stated precedent.
- [x] `scripts/sync/build-shared-scripts.ps1` run: 5 mirrors updated.

### TEST

- [x] `scripts/tests/merged-pr-lib.tests.ps1` -- new, 32 asserts. The behaviour cases moved out of
      `sync-rules.tests.ps1`, plus what neither caller could cover: the ordinal comparer asserted on
      BOTH transports (the whole point of one source is that neither caller can be the one without
      it), two names differing only in case kept as two entries, the object transport dropping the
      same four rows for the same four reasons as the TSV one, and `Test-MergedPrNameKnown`
      answering TRUE exactly where the proof answers FALSE.
- [x] `scripts/tests/prune-merged.tests.ps1` -- fixture copies the new lib (a missing dot-source is
      not a degraded answer but no script at all: every case failed at exit 1 until it was added,
      the same way `worktree-lib` was discovered). New case (r) pins structurally that the proof is
      the lib's and the bare `@{}` is gone -- cases (o) to (q) all passed with the private copy too,
      which is precisely how the two drifted apart unnoticed the first time.
- [x] `scripts/tests/sync-main.tests.ps1` / `sync-rules.tests.ps1` -- static asserts repointed, the
      moved block removed.
- [x] `check-plugin-integrity.ps1`: 0 errors. Full test gate: **58 suites, all passed**, 378s.

### DEPLOY: `fix/merged-pr-proof-shared-v1`

The proof that a merged PR is about **this ref** and not merely about a branch that once wore its
name now lives once, in `scripts/lib/merged-pr-lib.ps1`, and both scripts that need it call it.

It had lived twice since September 1, 2026, when two branches open at the same time repaired the
same defect class independently and correctly -- inbound #1190 in team-shopify's `sync-main.ps1`,
#1191 in the workflow plugin's `prune-merged.ps1`. The copies diverged the same day, on the guard
that is easiest to leave out because nothing fails without it yet: one keyed its lookup with
`[System.StringComparer]::Ordinal` and wrote down why git refs are case-sensitive, the other used a
bare `@{}`, whose comparer is not. A merged `Sync/live-x` could therefore be found under a standing
`sync/live-x` in one script and not in the other.

The lib carries the map, the sha-shape validation, the ordinal comparer and the two-part test; each
caller keeps its own gh transport, because each has a written reason for the one it uses that does
not travel to the other. It is registered twice in `Get-SharedScriptPairs` and mirrored into both
plugins rather than reached across between them -- they are separately versioned and separately
installed, so a cross-plugin path is a dependency a version mismatch breaks silently.

**Score:** 2

#### What makes this deploy extra special

It is #81's and #815's argument arriving from the inside, with a date on it. The case for a single
source is normally made in hindsight, about a copy that drifted over months; this one drifted in
hours, between two branches that were both right, and the half that went missing was the half whose
absence changes nothing today. That is the shape worth recording: duplication does not announce
itself by failing.

The behavioural change in this repo is one sentence in one report. In `prune-merged.ps1` a
case-differing merged name was *found* under the default comparer and the tip comparison then
failed, so the branch was kept with the reason *"the name was recycled"* rather than *"no merged
PR"* -- a wrong sentence, not a wrong action, and a false delete would additionally have needed two
branches differing only in case sitting on the same commit, where nothing is lost. Neither case was
constructed; the comparer difference was verified directly, and it is now pinned by a test on both
transports.

**Score:** 1

#### Pull Request
