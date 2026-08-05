---
name: fold-changelog
description: >-
  Fold a branch's changelog entry files into CHANGELOG.md via the shared, centralized fold script
  from the plugin (single source of truth, issue #81) -- so a consumer does not have to duplicate
  this script locally. Use this on main, immediately after merging a branch, to fold the entry
  files (<branch-name>.md in the repo root) into CHANGELOG.md -- a flat ranked list with no section
  headings, where each entry lands at the position its own impact table ranks it at (furthest reach
  first, highest significance first within a tier) -- and then remove them.
disable-model-invocation: true
---

# fold-changelog — the shared fold for consumers

This is the **plugin mirror** of `fold-changelog-entry.ps1`: the same tested source as in the
workshop repo, shared here so consumers (life-hub, smartwatchbanden, …) do not duplicate it.
The background is in [issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

## Why the entry file exists at all

**A branch never edits `CHANGELOG.md` directly.** Every branch would be modifying the *same* section of
the same file, so with more than one branch open at a time that guarantees merge conflicts — on a file
where a conflict is pure noise, because the two entries never actually disagree. Instead each branch
writes its **own** entry file, and this skill folds it in after the merge, when the conflict window is
already closed.

**The filename is the branch name with `/` replaced by `-`** — branch `feat/new-plugin` → file
`feat-new-plugin.md` in the repo root. **Never add a suffix** such as `-fix` or `-v2`, not even on a
second attempt on the same branch: the fold looks the entry up by the *exact* branch name, so a suffix
breaks the match and with it the automatic removal after folding. You are then left with a folded entry
*and* the file still sitting in the root, which reads exactly like an unfolded branch.

**The entry body carries the description; the fold adds what only exists after the PR.** An entry is one
`##` heading with three named `###` sections under it — the same block in the entry file and in
`CHANGELOG.md`, so what a contributor writes is exactly what lands:

```markdown
## Short strong title

### What does this change do?

…the description…

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

### Type of change

Feat
```

The scaffolder fills in the title and the type from the branch prefix. The fold adds what does not exist
until the merge: it prepends the **`#NN`** to the heading and appends a closing line carrying the
**`PR #NN` link and the merge date**. The separator is a middot.

```markdown
## #468 · Short strong title

…the three sections…

[PR #468](https://github.com/owner/repo/pull/468) · merged 2026-08-05
```

**An entry file written before this format still folds.** It carries an `###` heading with the type as a
middot field and, where the repo had adopted tiers, a `Tier: N` line instead of a table. An entry file
lives only on a branch, so that shape is not distant history — any branch opened before the format
changed still has one. The fold **promotes the heading to `##`** as it lands, and says so on the console:
an `###` in a flat list of `##`s is not an entry boundary to any reader of it, so it would otherwise be
absorbed into the entry above and inherit that entry's PR link.

**The date is the fold's, and it sits at the bottom** (Dave, August 5, 2026). The scaffolder runs when
the *branch* is created, so any date it wrote was the branch's birth date — a branch opened on Monday and
merged on Thursday was filed as Monday's work, in the one document whose subject is when things landed.
So the heading now carries what the author knows (title, type) and the closing line carries what only
the merge knows. The date comes from the PR's own merge timestamp rather than from the clock, because a
fold does not always run in the same minute as its merge.

## The one formatting rule: a body sub-heading is `####`, never `##` or `###`

**`##` makes it a separate change.** Every `##` in `CHANGELOG.md` is read as one entry, so a body
sub-heading at that level becomes a phantom entry — one that declares no impact, therefore reads as an
undeclared tier 0, and gets its own block in the release record.

**`###` makes it a fourth section, and can cost the entry a declaration.** The three named sections sit at
that level, and a section ends at the next heading of that level or above — so a stray `###` truncates
whichever section it lands in. The dangerous version is a *misspelled* section heading (`Who is this For`):
the parser looks for the exact text, so the entry silently loses the declaration the tier and significance
gates read.

Use `####`, or bold. The lint gate checks both halves in the entry file and in `CHANGELOG.md`.

**What makes this worth a rule is *when* it bites.** The entry file looks perfectly fine on its own, and
fine in the changelog after folding. The damage only appears once the release cut lifts the body into the
release notes and any per-plugin changelog — in the artifact a reader finally sees. Measured on a real
release, where a body's two subheadings came out looking like two extra release categories.
**Inspect the generated notes before pushing a release**; that is what the cut's `-NoPush` is for.

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/fold-changelog-entry.ps1" -Branch <prefix>/<name>
```

Without `-Branch` it folds all entry files present in the root. An optional `-RepoRoot <path>`
overrides which repo root the script writes to — for a consumer that runs the fold from a
temporary/detached worktree (e.g. a `ship-pr.ps1` that checks out main elsewhere) and wants the fold
to land there instead of wherever `CLAUDE_PROJECT_DIR`/git-root would otherwise resolve to (issue
#101); omitted, behavior is unchanged. The script:

1. Folds each entry file (`<branch-name-with-hyphens>.md`) into `CHANGELOG.md`, with the PR number + link
   included (retrieved via `gh pr list`).
2. Removes the entry file afterwards.

**Where it lands is decided by the entry's own impact table**, not by a heading and not by a seam.
`CHANGELOG.md` is an intro followed by a flat list of `##` entries, and the fold inserts the block at its
ranked position: **furthest reach first**, and within a tier **highest significance first**. Everything
above the first `##` is the intro and is never written into; a document with no entries yet simply gets the
first one.

**Nothing is consumed.** The `Tier: N` line of a pre-format entry, and the impact table of a current one,
both travel into `CHANGELOG.md` intact. That is a change from when the document had one section per tier: the
*section heading* stated the reach then, so the fold stripped the line. With no heading above the entry,
stripping it would leave the entry declaring nothing — and every downstream reader would take it as tier 0,
which is silent, correct-looking, and wrong in the direction that empties a release document. The documents
that travel outward strip both declarations themselves, at the moment they render.

**An entry that declares nothing is tier 0**, the harmless end: forgetting to classify can never promote
work into a consumer-facing document. The run says so out loud, because such work cannot carry a release on
its own where the repo's release cut checks tiers. **An entry that declares a reach but no significance is
also reported and still folds** — it sinks to the bottom of its tier, which is exactly where a reader of an
unranked entry would put it, and the same place it would rank from if it were scored last.

**What stops the fold before it touches anything**, reported for every entry at once rather than one file at
a time — a fold-all that failed halfway would leave earlier entries folded and their source files deleted:

- a tier the model has no meaning for (`Tier: 5`, `Tier: two`, or an impact row `| 5 | 3 | … |`);
- a significance cell off the scale (`| 2 | 9 | … |`).

**Two refusals disappeared with the sections, and both are structural rather than relaxed:** "could not find
the heading — stopping" (issue #178) has no heading name left to mismatch, and "this repo declares no section
for tier N" has no mapping left to miss — a tier the repo does not use is now a position in the list rather
than an error.

**The script can make that commit itself, and normally should: `-Commit`, or `-Push` to commit and push
in one step.** Both are **opt-in**, so without either the fold is left in the working tree for you to
commit by hand — which is how it ran until August 2, 2026, and four hand-typed fold commits in a single
session is what earned the flags. Committing stays opt-in deliberately: on most repos this commit lands
directly on the main branch, which is a governance exception the repo grants, not something a script
should assume.

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/fold-changelog-entry.ps1" `
  -Branch <prefix>/<name> -Push
```

**The commit names its paths**, so `CHANGELOG.md` and the entry files are the only things that can land
in it however messy the working tree is. That scope limit is the point rather than tidiness: where this
commit runs under a "never commit directly to main, except the fold" exception, an unscoped
`git add -A` would let anything else in the tree ride along under that exception. It is enforced by git
now instead of by care.

## Two things that go wrong in practice

**Check that you are really on the main branch before folding** (`git branch --show-current`).
`gh pr merge --delete-branch` promises in its help to clean up the local branch too, and in practice
turned out to be able to simply leave the local checkout **on the merged branch**. Measured July 16,
2026: the fold then ran there, and the changes had to be moved over by hand afterwards. Do not trust the
flag; trust the check.

**Working from more than one machine: always fold with `-Branch`.** Without it the script folds *every*
entry file present in the root — including one belonging to a merge that another machine is still
folding, which then lands twice. So `git pull` first, then fold your own branch by name. If your fold
push is rejected because you are behind origin, that is harmless: pull and retry.

## Closing step: branch cleanup (#163)

The fold is the **last step of the PR chain**, so branch cleanup belongs here as its fixed
closing step -- not something to remember per repo or per time:

- **Remote** -- a well-configured repo deletes the head branch automatically on merge (the GitHub
  setting *"Automatically delete head branches"*, `deleteBranchOnMerge: true`; see the
  `specialists-init` setup checklist). Nothing to do by hand.
- **Local** -- GitHub never touches your own clone, so finish on `main` after the fold with:

  ```powershell
  git fetch --prune            # drop stale remote-tracking refs (origin/<merged-branch>, ...)
  git branch -d <merged-branch>  # remove the merged local branch
  ```

  `git fetch --prune` matters even when the remote branch was auto-deleted: the stale
  remote-tracking refs otherwise pile up in the local clone until pruned.

## Requirements in the consumer

The script is repo-agnostic, but reads a small block of repo data from the **root** of the consumer
(dual-context: it resolves the repo root via `${CLAUDE_PROJECT_DIR}`):

- `scripts/repo-config.ps1` with `Get-RepoName` (for the `gh --repo` calls). This is the only
  repo-specific file fold needs -- it derives the PR number via `gh pr list` and the entry file name, and
  thus does not dot-source `branch-info.ps1` (unlike `open-pr`). **No changelog-structure seam is read any
  more**: `Get-ChangelogTierHeadings` and the legacy `Get-ChangelogHeading` are retired, because a flat
  document has no section headings to configure. A consumer that still defines either is unaffected --
  nothing calls them.
- A `CHANGELOG.md`. Its intro may be anything the repo likes; the fold only needs to find where the intro
  ends, which is the first `##` heading.
- `git` and a logged-in `gh` CLI.

If `repo-config.ps1` is missing -- typical on a clean consumer -- the script stops before the
dot-source with a clear pointer instead of a raw error (#86). The `specialists-init` bootstrap
puts it in place as a `VUL-IN` scaffold; fill it in (see the workshop repo as a model) before you use
this skill.

## Important

- **Run this on main, after the merge** (after the PR has been merged) — then the PR number exists.
- The script only touches `CHANGELOG.md` + the entry files; nothing else.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/release/fold-changelog-entry.ps1`) and then travels via
  a release to the plugin mirror — guarded by the shared-scripts drift lint.
