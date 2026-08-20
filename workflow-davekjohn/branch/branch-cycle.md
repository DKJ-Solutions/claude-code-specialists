# `docs/adoption-page-sequence` cycle · 20260820-143845

## PLAN

- [x] Verify all six inbound issues (#784-#789) still stand at HEAD: nothing under `plugins/` changed
      since `3b4c1703`, the commit they were all measured at
- [x] Recount #784's subject before scoping it. The report says "it is one document"; the tree says two
      -- `INSTALL.md`'s quickstart carries its own Step 2-4 copy of the adoption route and names no
      adopt skill either. Repairing only `ADOPTION.md` would also put the two pages on different step
      counts, which is the defect class this family repaired in #297 and #305
- [x] Check #785's claim against `INSTALL.md` too: its *Switching workflows* section is correct
      ("flip the two `enabledPlugins` keys"), so the false sentence exists only on the adoption page
- [x] Verify the repair #784 proposes before building it: all three adopt skills exist at the paths it
      names, and all three are additive + dry-run by default (their own frontmatter and `-Apply`
      parameter). Two of them append to `scripts/repo-config.ps1` and need it to exist, which step 1
      places

## CREATE

- [x] `plugins/ADOPTION.md`: the workflow-slot bullet states the one act that must be undone in the same
      edit, names `workflow-sessioncheck`'s `[ERROR]`, and says disabling is not uninstalling (#785)
- [x] `plugins/ADOPTION.md`: new **Step 3** -- the adopt skill of every enabled plugin, as a table of
      today's set plus the rule that does not go stale; the lens step becomes Step 4 (#784)
- [x] `INSTALL.md`: the quickstart gains **Step 4** (the adopt skills), the lens step becomes Step 5, and
      the agent-boundary table, its "of the N steps" count, the quickstart summary line and the
      "Steps 2 to 5" pointer follow
- [x] The step-count cross-references follow, per this repo's own count discipline:
      `specialists-init/SKILL.md` ("expect **four steps** there") and four references in `README.md`
- [~] No change to `INSTALL.md`'s "two acts plus two steps that remain": the new step is one an agent
      CAN complete, so it does not join the set that sentence counts

## TEST

- [x] `check-plugin-integrity.ps1`: 0 errors -- the link scan (285 links) is the one that matters here,
      since this branch adds cross-page references and repoints two stale ones
- [x] All 45 test suites run locally: 0 failures
- [~] No new test. The change is prose in four documents; the only machine-read property it touches --
      the `<!-- skills:all -->` spans and the shipped-skill registry -- is already gated by check 10

## DEPLOY

- [x] Read the diff once more as a whole before the push: four documents, one story, no step number
      left pointing at its old neighbour

## Where I left off

After the merge and the fold: close #784 and #785 with the evidence, including the recount that #784 is
two documents rather than one, and that its own headline count ("seven PRs") disagrees with its own
table. Then the remaining four inbound items, in the order Chris set: #787 (the pre-task sync -- silent
data loss, highest risk), #786 (the scaffold contradiction), #788 (the CRLF trap), #789 (the shipped
entry gate).
