# `feat/team-shopify-push-preview` cycle · 20260821-142444

## PLAN

Inbound [#805](https://github.com/DaveKJohn/claude-code-specialists/issues/805), verified on pickup:
`team-shopify` ships `sync-main.ps1` and `sync-rules.ps1` and no preview push, so the premise stands. The
consumer's own copies were read directly out of `BWJ-ecommerce/xoxowildhearts` rather than reconstructed
from the report, so what ships is the measured code and not a paraphrase of it.

## CREATE

- [x] `scripts/lib/preview-theme.ps1` -- the two argument lists, the flag whitelist, and TWO more readers
      than the consumer's copy had: the id out of the create call's `--json` output and the theme-list
      lookup. Both were inline expressions nobody could test without a store, which is the same argument
      that put the argument lists in a lib
- [x] `Get-ThemePreviewUrl` -- the one URL every store has, carrying the three admin parameters. So a repo
      without a market table gets a working link rather than none
- [x] `scripts/task/push-preview.ps1` -- the four-step resolution, the trunk refusal, the live refusal,
      the git-config memory, lazy creation
- [x] Both registered in `Get-SharedScriptPairs` (task + `LibOnly`), mirrors generated
- [x] `push-preview` skill page, including the `Get-ShopifyPreviewUrls` seam with a worked example
- [x] `team-shopify` README: the new seam table row, why the live id is recommended here and required for
      `sync-main`, and the roster row
- [x] `start-task` rewritten: it opens the branch and no longer creates a theme. Not in #805's scope, but
      the two pages would otherwise contradict each other -- one telling you to create a theme at branch
      time while the other creates it lazily
- [x] The plugin manifest description and the two `<!-- skills:all -->` spans in `README.md`

## TEST

- [x] `scripts/tests/push-preview.tests.ps1` -- 56 asserts, up from the consumer's 38: their whole set
      plus the two new readers (the duplicate-name throw, the PowerShell 5.1 member-enumeration trap, the
      empty-output case) and the preview URL
- [x] Eight affected suites green locally, lint clean, mirrors in sync

## DEPLOY

- [x] `build-shared-scripts.ps1` run -- both mirrors in sync
- [~] Deleting the consumer's local copies -- not this repo's to do. The consumer removes
      `scripts/task/push-preview.ps1` and `scripts/lib/preview-theme.ps1` on adopting this release, which
      is the point of shipping it; a second copy agreeing with the first is the failure #805 names

## Where I left off

Last of the three inbound issues. #802 (PR #808) and #806 (PR #812) are merged and folded.
