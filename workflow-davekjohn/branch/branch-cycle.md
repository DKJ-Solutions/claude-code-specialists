# `feat/prune-merged-ships-centrally` cycle · 20260821-200502

## PLAN

- [x] Verify inbound #815 against the tree: `ship-pr.ps1:347` merges without `--delete-branch`, and
      `delete-branch` / `push origin --delete` / `git branch -d` appear nowhere in the plugin. Both stand.
- [x] Check the report's reason, and it does not hold. It says the plugin leans on "a per-repo setting
      nobody's docs mention"; the setting is named in **three** places in the plugins -- the
      `specialists-init` checklist (with a paste-ready `gh api`), the `fold-changelog` skill, and Derek's
      persona -- and the reporting repo has both plugins. The gap is reach, not documentation.
- [x] Put the one open decision to Dave, since it is a way-of-working change reaching consumers: is the
      remote half the setting or the flag? Answer: the setting, with a read in `ship-pr` -- no
      `--delete-branch`. Recorded with the three measured reasons in the entry.

## CREATE

- [x] `scripts/task/prune-merged.ps1`: the trunk from the seam, refuse on a dirty tree, fast-forward
      ff-only, `fetch --prune`, then delete only on proof (`-d` on ancestry, `-D` on a merged PR), keep
      and report anything else. `-DryRun`, `-Remote`. No remote branch is ever touched.
- [x] Registered in `Get-SharedScriptPairs` and mirrored to the plugin, byte-identical.
- [x] `plugins/workflows/workflow-davekjohn/skills/prune-merged/SKILL.md` -- required by the registry,
      and it is what a consumer actually reads.
- [x] `scripts/release/ship-pr.ps1` step 7: read `delete_branch_on_merge` after the merge, and only when
      it is `false` name the setting plus the command. Never fails the ship.
- [x] Docs: the `fold-changelog` skill's closing step points at the script instead of prescribing two
      commands; Derek's persona gains the squash half of the `-d`/`-D` rule; his repo lens records both
      halves and that `prune-merged` does not weaken the declined remote-delete permission.
- [x] The two `skills:all` spans in `README.md`, and the workflow README's skill table.
- [~] `--delete-branch` on the merge: not added, on Dave's decision after the three measured reasons.

## TEST

- [x] `scripts/tests/prune-merged.tests.ps1`, 28 asserts: only-the-trunk, merged-goes/unmerged-stays,
      `-DryRun`, dirty-tree refusal, missing-trunk refusal, and the remote left standing -- plus the
      structural assert that no git call in the source carries a `--delete` argument.
- [x] `shared-scripts.tests.ps1` 412 asserts and `script-contract.tests.ps1` 282 asserts still pass with
      the new registry entry.
- [x] Lint gate: 0 errors. It caught two real things -- the missing skill-span entries, and my own prose
      quoting the span marker literally, which the same check then read as an unclosed span.
- [~] A test for ship-pr's step 7: **declared test gap**, not built. That block only runs after a real
      merge, and ship-pr has no suite; the precedent for testing gh-mutating logic here is to split it
      into its own script (`verify-resolved-issues.ps1`), which is not worth it for one read and one
      printed line. Said out loud rather than left as apparent coverage.

## DEPLOY

## Where I left off

## Extra finding, repaired along the way

The workflow README's skill table claims to list every skill and listed 13 of 14: `check-branch-entry`
had shipped without a row. Found by counting when adding `prune-merged`. Repaired, with the reason
written above the table -- dropping the old "The nine skills" heading stopped the count being *visibly*
wrong without stopping it being wrong.
