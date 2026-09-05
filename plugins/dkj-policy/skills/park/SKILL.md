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

This is the **plugin mirror** of `park-branch.ps1`: the same tested source as in the source repo,
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
current `dkj-policy/<branch>.md` reads. A plan that reads as current is not evidence that it is. The cheap checks
first:

```powershell
git log --oneline -- <the files the plan renames or creates>
```

plus the state of any issues the plan claims to close. In the measured case that was two commands, and it
turned a day of planned work into a one-line branch deletion.

**A second trap sits the other way round: the plan may be current and the work may not exist.** Measured
in the source repo on August 27, 2026
([#960](https://github.com/DaveKJohn/claude-code-specialists/issues/960)). A branch carried three `park:`
commits, eight resolved CREATE steps naming edits to three agent defs, three manuals and two lenses — and
its **entire** diff against the main branch was the cycle document, 161 insertions, one file. None of the
named edits were on the branch; none were on the main branch either. They were uncommitted in the other
device's working copy, which no reader of `origin` can see. A session picking that up in good faith either
rebuilds eight changes that already exist, or opens a PR that merges 161 lines the fold then deletes.

So **read the park commit before rebuilding anything.** Every automatic park stamps a `Backing:` line into
its body — steps resolved, files committed on the branch besides the document, files uncommitted in the
working copy the park came from — plus an explicit alarm where the plan reads as **finished** with nothing
behind it:

```powershell
git log -1 --pretty=%B origin/<branch>
```

That command is the only way to read it: a reporter used to print the note under each parked branch
automatically, and it went with `/lock` and `/handover` on August 27, 2026. **The two traps are
independent and both are cheap:** the check above asks whether the plan has been overtaken; this one asks
whether it was ever carried out. A plan can pass either and fail the other.

**Deleting the remote branch afterwards is deliberately a manual act** in the repo this was measured in —
a parked branch is by definition *not* merged, so its loss is unrecoverable, which is exactly the wrong
thing to automate. Check your own repo's governance before reaching for `git push origin --delete`.

## park-cycle -- the automatic one, and you do not run it

Since [#900](https://github.com/DaveKJohn/claude-code-specialists/issues/900) a third script sits beside
this one, and it is here rather than on its own page because the three parking moments are one subject:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/park-cycle.ps1"
```

**A Stop hook invokes it after every turn**, which is the point of it -- so this line is for reading, and
for the rare occasion you want to see why nothing was pushed. It commits and pushes
**`dkj-policy/<branch>.md` and nothing else**, because what another device needs from
a branch in flight is the plan, which phase is running, and where the last session stopped.

**Why a hook and not a habit.** `park` and `new-branch -Park` between them produced **six** commits in the
entire history, while the median merged branch sat invisible on `origin` for **22 minutes** (mean 35, worst
365, nine of 38 over half an hour). An opt-in backup is a backup nobody takes.

**It stops the moment a PR exists, and that is not a nicety.** The DEPLOY lock
([#884](https://github.com/DaveKJohn/claude-code-specialists/issues/884)) refuses the merge once this
document has diverged from what the PR published, so a pusher that kept running after `open-pr` would block
**every merge in the repo** -- and the failure would read as the lock misbehaving rather than as the
pusher. Same reason its fail-safe runs in that direction: when `gh` cannot say whether a PR exists, it does
**not** push. Being one turn stale is a nuisance; an unmergeable branch is a defect.

**And *exists* means ever, not just right now**
([#1035](https://github.com/DaveKJohn/claude-code-specialists/issues/1035)). Scoped to *open* PRs, that
bound lifted again the moment a PR merged — and on the machine that merged, a pruned `origin/<branch>`
then reads as absent, absent reads as *"a local commit nobody can see"*, and the next Stop hook pushes the
branch **back** onto the remote seconds after `deleteBranchOnMerge` deleted it. Measured here: merged at
12:56:25, deleted 12:56:27, re-created 13:05:30, at the PR's own head OID with nothing on it the trunk did
not already have. That is worse than an ordinary stale ref, because it collides with the read directly
above: `git ls-remote --heads origin` is the *only* way a parked branch surfaces, so the signal for real
parked work starts reporting branches that shipped hours ago — each carrying a `park:` commit whose
`Backing:` line reads *2 of 2 steps resolved*, which is exactly what finished work waiting to be resumed
looks like. So the bound asks about **any** PR with this head, merged and closed included, and the question
it is really answering is *has this branch been published?* rather than *is a PR open?*.

**If the work on such a branch genuinely resumed, park it by hand** — `park-branch.ps1`, deliberately.
That judgement belongs to the explicit park; the automatic one refuses and says which state refused it.

**Its commit body carries the `Backing:` note** described under *Picking a parked branch back up* above --
what is actually behind the plan it is publishing, measured on the machine that holds the work. A note, not
a gate: it never changes whether the park happens.

It is silent unless it does something, and it never fails a turn -- it exits 0 on every outcome, including
the ones it refuses on. Two parameters, both for callers rather than for you:

- **`-Quiet`** -- print nothing when there is nothing to do. What the hook passes, so an ordinary turn adds
  no line to the session. A push still reports itself.
- **`-RepoRoot <path>`** -- act on that tree instead of the one resolved from `${CLAUDE_PROJECT_DIR}` or the
  git root. For the suite, and for a caller acting on a worktree lane.

## park vs. new-branch vs. park-cycle

All three put a branch on the remote without a PR. They cover different moments, and only the middle one
is something you ask for:

- **`new-branch`** pushes **at creation**, committing **only the branch document** and leaving other staged
  work untouched. Since #900 that is what happens by **default** -- `-NoPush` is how you opt out, and
  `-Park` is still accepted, announces that it changed nothing, and is the switch this used to need.
- **`park` (this skill)** parks an **existing** branch **at any point mid-work** and commits
  **everything** outstanding -- back up a branch you are already working on. The deliberate one.
- **`park-cycle`** keeps **the one document** current on the remote for the life of the branch, on a hook,
  until a PR publishes it. The automatic one.

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
"parking a branch with nothing in it yet". Across the whole history there were **three** park commits at
the time -- **two** of them from `-Park`, one from this script. The two entry points are two *moments*, and
both were used; what was wrong was only that the record could not tell them apart.

**#900 read that same measurement the other way, and both readings are right.** Three commits (later six)
is proof that each moment is real, *and* proof that nobody parks often enough for an opt-in to work. So the
answer was not to delete an entry point but to stop asking: the creation push became the default and
`park-cycle` took over the middle of the branch. This script is what is left of the deliberate act, and it
is still the only one that commits everything outstanding.

## Requirements in the consumer

`park-branch.ps1` is self-contained: it needs only `git` and a configured, reachable `origin`, reads **no**
repo-owned config (no `branch-info.ps1`, no `repo-config.ps1`), and resolves its repo root dual-context via
`${CLAUDE_PROJECT_DIR}`.

**`park-cycle.ps1` needs a little more, because it has to find the document.** It reads
`scripts/repo-config.ps1` and `scripts/lib/branch-info.ps1` when they exist -- for the folder seam and the
trunk name -- and degrades to the shared defaults when they do not, so a repo mid-adoption gets the built-in
answers rather than a failure. A repo with no `origin` is not a failure either: there is simply nowhere to
park to, and it says so.

## Important

- **No PR, ever, from this skill** -- that remains a separate governance step.
- This script is maintained in the source repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/task/park-branch.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
