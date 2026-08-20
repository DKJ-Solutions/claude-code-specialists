# `docs/v4-17-0-release-note` cycle · 20260820-192202

## PLAN

- [x] Read the nine pending entries and rank the tier-2 sections by score, so the page opens with the
      heaviest item that also carries an action.
- [x] Decide the order: five action items first, four no-action records after.

## CREATE

- [x] Rewrite `workflow-davekjohn/releases/audience/4.x/4.17.0.md` from the draft the cut committed --
      audience section in the second person, urgency first, action or "no action needed" stated per item.
- [x] Write the two organisation sections, which cannot be generated.
- [x] Record the timing subtotal from clock readings; the total follows in a second pass after the publish.

## TEST

- [x] Verify every mechanism the page tells a reader to invoke against the tree: `adopt-shopify-floor`
      parameters, `sync-main`'s seams, `adopt-workflow-folder` placing the branch-entry workflow,
      `Get-EntryGateExemptPrefixes`' default.
- [x] Test 7 of the seven (the only one that is a gate): no link into `development/` or `internal/` --
      the page carries no links at all.
- [x] Read the publication target and the open-issue queue at their own source rather than carrying figures
      forward.

## DEPLOY

- [x] Ship via the ordinary branch + pull request route -- the tag holds the draft, and this document is not
      covered by either direct-on-`main` exception.

## Where I left off

Page written and frozen for its pull request. After the merge: publish the GitHub Release with this document
and the development notes as attachments (step 5), then the second timing pass.
