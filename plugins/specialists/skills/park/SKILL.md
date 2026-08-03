---
name: park
description: >-
  Park the current branch via the shared, centralized park-branch script from the plugin (single
  source of truth, issue #81) -- so a consumer does not have to duplicate this script locally.
  Commits any outstanding work on the current branch and pushes it to origin with `git push -u`, so
  the exact state is immediately continuable on another device. Opens NO pull request and performs
  NO live/deploy action -- it only backs the branch up to the remote. Use when you want to set a
  branch aside for later ("park it for next time") without opening a PR.
disable-model-invocation: true
---

# park -- the shared branch-parker for consumers

This is the **plugin mirror** of `park-branch.ps1`: the same tested source as in the workshop repo,
shared here so consumers do not duplicate it. Background in
[issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/park-branch.ps1"
```

Optionally record where you left off (appended to the park commit message, so the "what is next"
state lives in git history):

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/park-branch.ps1" `
  -Intent "Skeleton + routing done; next: wire the API client."
```

The script:

1. **Guardrail:** refuses on `main` -- parking is a feature-branch action (everything on `main`
   goes via a PR).
2. Commits **all** outstanding work on the current branch (`git add -A` + commit), so nothing is
   left behind locally -- the changelog entry file and any other WIP travel along. If nothing is
   staged (the branch was already committed locally but never pushed), it skips the commit and just
   pushes.
3. Pushes the branch to `origin` with `git push -u` (sets upstream tracking).

## What parking is NOT

- **No pull request.** Push is not a PR: parking makes the branch reachable/continuable from another
  device, while the PR rule stays intact and separate. Opening a PR remains a separate, explicit
  step (the `open-pr` skill).
- **No live/deploy action.** The script only touches git (add/commit/push). A consumer whose repo
  drives a live target (e.g. a Shopify theme) is never published by a park.

## park vs. new-branch -Park

Both put a branch on the remote without a PR, but they cover different moments:

- **`new-branch -Park`** parks a branch **at creation** and commits **only the changelog entry**
  (leaving other staged work untouched) -- start-and-park in one move.
- **`park` (this skill)** parks an **existing** branch **at any point mid-work** and commits
  **everything** outstanding -- back up a branch you are already working on.

## Requirements in the consumer

Self-contained: the script needs only `git` and a configured, reachable `origin`. It reads **no**
repo-owned config (no `branch-info.ps1`, no `repo-config.ps1`), so there is nothing to scaffold. It
resolves its repo root dual-context via `${CLAUDE_PROJECT_DIR}`.

## Important

- **No PR, ever, from this skill** -- that remains a separate governance step.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/task/park-branch.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
