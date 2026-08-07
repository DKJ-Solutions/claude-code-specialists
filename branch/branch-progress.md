## `feat/bump-follows-the-tiers` progress

### Steps

- [x] `Test-ReleaseBumpEarned`: tier 0 only -> patch, tier 1 or higher -> minor
- [x] Extend the refusal to `major` as well -- the suite caught that I had only covered `minor`
- [x] Leave the highlights condition alone: it already requires a tier-2 entry, so it needs no change
- [x] Rewrite the eight asserts that encoded the old rule, stating the new one rather than relaxing them
- [x] `CLAUDE.md`, `CONTRIBUTING.md`, Rendall's lens, the `new-branch` and `cut-release` skills
- [x] Full suite green (26 suites, 0 failures), PR, merge, fold

### Where I left off

Lint clean, `release-lib` 377 asserts green.

**The tests earned their keep twice here.** Eight asserts failed the moment the rule changed -- exactly
the ones that encoded it -- and one of those failures was a real defect rather than a stale expectation: I
had written the refusal for `minor` alone, so a **major** built from tier-0-only work would have passed.
A major is a bigger claim than the bump being refused beside it.

**One thing I told Dave that turned out to be wrong, corrected in place:** I said the highlights trigger
would have to move from bump type to tier 2. It was already
`($highlightsBumps -contains $bumpType) -and ($tier2Entries.Count -gt 0)`. What changed is not the
condition but its standing: it was belt-and-braces while a minor required tier 2, and is now the only
thing stopping a tier-1 minor from handing consumers an empty document.

Queued next, in order: measure `-Park` against `park-branch` before proposing either goes, and weigh
renaming `park-branch` to something that states the goal (`origin-save`). Then `open-pr` enforcing the
type prefix on PR titles, and the workflow analysis with Marlowe's three objections still unanswered.
