# `feat/shopify-pre-task-sync` cycle · 20260820-151657

## PLAN

- [x] Verify #787 still stands: `grep -rn "sync-main" plugins/` returns nothing at HEAD, so the plugin
      ships no sync script and no rule
- [x] Read BOTH reference implementations rather than inventing one. Both Shopify consumers have a local
      checkout on this machine (`connectors/*.json` -> `localCheckout`), so the two hand-written versions
      are readable side by side
- [x] Recount the report's three "seam-worthy" divergences. Two differ for real (`^sync` vs `^[Ss]ync`;
      merges vs stops at the push). The THIRD does not: both write `sync/live-<date>`. It is still a seam,
      for a reason the report gave elsewhere -- it must line up with what the consumer's CI exempts
- [x] Establish the hard constraint before designing: the rule lib must NOT dot-source
      `scripts/repo-config.ps1`. The live-theme guard reads that file on every command inside a
      `try/catch` that returns no theme id, so anything it pulls in is a way to silently disarm the guard
- [x] Establish the second constraint: team-shopify must not depend on `workflow-davekjohn`. One of the
      two consumers now runs `workflow-default`, so every seam is read through `Get-Command`
- [~] The merging variant reads `Get-PrMergeMethod` where a consumer defines it, but requires nothing but
      `gh`. Porting the sibling's `open-pr.ps1`-based route was dropped: it would make the sync depend on
      one workflow plugin

## CREATE

- [x] `scripts/lib/sync-rules.ps1` -- the two queries as a dependency-free lib, with the union pattern
      and its reasoning
- [x] `scripts/task/sync-main.ps1` -- the sync, repo-agnostic, seam-driven, stopping before the merge by
      default
- [x] Both registered in `shared-scripts-lib.ps1` and mirrored into `plugins/teams/team-shopify/scripts/`
      by `build-shared-scripts.ps1`
- [x] `plugins/teams/team-shopify/skills/sync-main/SKILL.md` -- the skill page, every parameter and every
      seam named, plus what each refusal means
- [x] `adopt-shopify-floor.ps1`: the seam block gains the sync's answers, the script gains `-StoreDomain`,
      and both the dry-run hint and the closing report say whether the sync can run yet
- [x] Docs: Sandra's manual gains the procedure and the rule (it referenced "the pre-task sync" three
      times without ever saying what it was), the team-shopify README gains the seam table, the plugin
      description and the two `skills:all` spans gain the skill
- [x] Fixed a contradiction inherited from both consumers: `-SkipPull` promised to run the rule over the
      current worktree while the clean-tree check refused one. It now warns and proceeds there
- [~] No session check for an unanswered `Get-ShopifyStoreDomain`. The guard's hole is a hole; a sync that
      refuses is safe, and a check that fires while nothing is wrong is the check nobody reads on the day
      it is right

## TEST

- [x] `sync-rules.tests.ps1`: 16 asserts, 0 fail -- the union pattern from both sides, the tag fallback,
      the `$null` refusal, and the deletion-is-a-touch case
- [x] `sync-main.tests.ps1`: 16 asserts, 0 fail -- every refusal, plus the rule end to end through the
      script against a fixture consumer with a real bare origin
- [x] Coverage boundary stated in the suite header rather than left as a gap: the Shopify pull and the
      PR/merge branch are not exercised, and the push runs but is not asserted
- [x] `check-plugin-integrity.ps1`: 0 errors -- 35 shared-script pairs, 17 shared entry points, 21
      canonical skills, all picked up
- [x] `check-script-contract.ps1`: 0 errors (the Shopify seams are team-shopify's own, not contract seams)
- [x] Smoke-tested both copies from this repo: each refuses with the marketplace message

## DEPLOY

- [x] Full suite run before the PR, since this branch adds two suites and changes a third's subject

## Where I left off

After the merge and the fold: close #787 with the evidence, including the branch-name recount and the
`-SkipPull` contradiction. Then #786 (the scaffold contradiction), #788 (the CRLF trap -- which is the
other half of what makes the drift READABLE, and belongs beside this), #789 (the shipped entry gate).
