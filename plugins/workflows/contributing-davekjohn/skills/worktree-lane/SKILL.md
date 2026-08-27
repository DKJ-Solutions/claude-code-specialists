---
name: worktree-lane
description: >-
  Open a branch in its own git worktree -- a "lane" -- so one branch can be BUILT while another one
  SHIPS, and hand a lane's branch back to the primary checkout when it is ready to ship. Use this when
  a session would otherwise sit idle waiting on the blocking CI check that ship-pr watches before it
  can merge, and you want to start the next piece of work instead. Also use it with -HandBack to
  release a finished lane's branch so ship-pr can run on it from the primary checkout.
disable-model-invocation: true
---

# worktree-lane -- build in one place, ship in another

This is the **plugin mirror** of `worktree-lane.ps1`: the same tested source as in the source repo,
shared here so consumers do not duplicate it. It is shared for the same reason `new-branch` is --
the collision it works around lives in `ship-pr.ps1`, which every consumer of this workflow runs.

## The problem, measured

`ship-pr.ps1` step 3 is a synchronous `gh pr checks --watch`, and branch protection means the merge
cannot happen before that check is green. Measured in the source repo on August 23, 2026 over the 65
most recent blocking runs: the `pull_request` CI leg has a **median of 8m 01s** (min 5m 06s, p90
9m 39s). At **73 merged PRs in seven days** that is **9h 45m per week** in which the session that
opened the PR can do nothing else. The 135 `push` runs in the same window (median 8m 05s) block
nobody and are deliberately not part of that bill.

**How much of that actually held a person up is not in the repo** -- it depends on whether the ship ran
in the foreground, and no git or gh timestamp records that. So treat 9h 45m as the ceiling of the
saving, not the saving.

## Why the obvious fix does not work

Running `ship-pr.ps1` in the background and starting the next branch in the **same** checkout ends
badly: at step 5 ship-pr runs `git checkout main` in order to fold, which yanks HEAD out from under
the work in progress.

Doing it the other way around -- shipping from inside a worktree while the primary sits on `main` --
fails harder, because git refuses one branch in two worktrees:

```
fatal: 'main' is already used by worktree at '<primary checkout>'
```

That refusal lands **after** the merge has already happened, which is exactly the half-state
`ship-pr.ps1` warns about at that same step: *"the PR is merged, the entry file is still in the root,
and every gate stays green until a release trips over it."* Probed and confirmed on
git 2.54.0.windows.1 rather than reasoned about.

## So the lanes run the other way around

> **The worktree is where you BUILD. The primary checkout is where you SHIP.**

One shipping lane, N building lanes. Branch A ships in the primary -- `git checkout main` is legal
there, because no other worktree holds `main` -- while you build branch B in its own lane. Nothing
collides, and no shipping script is touched.

**And since [issue #985](https://github.com/DaveKJohn/claude-code-specialists/issues/985) (Dave, August 27,
2026) that pairing is the default rather than an option.** `ship-pr.ps1` is started as a background command
and the session carries straight on -- so a lane is not the thing you reach for when two branches happen to
overlap, it is the ordinary next move after every ship. The two halves only work together: backgrounding
without a lane is what pulls `HEAD` out from under the work in progress, and a lane with a foreground ship
saves nothing. `ship-pr` prints the reminder at the moment it begins to wait; the rule itself is in the
[`ship-pr` skill](../ship-pr/SKILL.md).

## Opening a lane

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/worktree-lane.ps1" `
  -Name "feat/next-thing" -Title "The next thing"
```

**In the source repo, run its own copy instead -- `scripts/task/worktree-lane.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since.

- **`-Name`** (required) the branch name, exactly as `new-branch` takes it (`<prefix>/<short-name>`).
  Deliberately **not** validated by this script: `new-branch` owns the prefix taxonomy, and a refusal
  from it rolls the lane back.
- **`-Title`** (optional) the entry title, passed straight through to `new-branch`.
- **`-Intent`** (optional) a note on what the lane is for, passed straight through to `new-branch`.
- **`-Path`** (optional) where to put the worktree. Default: a sibling of the primary checkout,
  `<repo>-lanes/<branch name with the separator flattened>`. Supply it only when that default is wrong
  for your machine.

What it does, in order:

1. Resolves the **primary** worktree from git itself (the first entry of `git worktree list
   --porcelain`), anchored on the dual-context repo root (`${CLAUDE_PROJECT_DIR}`, else the git root).
   The anchor only tells git *which repository* to answer about; git's own ordering decides which
   worktree is primary. That distinction matters: in a session that **is** a lane, the project dir holds
   the lane, so reading the answer straight off the variable would be wrong.
2. Fetches `origin` and bases the lane on `origin/main`, not on the local trunk. The "fresh pull before
   every new branch" rule applies to a lane exactly as it does to a branch, and reading origin directly
   also means the lane does not care what the primary currently has checked out.
3. Adds the worktree **detached** at that commit.
4. Delegates to `new-branch.ps1` with the lane as its `-RepoRoot`, so the branch and both branch files
   come into being **inside** the lane. Every rule `new-branch` enforces therefore holds in a lane
   without being restated.
5. If that delegation fails, **removes the worktree again** and exits non-zero. That rollback is what
   lets step 3 run before the branch name has ever been validated.

**It never touches the primary checkout's HEAD.** Opening a lane while a ship is running in the primary
is the entire use case.

## Handing a lane back

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/worktree-lane.ps1" -HandBack
```

- **`-HandBack`** close a lane and give its branch back to the primary checkout, so `ship-pr` can run
  there.
- **`-Lane`** (optional, with `-HandBack`) which lane to hand back. Default: the worktree you are
  standing in.

What it does, in order:

1. **Refuses if the lane tree has uncommitted work.** `git worktree remove` refuses that by itself, but
   only after this script has already committed to the path; saying it here gives the actual next
   action. Note that a *freshly opened* lane is always in this state -- `new-branch` writes the two
   branch files and does not commit them.
2. **Refuses if the primary tree is dirty.** It is about to receive `git checkout <branch>`, which would
   either fail halfway or drag those edits across.
3. **Steps out of the lane**, then removes it **without `--force`**, so git's own safety net stays the
   last word. Stepping out first is necessary rather than tidy: on Windows the process's working
   directory holds an open handle, so removing the lane you are standing in fails with
   `Permission denied` -- and standing in it is the normal case.
4. Checks the branch out in the primary and says that `ship-pr` runs from there.

### Why a hand-back is needed at all

A branch checked out in a lane cannot also be checked out in the primary -- the same git refusal quoted
above, mirrored. So the lane has to release the branch before the primary can ship it. Two commands,
once per lane.

**The alternative was considered and declined.** A one-line change to `ship-pr.ps1` -- fold via whichever
worktree holds `main` instead of `git checkout main` -- would remove those two commands. It saves nothing
in wall-clock, and it changes the single line that produces the state nothing reports. Declined on that
trade, deliberately, not overlooked.

### `git worktree remove` is not atomic, and the script does not pretend otherwise

Measured on the `Permission denied` case: git had already emptied the tree **and deregistered the
worktree**, and failed only on deleting the now-empty directory. A non-zero exit there does not mean
nothing happened. So on failure the script asks git what it actually thinks now, and either reports a
genuine no-op or continues while naming the leftover folder.

## What this skill does NOT do

- **It opens no PR, merges nothing, folds nothing.** A lane is a place to work; shipping stays exactly
  where it was.
- **It removes no branch**, locally or on the remote. Removing a lane leaves its branch untouched;
  branch cleanup is the `prune-merged` skill's.

## Where lanes live

Outside the repo, in a sibling `<repo>-lanes/` directory, and that is deliberate: a worktree inside the
tree would be walked by the lint gate's link scan and by the test suites, which would report a second
copy of the whole repo as findings.

## Requirements in the consumer

The script itself needs only `git`. Because step 4 delegates to `new-branch.ps1`, a lane inherits that
script's requirement: `scripts/lib/branch-info.ps1` in the consumer's repo root (`Get-BranchInfo`,
`Test-BranchName`). If that is missing, `new-branch` says so and the lane is rolled back.

## Important

- **Ship from the primary, always.** That is not a style preference; it is the git constraint this whole
  skill exists to work with.
- This script is maintained in the source repo; do not modify it locally in the consumer. A change lands
  first in the source (`scripts/task/worktree-lane.ps1`) and then travels via a release to the plugin
  mirror -- guarded by the shared-scripts drift lint.
