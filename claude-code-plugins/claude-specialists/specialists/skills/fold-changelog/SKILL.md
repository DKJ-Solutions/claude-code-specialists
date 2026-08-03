---
name: fold-changelog
description: >-
  Fold a branch's changelog entry files into CHANGELOG.md via the shared, centralized fold script
  from the plugin (single source of truth, issue #81) -- so a consumer does not have to duplicate
  this script locally. Use this on main, immediately after merging a branch, to fold the entry
  files (<branch-name>.md in the repo root) into the repo's changelog section (## Pull Requests by
  default, or whatever Get-ChangelogHeading names -- e.g. ## [Unreleased] on Keep-a-Changelog) and
  then remove them.
disable-model-invocation: true
---

# fold-changelog — the shared fold for consumers

This is the **plugin mirror** of `fold-changelog-entry.ps1`: the same tested source as in the
workshop repo, shared here so consumers (life-hub, smartwatchbanden, …) do not duplicate it.
The background is in [issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

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

**Which section** comes from `Get-ChangelogHeading` in the consumer's `scripts/repo-config.ps1` --
the literal heading line, e.g. `## Pull Requests` (this workshop) or `## [Unreleased]` (a
Keep-a-Changelog repo). The function is optional: without it the script falls back to
`## Pull Requests`. If the configured heading is not found in `CHANGELOG.md`, the fold stops before
touching anything and names both the heading it looked for and the function to set (issue #178).

Then commit the result (`CHANGELOG.md` + the removed entry files) directly on main.

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
  `Get-ChangelogHeading` (the section to fold into; defaults to `## Pull Requests`). This is the
  only repo-specific file fold needs -- it derives the PR number via `gh pr list` and the
  entry file name, and thus does not dot-source `branch-info.ps1` (unlike `open-pr`).
- A `CHANGELOG.md` carrying that heading.
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
