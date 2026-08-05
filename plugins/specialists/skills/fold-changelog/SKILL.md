---
name: fold-changelog
description: >-
  Fold a branch's changelog entry files into CHANGELOG.md via the shared, centralized fold script
  from the plugin (single source of truth, issue #81) -- so a consumer does not have to duplicate
  this script locally. Use this on main, immediately after merging a branch, to fold the entry
  files (<branch-name>.md in the repo root) into the repo's changelog section -- one section per tier
  where Get-ChangelogTierHeadings declares them, otherwise the single section Get-ChangelogHeading
  names (## Pull Requests by default, or e.g. ## [Unreleased] on Keep-a-Changelog) -- and then
  remove them.
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

**The entry body carries the description; the fold adds what only exists after the PR.** An entry is
written as a heading plus prose:

```markdown
### Short strong title · Branch-type · YYYY-MM-DD
```

The scaffolder fills in the type and the date from the branch prefix; the fold prepends the **`#NN`** and
appends the **`PR #NN` link**, both of which require the PR to exist. The separator is a middot.

## The one formatting rule: never use `##` in an entry body

An entry heading is an `###`, and a release cut groups entries under `##` category headings (Features,
Fixes, and so on). **So an `##` inside a body climbs out of its category and renders as a sibling of
it** — the release notes then appear to have extra categories that are really one entry's subheadings.
Use `####`, or bold.

**What makes this worth a rule is *when* it bites.** The entry file looks perfectly fine on its own, and
fine in the changelog section after folding. The damage only appears once the release cut lifts the body
into the release notes and any per-plugin changelog — past every gate that could have judged it, in the
artifact a reader finally sees. Measured on a real release, where a body's two subheadings came out
looking like two extra release categories. **Inspect the generated notes before pushing a release**;
that is what the cut's `-NoPush` is for.

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

1. Folds each entry file (`<branch-name-with-hyphens>.md`) into this repo's changelog section of
   `CHANGELOG.md`, with the PR number + link included (retrieved via `gh pr list`). The entry lands
   at the top of that section, below any intro text and above whatever already sits there.
2. Removes the entry file afterwards.

**Which section is decided by the entry's TIER**, and the sections themselves come from the consumer's
`scripts/repo-config.ps1`:

- `Get-ChangelogTierHeadings` -- a map from tier number to the literal heading line, in the order those
  sections appear in `CHANGELOG.md`. The entry declares its tier with a `Tier: N` line (`0` = only this
  repo's own developers notice, `1` = a colleague on the project gets something out of it, `2` = a consumer
  notices); the fold files it under the matching section and then **removes the line**, because from then on
  the section states the tier.
- `Get-ChangelogHeading` -- the legacy single heading, e.g. `## Pull Requests` (this workshop's own
  predecessor) or `## [Unreleased]` (a Keep-a-Changelog repo). Still read where no tier map is declared.

**Both are optional, and a repo needs at most one.** Without either, the script falls back to one
`## Pull Requests` section, which is what it always did — a repo with one section is simply a repo with one
tier, so there is no separate behaviour to opt into or out of.

**An entry with no `Tier:` line is tier 0**, the harmless end: forgetting to classify can never promote work
into a consumer-facing document. The run says so out loud, because such work cannot carry a release on its
own where the repo's release cut checks tiers.

**Two things stop the fold before it touches anything**, both reported for every entry at once rather than
one file at a time — a fold-all that failed halfway would leave earlier entries folded and their source
files deleted:

- a `Tier:` value the model has no meaning for (`Tier: 5`, `Tier: two`);
- a tier this repo declares no section for — refused by name, with the tiers it *does* declare listed,
  rather than quietly filed under a neighbour.

If a configured heading is not found in `CHANGELOG.md`, the fold likewise stops before touching anything and
names both the heading it looked for and the function to set (issue #178).

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

- `scripts/repo-config.ps1` with `Get-RepoName` (for the `gh --repo` calls), and optionally
  `Get-ChangelogTierHeadings` (one section per tier) or the legacy `Get-ChangelogHeading` (a single
  section; defaults to `## Pull Requests`). This is the only repo-specific file fold needs -- it derives
  the PR number via `gh pr list` and the entry file name, and thus does not dot-source `branch-info.ps1`
  (unlike `open-pr`).
- A `CHANGELOG.md` carrying every heading that seam declares.
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
