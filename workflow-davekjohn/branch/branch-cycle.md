# `docs/branch-portable-entry-shape` cycle · 20260820-081727

## PLAN

- [x] Verify the lock's four counts against the file rather than inheriting them — all four exact
- [x] Verify the four seams it names actually exist — all four in `entry-scaffold-lib.ps1`
- [x] Check the repo-side companion `workflow-davekjohn/branch/README.md` — already current, no defect
- [x] Read the whole page, not the four lines — found a fifth stale claim ("the branch type")
- [x] Establish what the scaffolder really writes, from the template and a live scaffold, not from the doc

## CREATE

- [x] Repair the `branch-deployment` section: what `new-branch` fills in, and what is left for the author
- [x] Replace the `Branch title` paragraph — the title is the `Pull Request` section's first line
- [x] Cite the seams as the source of truth for which sections exist, keeping the wording as an example
- [x] Step 6: "the Significance sections" → the tiers the entry carries; **live anchor on line 311 kept**
- [x] The fold's six-item list: four of the six were retired sections
- [x] `new-branch.ps1`: reword the printed "Significance sections written at tier 0"
- [x] Rebuild the plugin script mirror for `new-branch.ps1`

## TEST

- [x] Grep the page: only the live `#significance--…` anchor and the deliberate retired-name statement left
- [x] `check-plugin-integrity.ps1` + all suites — lint 0 errors; 44 suites, 0 failing

## DEPLOY

## Where I left off

Repair the half-migrated entry-section claims in BRANCH-portable.md, citing the seams rather than the literals.

Two open inbound issues the lock did not account for — **#776 and #777**, filed four minutes before it was
stamped — are Dave's to rank against the v4.15.0 cut. Not touched here.
