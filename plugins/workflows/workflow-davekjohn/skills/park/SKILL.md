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

**In the source repo, run its own copy instead -- `scripts/task/park-branch.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

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
   left behind locally -- both branch files (the entry and the step list) and any other WIP travel
   along. If nothing is staged (the branch was already committed locally but never pushed), it skips
   the commit and just pushes.
3. Pushes the branch to `origin` with `git push -u` (sets upstream tracking).

## What parking is NOT

- **No pull request.** Push is not a PR: parking makes the branch reachable/continuable from another
  device, while the PR rule stays intact and separate. Opening a PR remains a separate, explicit
  step (the `open-pr` skill).
- **No live/deploy action.** The script only touches git (add/commit/push). A consumer whose repo
  drives a live target (e.g. a Shopify theme) is never published by a park.

## Picking a parked branch back up — measure the plan against the main branch first

**A parked branch is invisible to every ordinary check, and that is a consequence of the design rather
than a defect.** Parking opens **no PR**, so the branch appears in no PR listing, in no issue, and in
nothing `git status` or `git log` prints on the main branch. On a machine that never checked it out,
`git branch --list` does not show it either. **`git ls-remote --heads origin` is the only command that
shows it exists** — so that belongs in whatever start-of-session verification the consumer's
orchestrator does.

**And a park note knows nothing about what happened after it was written**, which is the trap. Measured
in the source repo on August 4, 2026: a branch was parked carrying an 81-line hand-off plan and no
content; the same work was then built on a different branch and merged **1 hour 43 minutes later**,
closing all three of the issues the plan named. The parked branch stayed on the remote — perfectly
intact, entirely superseded — and nothing anywhere reported it. It was found the next morning by listing
remote heads while cleaning up an unrelated merge.

So before executing a line of a parked plan, **measure it against the main branch**, however detailed and
current `workflow-davekjohn/branch/branch-progress.md` reads. A plan that reads as current is not evidence that it is. The cheap checks
first:

```powershell
git log --oneline -- <the files the plan renames or creates>
```

plus the state of any issues the plan claims to close. In the measured case that was two commands, and it
turned a day of planned work into a one-line branch deletion.

**Deleting the remote branch afterwards is deliberately a manual act** in the repo this was measured in —
a parked branch is by definition *not* merged, so its loss is unrecoverable, which is exactly the wrong
thing to automate. Check your own repo's governance before reaching for `git push origin --delete`.

## park vs. new-branch -Park

Both put a branch on the remote without a PR, but they cover different moments:

- **`new-branch -Park`** parks a branch **at creation** and commits **only the branch files**
  (leaving other staged work untouched) -- start-and-park in one move.
- **`park` (this skill)** parks an **existing** branch **at any point mid-work** and commits
  **everything** outstanding -- back up a branch you are already working on.

**The commit says which of the two you got**, since
[#507](https://github.com/DaveKJohn/claude-code-specialists/issues/507): `park: <branch> (all outstanding
work)` against `park: <branch> (the branch files only)`. Until August 7, 2026 both wrote the *same*
subject -- `park: <branch> (work parked for later)` -- so afterwards nothing told you which half of your
work was safely on origin, which is the one question a park exists to answer. Both now run the same
implementation (`Invoke-GitPark` in `park-lib.ps1`), and the scope picks the pathspec **and** the words
from one decision, so a park cannot commit one thing and announce another.

**The name stays `park`, decided rather than defaulted** (Dave, August 7, 2026). A rename to `origin-save`
was proposed alongside the fix, on the grounds that it states the goal — *make sure everything local is
safely on origin* — instead of a metaphor. It was declined once the commit message told the two scopes
apart: the confusion the rename was meant to cure was **which half got saved**, and that is what was
actually wrong. A rename would have cost a consumer-visible transition — the script path, this skill's
name, and every document naming either — for a clarity the fix already delivers. Recorded here so it is a
settled question rather than one that returns.

**Neither was deleted, and the measurement is why.** The proposal on the table was to drop `-Park` as
"parking a branch with nothing in it yet". Across the whole history there are **three** park commits --
**two** of them from `-Park`, one from this script. The two entry points are two *moments*, and both are
used; what was wrong was only that the record could not tell them apart.

## Requirements in the consumer

Self-contained: the script needs only `git` and a configured, reachable `origin`. It reads **no**
repo-owned config (no `branch-info.ps1`, no `repo-config.ps1`), so there is nothing to scaffold. It
resolves its repo root dual-context via `${CLAUDE_PROJECT_DIR}`.

## Important

- **No PR, ever, from this skill** -- that remains a separate governance step.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/task/park-branch.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
