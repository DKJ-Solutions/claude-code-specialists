---
name: tidy-machine
description: >-
  Clear the clutter this workflow leaves behind on a machine, in one command and ten lanes: finished
  branches, stale worktree lanes, branches whose pull request was CLOSED without merging, expired
  backup branches, old stashes, an unfolded changelog entry, the ~/.claude plugin administration,
  install records pointing at a checkout that is gone, plugin/marketplace staleness, and fixture trees
  under the scratch root. It DELETES only what prune-merged can already prove -- an ancestor of the
  trunk, or a tip that is the head commit of a merged PR -- and everything else it classifies and
  hands over with the command, paste-ready. Use it when branches have piled up, as the closing tidy-up
  of a working session, when a lane worktree has outlived its branch, or when you want to know which
  of the trees under your temp directory belong to runs that have ended.
---

# tidy-machine -- the whole-machine tidy, in ten lanes

`prune-merged` answers one question extremely well: **was this branch merged?** This command answers
the ones next to it, and calls `prune-merged` for that one rather than re-deciding it.

## Why it exists, measured

Run in the source repo on **September 10, 2026**, `prune-merged -DryRun -IncludeRemote` found 32 local
branches beside the trunk: **27 provably merged, 5 kept -- and not one of the five was live work.**

| branch | what it actually was |
|---|---|
| `backup/main-pre-sync-20260903` | a 7-day-old pre-sync backup, no PR has ever existed for it |
| `docs/changelog-dropped-ship-cost-v1` | PR #1299 **CLOSED**, unmerged |
| `fix/round-tally-error-wrap-v1` | PR #1243 **CLOSED**, unmerged |
| `fix/branch-doc-per-branch-path-v1` | PR #1260 **CLOSED**, unmerged -- **and holding a whole second checkout** |
| `feat/plugin-version-overview` | PR #1599 **MERGED**, local tip one commit past the merge |

`prune-merged` keeps all five **correctly**: none of them has a merge proof, and inventing one is the
defect inbound [#1191](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1191) measured.
What was missing was a name for what they *are*.

**A closed pull request is a decision a person took on the tracker: this work does not land.** That is
evidence of the same kind as a merged one -- a state outside the working tree -- and it is the only
thing that separates *abandoned* from *in progress* without guessing from a date or a branch name.

## What it may throw away, and what it only reports

**Dave, September 10, 2026, asked what this command may delete on its own: only what is provably
merged.** So:

| | |
|---|---|
| **deletes** | exactly one lane, and only by delegation -- `prune-merged.ps1`, on its own two existing proofs |
| **reports** | everything else, each item with what was measured and the command that would act on it |

**That is the `-IncludeRemote` doctrine turned inward.** `prune-merged` refuses to delete a *remote*
branch and hands over the line instead, because with `deleteBranchOnMerge` on, the only branches a
delete could still reach are the ones whose loss is unrecoverable. An abandoned branch is in exactly
that position from the other direction: **its pull request is closed, so the remote copy is gone and
this clone holds the last one.** A closed PR is strong evidence that nobody wants the work; it is not
evidence that nobody wants the commits.

## Running it

From the root of the consuming repo:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/tidy-machine.ps1" -DryRun
```

**In the source repo, run its own copy instead -- `scripts/maintenance/tidy-machine.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own,
so for them the line above is the correct one.

Look first, then let it act:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/tidy-machine.ps1"
```

| flag | what it does |
|---|---|
| `-DryRun` | change nothing anywhere, including in the one lane that would otherwise act -- it is passed through to `prune-merged` |
| `-CheckoutOnly` | lanes 1-6 only |
| `-MachineOnly` | lanes 7-10 only. Useful mid-flight, when you want the `~/.claude` and scratch answers without anything reading the branch list |
| `-MaxAgeDays <n>` | how old a `backup/*` branch or a stash must be to be reported. Default 14 |
| `-MinFixtureAgeHours <n>` | how old a scratch tree must be before its dead pid counts. Default 24 |
| `-Remote <name>` | the remote `prune-merged` fetches and prunes. Default `origin` |

## The ten lanes

**Per checkout:**

| # | lane | authority |
|---|---|---|
| 1 | **stale lanes** -- a worktree whose branch is finished | reports, with the hand-back command |
| 2 | merged branches and stale tracking refs | → `prune-merged.ps1`; **deletes on proof** |
| 3 | **abandoned** -- a PR CLOSED without merging | reports, with `git branch -D` |
| 4 | **expired backups**, and branches no proof reaches | reports |
| 5 | stashes past the bound | reports -- **never dropped** |
| 6 | an unfolded changelog entry on the trunk | → `check-unfolded-entry.ps1` |

**Machine-wide, once:**

| # | lane | authority |
|---|---|---|
| 7 | the `~/.claude` plugin administration | → `check-claude-home.ps1` |
| 8 | **install records pointing at a checkout that is gone** | reports |
| 9 | plugin and marketplace staleness | → `plugin-versions.ps1` |
| 10 | **fixture trees under the scratch root** | attributes -- **never deletes** |

Six of the ten are a call into a script that already exists and already has its own suite. Only four
carry new logic, and that logic is pure and lives in `tidy-lib.ps1`, which is what lets its suite drive
the classifier over states no machine here has ever been in.

### Lane 1 runs first, and the order is load-bearing

git refuses to delete a branch that is checked out in **any** worktree, and that refusal is raised
*before* the merged/unmerged question is asked. Measured on git 2.54.0.windows.1
([#1760](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1760)):

```text
error: cannot delete branch 'X' used by worktree at '<path>'
```

So a lane holding a provably merged branch makes that branch **unreapable** until the lane goes.
Reported first, you can clear it in the same sitting; reported afterwards, you get git's sentence about
a worktree in the middle of a list of merge proofs. The run also says so explicitly when it finds that
pair, rather than leaving you to notice.

### Lane 3's proof is the name **and** the tip, exactly like lane 2's

A branch **name** proves nothing about which commits were merged -- or closed -- under it, and
`deleteBranchOnMerge` frees a name the moment a PR ends, whichever way it ended. So the closed-PR test
is the same pair test `prune-merged` uses, through the same shared functions rather than a second copy
of them: the ordinal-keyed lookup is precisely the detail a re-typed copy loses silently, and it has
already gone wrong twice ([#1190](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1190),
[#1191](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1191)).

A name whose closed PR ended on a *different* commit is reported as **recycled** and nothing is
proposed for it -- the lookup came up full and belonged to somebody else's work, which is a different
sentence from "no PR found".

### Lane 3's lookup filters on the server, and that was measured

`gh pr list --state closed` **includes merged** -- merged is a kind of closed, and gh has no state
meaning closed-and-not-merged. The first version of this script asked for `--state closed --limit 200`
and dropped merged rows locally. It found **zero** abandoned branches in a repo that has three: where
nearly every PR merges, the 200 most recent closed pull requests are 200 merged ones, so every
genuinely abandoned branch falls outside the window. A filter that is correct and reaches nothing.

`--search is:unmerged` asks GitHub the question instead, so the whole limit is spent on rows that can
actually be a proof. `mergedAt` is still requested and still dropped on, as a belt.

### Lane 4's age bound applies to `backup/` and to nothing else

An age is not evidence: a branch untouched for a month may be a month of not getting round to it. The
one place a date carries meaning is a branch whose **name** says it was made to be temporary, and
`backup/` is this workflow's only such prefix.

An expired backup is reported with **whether it is an ancestor of the trunk**, because the two are not
the same risk wearing one name. One that is holds nothing the trunk does not; one that is **not** holds
commits that exist in this clone and nowhere else -- which is exactly what a pre-sync backup is for
when a sync went non-fast-forward. Measured on `backup/main-pre-sync-20260903`: **not** an ancestor.

### Lane 10 attributes and never deletes, by a decision already taken

`scripts/README.md` settled this before the lane was written, on
[#1668](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1668): those trees are *"left
standing on purpose: `$PID` in the leaf is what makes one attributable to a run that is no longer
alive, and a person can clear it by hand"* -- and it names the alternative by name, *"a sweep by name
pattern in a shared temp directory, i.e. the same delete primitive `New-ScratchPath` exists to
remove"* ([#1659](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1659)).

**An earlier draft of this lane offered exactly that behind a `-ReapScratch` flag. It was removed
rather than defended**, and the suite now pins its absence -- a decision that lives only in prose is
one draft away from being made again.

What is left is worth having on its own, because #1668 also measured that the *first* reading of that
directory was wrong: 413 entries read as leaked fixtures, of which 546 in the same directory were
retained-on-purpose artefacts (`sync-pr-body-*`, written for you to paste into `gh pr create
--body-file`; the gate's capture directories from
[#1636](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1636)) and 162 belonged to an
unrelated tool. **Attribution is the scarce thing, not deletion.** The lane skips both retained labels
by name and reports only trees whose pid is no longer a running process.

## What it never touches

- **No remote branch**, ever, with or without a flag. Same rule as `prune-merged`, same reason, and the
  suite asserts it structurally -- no `--delete` argument appears in the source, in quotes of either
  kind.
- **No stash is ever dropped.** A stash is unrecoverable and invisible to every other guard here.
- **No pull request** is opened, merged or closed, and no issue is touched.
- **Nothing under the scratch root is deleted** (lane 10, above).
- **No working tree is moved by this script.** The one exception is inherited rather than performed:
  `prune-merged`'s step 4c steps off a branch it has just proven merged, and only then.
- **No other checkout is visited.** The machine-wide lanes read `~/.claude`; they do not walk into other
  repositories. Dave's answer on September 10, 2026 was "this checkout plus the machine-wide lanes"
  rather than "every checkout the machine knows about" -- the blast radius of a bug in the second shape
  is repositories nobody had opened.

## Requirements in the consumer

`git`, and `gh` for both PR proofs (optional -- without it only ancestry proves anything, and nothing is
ever classified abandoned). It reads the trunk name from `Get-TrunkBranchName` in
`scripts/repo-config.ps1` when that file exists, defaulting to `main`; nothing else is repo-owned, so
there is nothing to scaffold. It resolves its repo root dual-context via `${CLAUDE_PROJECT_DIR}`.

Lanes 6, 7 and 9 delegate to scripts that may not be present in every consumer; each says so and is
skipped rather than failing the run.

## Important

- **Run `-DryRun` first on any machine you have not run this on.** Lane 2 deletes, and on a clone that
  has never been tidied it will delete a lot -- 27 branches, in the measurement above.
- This script is maintained in the source repo; do not modify it locally in the consumer. A change
  lands first in the source (`scripts/maintenance/tidy-machine.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
