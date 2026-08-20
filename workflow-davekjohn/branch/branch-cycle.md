# `fix/workflow-folder-history-split` cycle · 20260820-155447

## PLAN

- [x] Verify #786 still stands at HEAD: the scaffold writes the `## Release history` heading, the table
      and the "the cut inserts a row" VUL-IN (`adopt-workflow-folder.ps1`), while the closing advice
      says to leave `Get-ReleaseHistoryPath` at `releases/README.md`
- [x] Check which of the report's two options the SOURCE itself already took: option 1. This repo's
      `workflow-davekjohn/releases/README.md` carries no table and points at the root list (Dave,
      August 19, 2026), so the scaffold had simply not followed that decision
- [x] Recount the report's mechanism before building its proposal. **Two of its claims are false:**
      `cut-release.ps1:925` warns `"<path> is missing -- row not added"` rather than creating a second
      file, so "the cut creating a never-scaffolded history file" and "nothing warns" both fail
- [x] Measure what a SCAFFOLDED-but-headingless root file would do: `Test-Path` true, so the row is
      filed, while `Get-OverviewTargetMajor` returns `$null` and the major guardrail is skipped. A hole
      with a comment on it -- the failure adopt-shopify-floor already refuses for `VUL-IN` stubs

## CREATE

- [x] The scaffolded folder page states this repo's release ANSWERS and names the seam's answer instead
      of carrying a table
- [x] `$historyRelPath` read through `Get-Command Get-ReleaseHistoryPath`, so the pages name the repo's
      own path -- the same repair `cut-release`'s missing-file warning had on August 4, 2026
- [x] The other three places carrying the same claim: the script header, the folder README's table row,
      and the folder `CLAUDE.md`'s rules list
- [x] The closing advice prints the exact shape the root file needs, why this command will not write it,
      and the warning the cut gives if it is forgotten
- [x] The skill page: the frontmatter description, the tree listing, and a section with the measurement
- [~] The root history file is NOT scaffolded. That is the report's proposal, declined on the measurement
      above and stated as a decision in both the script output and the skill page rather than left silent

## TEST

- [x] `adopt-workflow-folder.tests.ps1`: the assert that demanded the table now asserts its absence and
      that the page names where the list lives -- 25 asserts, 0 fail. That inverted assert is the
      regression guard on this contradiction
- [x] Ran the scaffolder into a scratch tree and read the generated page and the closing block as a
      reader would, rather than trusting the asserts
- [x] `bootstrap-drift` (126) and `release-lib` (408): 0 fail -- the two suites that could have been
      holding the old shape
- [x] `check-plugin-integrity.ps1`: 0 errors

## DEPLOY

- [x] Own up to a process slip in the report rather than quietly fixing it: this work started on `main`.
      I checked the trunk out to read `cut-release.ps1` and kept editing there -- the exact trap Chris's
      lens names, on a follow-up assignment inside one conversation. Nothing was committed, so
      `new-branch` carried all four files across intact and the cost was zero

## Where I left off

After the merge and the fold: close #786 with the evidence, including the two falsified claims and why
the proposed scaffolding was declined. Then #788 (the CRLF trap) and #789 (the shipped entry gate).
