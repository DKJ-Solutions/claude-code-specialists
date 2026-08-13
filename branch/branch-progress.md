## `feat/rename-finds-every-mention` progress

### Steps

- [x] Measure what a rename actually costs, per specialist, before designing anything
- [x] Decide tool-vs-gate, and write down why a name-matching gate was refused
- [x] Build `scripts/sync/find-specialist-mentions.ps1`, deriving the roster instead of hardcoding it
- [x] Add a test suite (`scripts/tests/find-specialist-mentions.tests.ps1`) -- 31 asserts
- [x] Document the tool where a renamer will look for it (`scripts/README.md` + the specialists handbook)
- [x] Fill in the changelog entry
- [x] Code review (Victor) + copy edit (Edith) on the diff
- [x] Repair the three defects review found, and re-measure every figure the docs claim
- [x] Run the lint gate and the full suites
- [~] Mirror the script into the plugin -- dropped for this branch. It is repo-owned until it has
      been used at a real rename; sharing an unproven tool is how a mirror earns maintenance it has
      not paid for.

### Where I left off

Done and green. The three review defects are fixed and each one is recorded in the changelog entry
rather than only in the commit, because all three were the same class: wrong output that looked right.

Every figure the documentation claims was re-measured with the repaired script against `main` (a
worktree at the merge base), and the numbers moved: Chris 179 live mentions in 59 files (not 262/99),
Sebastian 46 in 18, link text 7.5% of 1,291 (not ~10%), the filename form +46%. The earlier figures
came from an ad-hoc `git grep` rather than from the tool being shipped; the ones in the docs now are
reproducible by checking out that commit and running the script.
