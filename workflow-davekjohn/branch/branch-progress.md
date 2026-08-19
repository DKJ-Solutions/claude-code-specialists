## `docs/claude-md-workflow-layer` progress

### Steps

#### PLAN

- [x] Measure what in the root `CLAUDE.md` is actually plugin-dependent, split into the three
      categories: product payload (stays), teams/specialists (already behind one `@`-import), and
      workflow mechanics (no seam yet).
- [x] Check whether growing `workflow-davekjohn/CLAUDE.md` traps existing consumers — it does not:
      the scaffold ends on a `VUL-IN` slot for repo-specific rules, and no test asserts the file.
- [x] Get Dave's boundary: the workflow half only, specialist prose untouched.

#### CREATE

- [x] `workflow-davekjohn/CLAUDE.md` gains the layering intro, the two gates, and the mechanics of the
      two direct-on-`main` exceptions, with every relative link repointed one level up.
- [x] Root `CLAUDE.md` keeps the rules and every bound, loses the mechanics, and gains the pointer
      paragraph that names the folder page as the layer that wins on conflict.
- [x] Repair the one citation the split broke: Rendall's lens lists "the hand-written documents land
      via a branch + PR" among what the root states operatively, so that clause is back in the root.

#### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors, all 273 links + 21 lens links resolve.
- [x] Read every cross-reference into the shrunk section by hand — anchors resolve, so the lint cannot
      catch a claim that stopped being true.
- [x] Full test suites, as CI runs them: all 43 suites pass in 165s. The first run failed 3 of them on
      one cause — the entry's own relative links. An entry folds into the root `CHANGELOG.md`, so the
      lint resolves its links from the **root**, not from `workflow-davekjohn/branch/`; repointed.

### Where I left off

Two findings that are **not** this branch's to repair, both pre-existing and verified against
`git show HEAD:CLAUDE.md` rather than assumed:

- `.claude/specialists/lenses/05-06-extension.md:236` cites the root's safety-implementation section
  for the measurement that merged the two release documents (twelve releases, 38%). That measurement
  has never been in the root, before or after this branch.
- `.claude/specialists/lenses/06-25-extension.md:358` cites the same section for the record that the
  cut used to run the lint alone and was the least-gated commit in the workflow. Also never there.

Both are pointers into a section that does exist, so the lint's link scan passes them. They belong to
Rendall's and Nolan's lenses respectively.

One follow-up Dave may or may not want, deliberately left out of this scope: the `$folderClaude`
scaffold in `plugins/workflows/workflow-davekjohn/scripts/task/adopt-workflow-folder.ps1` does not
tell a fresh consumer that their folder page is the layer on top of their root `CLAUDE.md` — it only
says so for `CONTRIBUTING.md`. Adding it is payload work, reaches new consumers only, and is
Sylvester's.
