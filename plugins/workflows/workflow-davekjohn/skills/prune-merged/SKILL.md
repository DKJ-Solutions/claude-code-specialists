---
name: prune-merged
description: >-
  Tidy the local clone after merges via the shared, centralized prune-merged script from the plugin
  (single source of truth, issue #81) -- so a consumer does not have to duplicate this script
  locally. Fast-forwards the trunk, drops stale remote-tracking refs, and deletes only the local
  branches whose merge can be PROVEN: an ancestor of the trunk, or a branch whose PR is merged. A
  branch with neither proof -- unfinished work, a parked branch, a branch pushed from another machine
  -- is left alone and reported. Touches NO remote branch. Use when merged branches have piled up in
  the clone, or as the closing tidy-up of a working session.
disable-model-invocation: true
---

# prune-merged -- the shared branch-reaper for consumers

This is the **plugin mirror** of `prune-merged.ps1`: the same tested source as in the source repo,
shared here so consumers do not duplicate it. It exists because two consumers had each written their
own copy and the plugin had none — the same argument as
[issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81), reported as
[#815](https://github.com/DaveKJohn/claude-code-specialists/issues/815).

## Branch cleanup has two halves, and only one of them is this script

| half | who does it | what you do |
|---|---|---|
| **remote** | GitHub, via the repo setting *"Automatically delete head branches"* (`deleteBranchOnMerge`) | switch it on once, per repo |
| **local** | this script | run it when branches have piled up |

**The remote half is a setting, not a flag, and that is deliberate.** The setting covers *every* merge
route — the script path, the web UI, another machine, another tool — while `--delete-branch` on
`gh pr merge` covers only the one path it is passed on. `ship-pr` reads the setting after a merge and
tells you, with the command, when it is off; it does not pass the flag. Turning it on:

```powershell
gh api -X PATCH repos/<owner>/<repo> -F delete_branch_on_merge=true
```

**Nothing in this workflow deletes a remote branch**, and that is a decision rather than a gap. With the
setting on, merged branches disappear by themselves, so a remote delete would only ever reach branches
that are **not** merged — exactly the ones whose loss is unrecoverable. All of the risk, almost none of
the benefit. Check your own repo's governance before reaching for `git push origin --delete`.

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/prune-merged.ps1"
```

**In the source repo, run its own copy instead -- `scripts/task/prune-merged.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

Look before you reap:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/prune-merged.ps1" -DryRun
```

`-DryRun` reports what would go and deletes nothing. The fast-forward and the ref prune still run —
neither loses anything, and without them the branch list being reported on is the stale one.
`-Remote <name>` fetches and prunes a remote other than `origin`.

The script:

1. **Refuses on a dirty working tree.** Switching branches with uncommitted work either fails halfway
   or drags the work across. Commit, `park`, or stash first.
2. Switches to the trunk and fast-forwards it (`git pull --ff-only`). **Fast-forward only** — this
   script may advance the trunk and must never merge anything into it. A non-fast-forward is a
   warning, not a stop: the deletions are then judged against the older trunk, which errs towards
   keeping branches.
3. `git fetch --prune` — drops remote-tracking refs whose remote branch is gone.
4. Deletes each local branch whose merge can be **proven**, and only those.

## The proof, which is the whole safety property

- **An ancestor of the trunk** → `git branch -d`. That flag refuses an unmerged branch by itself, so
  the proof is checked twice.
- **Otherwise, a merged PR on GitHub** → `git branch -D`. This is the squash case: the branch's own tip
  is deliberately *not* in the trunk's history, so ancestry can never see it and `-d` would refuse a
  branch that is genuinely finished. The merged PR is what replaces ancestry — which is why the forced
  delete is safe here and nowhere else.
- **Neither** → the branch is **kept**, and the line says why. A parked branch (the `park` skill),
  unfinished work, or a branch pushed from another machine has neither proof, so none of them can be
  lost by this script.

The merged-PR set is read **once** per run (`gh pr list --state merged`) and matched locally, rather than
one lookup per branch. If `gh` is absent or unauthenticated that is not an error: proof (b) simply cannot
be established, the run says so, and every squash-merged branch is kept.

## `git fetch --prune` proves nothing about the remote

It only drops tracking refs for branches **already gone** from the remote, so a clean local list is no
evidence whatsoever that the remote is clean. The script prints the one command that answers it, and it
is worth keeping in mind whenever you reason about what has and has not landed:

```powershell
git ls-remote --heads origin
```

## Why this is a separate command and not part of `ship-pr`

So that a session cannot delete a branch as a **side effect** of shipping a PR. Merging and reaping are
two decisions, and the second one is the destructive one. It also keeps the reaping re-runnable and
inspectable (`-DryRun`) at a moment of your choosing, instead of once per merge whether you were looking
or not.

There is a measured reason not to reach for `--delete-branch` inside the merge either, beyond the route
coverage above: that flag deletes the **local** branch too, and on July 16, 2026 it was measured leaving
the checkout **on the merged branch** — with the fold then running there and having to be undone by hand.

## Requirements in the consumer

`git`, and `gh` for the squash-merge proof (optional — without it those branches are kept). It reads the
trunk name from `Get-TrunkBranchName` in `scripts/repo-config.ps1` when that file exists, defaulting to
`main`; nothing else is repo-owned, so there is nothing to scaffold. It resolves its repo root
dual-context via `${CLAUDE_PROJECT_DIR}`.

## Important

- **No remote branch is ever deleted by this script**, and no PR is opened or merged by it.
- This script is maintained in the source repo; do not modify it locally in the consumer. A change
  lands first in the source (`scripts/task/prune-merged.ps1`) and then travels via a release to the
  plugin mirror -- guarded by the shared-scripts drift lint.
