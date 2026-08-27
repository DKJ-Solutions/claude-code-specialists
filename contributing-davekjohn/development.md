## Development: `feat/shopify-sync-pr-body-seam-v1` · 20260827-213211

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

Inbound [#1000](https://github.com/DaveKJohn/claude-code-specialists/issues/1000), from
`BWJ-ecommerce/smartwatchbanden`: `team-shopify`'s `sync-main` composes a PR body naming only what the
content rule held BACK, and there is no seam to reshape it. The consumer's own rule is that a sync PR does
not wait for a review provided it states plainly what a third party did -- so the body is the only record
that drift was ever inspected, and it has already failed once: in their sync PR #350 the body was a flat
file list, so nothing recorded that live had made `templates/page.back-to-school.json` *disappear*.

#### The six inbound checks, run before any of this was scoped

All six stand, and one detail of the report is sharper than the report itself:

- **subject** -- `scripts/task/sync-main.ps1` exists, `plugin.json` says `4.20.0`, the version the report
  measured.
- **symptom** -- stands. No `Get-ShopifySyncPrBody` and no `-BodyBuilder` anywhere in the tree; the
  composed body carries `$keep` only; the quoted hint is verbatim in the file.
- **reason** -- stands. The classified row carries `Status`, `Path` and `Reason`, and the taken rows are in
  hand where the body is composed. The data really is already there.
- **repair** -- the mechanism it proposes exists: every seam is read defensively through `Get-Command`, so
  one more `Get-ShopifySync*` is the house pattern rather than an invention.
- **size** -- its four counts are zero and correct. Recount of the *subject*: **two** body sites, not one,
  and the report names both.
- **repo** -- ours. The canonical copy is `scripts/task/sync-main.ps1`; the plugin copy is a mirror
  `build-shared-scripts.ps1` writes.

**The one thing the report understates:** on the non-merging path no body is composed *at all* -- the
printed `gh pr create` line has no `--body`, and the operator is told to copy the exclusions in by hand.
That is the DEFAULT path, because the seam that merges is opt-in. So the repo with no body was the common
case, not the edge.

### CREATE

- [x] `New-SyncPrBody` + `Get-SyncFileKind` in `scripts/lib/sync-rules.ps1` -- the default body, naming
      both halves and every path with its kind in words (`changed on live`, `new on live`, `gone from
      live`), files grouped under their shared reason so a 31-file sync does not print one sentence 31
      times.
- [x] `Get-ShopifySyncPrBody`, read by `Get-SyncPrBodySeamAnswer` in the task script. **Not in the lib**,
      and that is the lib's own header rather than a preference: it is deliberately not a reader of
      `scripts/repo-config.ps1`, because the same file is dot-sourced by team-shopify's live-theme guard
      on every command and a fault in it must not reach the one rule that cannot self-declare.
- [x] The seam is read at the moment it is needed, not with the scalar answers at the top. Capturing its
      `ScriptBlock` up there was the first shape and it is wrong: the consumer's function may call
      anything else its `repo-config.ps1` defines, and by then that child scope is gone.
- [x] A body seam that throws is **reported**, not swallowed. Every other seam degrades silently because
      its default is a correct answer; here the consumer asked for a specific record and got the generic
      one, which is the failure #1000 is about.
- [x] One composition for both paths. The non-merging path writes the body to a file and hands over
      `gh pr create ... --body-file <path>` -- multi-line markdown does not survive a copy out of a console
      and a paste into another shell, which is what `--body-file` exists for.
- [x] Docs: the script docstring (the seam list and a `THE PR BODY IS THE RECORD` paragraph), the block
      `adopt-shopify-floor` writes into a consumer's `repo-config.ps1`, the plugin README's seam table, the
      `sync-main` skill page (a step 8 and the table), the `adopt-shopify-floor` skill page, and Steven's
      manual -- whose bullet *"The script prints that list, and it belongs in the PR body"* was the
      instruction this change retires.
- [x] `build-shared-scripts.ps1` mirrored all three scripts into `plugins/teams/team-shopify/`.

### TEST

- [x] `scripts/tests/sync-rules.tests.ps1`: **61 -> 78** asserts. The kind mapping in all three
      directions, the `D` case that is #350, the counts, the grouping, the caller's order, both empty
      halves, a `$null` row, the caller's intro.
- [x] `scripts/tests/sync-main.tests.ps1`: **32 -> 43** asserts, end to end against a fixture consumer --
      the body file on the non-merging path, an answered seam (and that `-Default` reaches it), and a
      throwing seam that costs the custom body and not the sync.
- [x] `check-plugin-integrity.ps1`: 0 errors, mirrors in sync.
- [x] The assert worth naming is `body/take: the taken paths are named at all`. Every other property here
      -- counts, reasons, grouping -- was true of the old body too, so a suite can be entirely green over a
      report that omits the half a reader came for. It is worded as presence for that reason.

### DEPLOY: `feat/shopify-sync-pr-body-seam-v1`

`team-shopify`'s pre-task sync now writes the PR body itself, on **both** paths, and a consumer can replace
it. The body names what was TAKEN from live as well as what was held back, and gives every path its kind in
words -- `changed on live`, `new on live`, `gone from live` -- so a deletion on live reads as a deletion
instead of as a filename in a list. `Get-ShopifySyncPrBody` receives the classified rows and the composed
body and returns whatever the repo's own review policy needs around them.

**Score:** 4

#### What makes this deploy extra special

**The PR body is the record, and in some repos it is the only one.** Where a consumer has ruled that the
sync PR does not wait for a review -- provided it states plainly what a third party did -- nobody reads the
diff by design. *"The diff shows what came in, never what was held back"* was the script's own instinct and
it was the right half of a two-half problem: the diff of a sync branch cannot show what live no longer has
either. That is not hypothetical. Inbound #1000 arrived with the failure already measured in the reporting
repo's sync PR #350, where a flat file list could not say that a template had disappeared.

**And the path that had no body at all was the default one.** The merging variant composed a partial body;
the non-merging variant composed none and printed a `gh pr create` line without `--body`, plus a list for
the operator to paste in. Merging is opt-in, so the common case was the empty one -- the sort of gap that
survives because every consumer who hits it works around it locally, which is exactly what the reporting
repo had been doing since the time-window era.

**Score:** N/A

#### Pull Request

team-shopify sync-main: a seam for the sync PR body
