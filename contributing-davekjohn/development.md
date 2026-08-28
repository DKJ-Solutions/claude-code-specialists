## Development: `feat/shopify-sync-pr-label-seam-v1` · 20260828-135325

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

Inbound #1023 verified as standing on all six checks. Adding Get-ShopifySyncPrLabels to sync-main.ps1, applied on BOTH the merging create and the printed operator line.

#### The verification, before anything was routed

All six checks stand. Symptom: `& gh pr create --base $trunk --head $branch --title $msg --body $body`
is verbatim at `sync-main.ps1:615` in 4.21.0, exactly as reported. Size: the eight seams the script
reads is eight. Reason: none of them is a label seam. Repair: `--label` on `gh pr create` exists and is
already in use in this tree at `open-pr.ps1:1276`. Subject and repo: the file is here, and the root copy
is the canonical source rather than the plugin mirror.

### CREATE

- [x] `Get-ShopifySyncPrLabels` added to the main seam block in `scripts/task/sync-main.ps1`, with its
      own try/catch so a throwing seam is reported rather than silently costing the store and theme id.
- [x] The labels composed once beside the PR body and applied on BOTH paths -- `@labelArgs` splatted onto
      the `gh pr create`, and `--label "x"` appended to the line the non-merging path prints.
- [x] The create's failure message extended to name the label cause, since gh validates labels before
      opening and a label the repo does not have fails the create outright.
- [x] The seam documented where the other seven are: the script's own seam list, the scaffold block in
      `scripts/task/adopt-shopify-floor.ps1`, `team-shopify`'s README and both skill pages, and a third
      bullet in manual 05-21.
- [x] Two stale counts corrected in `adopt-shopify-floor.ps1` while changing them anyway -- its docstring
      said "other three seams" against a block that had listed four since inbound #1000.
- [x] Plugin mirrors regenerated with `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] 12 new asserts in `scripts/tests/sync-main.tests.ps1`, covering the unanswered default, a bare
      string, an array, blank entries dropped, and a throwing seam. Suite green at 55.
- [x] `adopt-shopify-floor.tests.ps1` green at 36 -- its scaffold text changed.
- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] The `@labelArgs` splat measured against Windows PowerShell 5.1 rather than assumed: the bare
      `$labelArgs` form passes an empty string argument when the list is empty, the splat passes nothing.

### DEPLOY: `feat/shopify-sync-pr-label-seam-v1`

`sync-main.ps1`'s merging path opened its PR with a bare `gh pr create`, so a repo whose guardrail
requires every PR to carry a label got a sync PR that went red on CI and could not merge. None of the
eight seams the script read was a label seam, so there was no way to answer it from `repo-config.ps1`
-- which is why a consumer still carried a wrapper around this script purely to get a label on.

`Get-ShopifySyncPrLabels` answers it: a string or an array, empty and absent both meaning no label,
which is the behaviour every existing consumer already had. **The labels go on both paths**, for the
reason inbound #1000 established for the body: the non-merging path is the default one, and a printed
`gh pr create` line without `--label` hands the operator the same red CI one paste later.

Two decisions worth naming. **The labels go on the create rather than a `gh pr edit` afterwards** --
the guardrail reads labels when it runs, so a PR opened bare starts its first check run bare and
labelling a moment later leaves a red run to re-trigger. The cost is that a label the repo does not
have fails the create outright, which is the better end to fail at: the branch is pushed, nothing is
lost, and the message says what to correct. **And it is a seam rather than a route through the workflow
plugin's `open-pr.ps1`**, which would have brought the lint and test gates along too: that couples
`team-shopify` to `contributing-davekjohn`, and the merging path deliberately uses nothing but `gh` so a
consumer on either workflow plugin, or neither, gets the same behaviour. The gates are the cost of that
choice and the script now says so rather than leaving it implied.

A fault in the seam is reported rather than swallowed -- the one answer in that block treated that way,
because its fallback is not a correct answer but a PR a guardrail repo cannot merge.

**Score:** 3

#### What makes this deploy extra special

A `team-shopify` consumer whose CI requires a label on every PR can let the shared sync open and merge
its own PR for the first time: answer `Get-ShopifySyncPrLabels` in `scripts/repo-config.ps1` and delete
whatever wrapper was there to put the label on. The consumer this came from has one to delete. Nobody
else has to do anything -- unanswered, the seam changes nothing at all, and the printed line is byte
for byte what it was.

What it deliberately does not bring is the lint and test gates: those live in `open-pr.ps1`, and reaching
them from here would couple the two plugins. A repo that wants them runs the sync with the merge seam off
and opens the PR through its own route, which is what the default already does.

**Score:** 4

#### Pull Request

A label seam for the Shopify sync PR

