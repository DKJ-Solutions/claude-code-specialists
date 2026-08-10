## `docs/the-fold-stays-its-own-commit` changelog

### Branch title

The fold stays its own commit, and git is why

### Branch ID

20260810-114156

### Branch type

docs

### What does the change on this branch bring to main?

Inbound [#571](https://github.com/DaveKJohn/claude-code-specialists/issues/571) asked `ship-pr.ps1` to
fold the changelog entry **into** the merge commit, so a PR leaves one commit on `main` instead of a
merge with a `chore: fold ...` sitting on top of it. It is declined, and `ship-pr.ps1` now carries the
reason at the exact step a future reader would propose it again.

The symptom the report measured is real, and better supported than its own figures: it claimed 117
merge commits against 117 folds over 387 commits, while this repo holds **1,420** commits, **398**
merge commits (206 typed `merge: `, plus **192** older `Merge pull request` ones the report's pattern
could not see) and **410** folds, **394** of which sit directly on a merge in first-parent order. The
pair is real; the arithmetic was not.

What decided it was measured rather than argued. The report treated the fold's explicit pathspec — the
guarantee that nothing else in the tree can ride into a commit landing directly on `main` — as a
property that would have to *move*. Git will not let it move: `git commit -- <paths>` while `MERGE_HEAD`
exists returns `fatal: cannot do a partial commit during a merge`, and the whole-index commit that
remains swept an unrelated file straight into the merge commit in the same test — the exact `git add -A`
defect that pathspec was introduced to remove. Two further costs came with it: the merge date falls back
to the clock (a local merge leaves the PR open, so `mergedAt` is empty — the source
[#469](https://github.com/DaveKJohn/claude-code-specialists/issues/469) deliberately moved away from),
and the merge stops passing the repo ruleset's required check, extending to every PR what `CLAUDE.md`
already records about the release commit.

One correction fell out of the verification and is repaired in the same file. The comment beside
`--subject` claimed the flag "applies to the merge-commit method only" and that "gh ignores it there"
for squash. `gh pr merge --help` documents it as "Subject text for the merge commit" with no method
restriction, so a squash consumer's squashed commit is likely titled `merge: <branch> (#NN)` — a type
label that is wrong for a commit which *is* the change. It is flagged rather than fixed: it cannot be
reproduced from this repo, and building a repair on the same unverified reading is what produced the
sentence in the first place.

### Significance

#### Tier 0

A rejected design that is not written down is a design that gets proposed again, and this one is
attractive enough to have been proposed from outside. The reason now sits at step 5, beside the
pathspec it would have broken, with the git refusal quoted so nobody has to re-derive it.

**Score:** 3

#### Tier 1

Nobody but this repo's own developers reads a docstring in `ship-pr.ps1`.

**Score:** N/A

#### Tier 2

The script is mirrored into `workflow-davekjohn`, so a consumer receives the text — but it changes
nothing they can observe: no behaviour, no flag, no output moves.

**Score:** N/A

### Pull Request
