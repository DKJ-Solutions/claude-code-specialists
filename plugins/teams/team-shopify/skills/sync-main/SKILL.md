---
name: sync-main
description: Mirror the live Shopify theme into this repo's trunk without letting live overwrite the trunk's own work -- the pre-task sync, with the exclusion rule that makes it safe. Use it at the START of any theme task, before creating a branch, since a live theme has no locking and third parties edit it through the theme editor while you work. Reads from live and writes to git only: it never pushes to live, publishes a theme, or deletes one. Stops before the merge by default, so somebody sees what changed on live before it becomes the base of new branches.
---

# sync-main -- mirror live into the trunk, without losing what the trunk did

A live theme has **no locking, no merge and no conflict detection**. Third parties edit it through the
theme editor and the last write wins, silently. So work in a Shopify repo starts by mirroring live into
the trunk -- and the obvious implementation of that, a wholesale pull committed straight onto the trunk,
knows nothing about what the trunk has done since and therefore **overwrites it**.

This command is that step with the one rule that fixes it:

> Has the trunk touched this file since the last sync? Then the **trunk** wins. Otherwise **live** wins.

## Run it

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/sync-main.ps1"
```

`${CLAUDE_PLUGIN_ROOT}` resolves **only inside a plugin-owned component** -- that is, when your Claude
runs this skill. Typing the command by hand in a terminal means spelling out the absolute path to your
own plugin cache instead, so the easy route is to ask for the skill rather than to copy the line.

**It is not a dry run**, unlike the `adopt-*` skills, and it cannot usefully be one: the drift it has to
show you does not exist until live has been pulled. What protects you instead is the shape of what it
does -- it reads from live, writes to git, and stops before the merge. Nothing it does reaches the store.

## What it does, in order

1. **Refuses unless the working tree is clean.** A sync must not carry your work into it.
2. **Switches to the trunk and fast-forwards** from `origin`.
3. **Reads the exclusion rule's reference point** -- *before* the pull, on the state the pull is about to
   change. Reading it afterwards would read it off a tree that already holds live's version of
   everything, which is the one ordering mistake that leaves the rule useless while looking fine.
4. **Pulls the live theme.**
5. **`git add -A`.** This is a step and not a tidy-up: the Shopify CLI writes each file with the line
   endings **live** holds, live holds both, so files come back reported as modified with **zero changed
   lines** -- 37 of them on one real store theme. Staging costs nothing for exactly those, because there
   is nothing in them, and it leaves only real content standing. **Read the drift after this, never off
   the raw `git status`** -- and do not reach for `eol=lf` in `.gitattributes`, which is the obvious fix
   and makes it permanent. Both halves are in
   [Steven's manual](../../manuals/05-22-manual.md#the-cli-rewrites-line-endings-and-that-is-a-property-of-the-tool)
   with the measurements (inbound
   [#788](https://github.com/DaveKJohn/claude-code-specialists/issues/788)).
6. **Applies the exclusion rule.** Anything the trunk has touched since the reference point is restored
   to the trunk's version and held out of the sync. It prints what it held back, because that is the half
   a reviewer cannot see from the diff -- the diff shows what came in, not what was kept out.
7. **Commits what is left on a sync branch and pushes it.** Whether it then merges is a seam answer, and
   the default is no.

## Why it stops before the merge

The whole point of the step is a moment where somebody **looks** at what third parties changed on live
before it becomes the base of new branches. Auto-merging removes exactly the review the step exists to
add. The two Shopify consumers this shipped from answer it differently -- one merges once CI is green,
one stops at the push -- which is why it is a seam rather than a decision made for you.

## Parameters

| parameter | what it does |
|---|---|
| `-Store` | store domain to pull from, overriding `Get-ShopifyStoreDomain`. For a repo whose seam is not answered yet, or a one-off against a second store. |
| `-SkipPull` | skip the Shopify pull and run the exclusion rule over whatever is already in the working tree. For rehearsing the rule without touching the network; not for normal use. It also **downgrades the clean-tree refusal to a warning**, because the two would otherwise contradict each other -- a refusal on a dirty tree guarantees the tree never holds what this switch says it holds. Anything of yours left uncommitted is then read as third-party drift, and the warning says so. |
| `-StopBeforeMerge` | push the sync branch and stop, even where `Get-ShopifySyncMerges` says to merge. The escape valve runs in the **safe direction only**: there is no switch that forces a merge the seam has not asked for. |
| `-ChecksTimeoutMinutes` | how long to wait for CI on the sync PR before giving up and leaving it unmerged. Only used when the seam says to merge. Default: `15`. |

## The seam answers it reads

All from your own `scripts/repo-config.ps1`, all read defensively -- an absent function falls back to the
default beside it. `adopt-shopify-floor` writes the block; the two required ones refuse rather than guess.

| seam | default | what it decides |
|---|---|---|
| `Get-ShopifyLiveThemeId` | **required** | which theme is live. A non-numeric answer counts as no answer, exactly as the guard reads it -- a `VUL-IN` left in place would otherwise read as answered. |
| `Get-ShopifyStoreDomain` | **required** | the store the pull reads from. `-Store` gets you through one run; answering the seam is the durable fix. |
| `Get-ShopifySyncReferencePattern` | `^[Ss]ync` | the `--grep` pattern that recognises a previous sync commit. |
| `Get-ShopifySyncBranchPrefix` | `sync/live-` | the drift branch's prefix. It has to line up with whatever your PR guardrails and CI exempt, which is why it is yours to set. |
| `Get-ShopifySyncMerges` | `$false` | `$true` opens the PR and merges it once CI is green. |
| `Get-TrunkBranchName` | `main` | the trunk. |
| `Get-PrMergeMethod` | `merge` | read only when `Get-ShopifySyncMerges` is true. |

**Why the default pattern carries a capital.** The two consumers that wrote this script spell their sync
commits differently: one writes `sync: live theme drift <date>`, the other has written `Sync main with
live theme (<store>)` since May 2026 -- capital S, no colon. A pattern that matches one finds *nothing*
in the other, falls through to the tag lookup, finds nothing there either in a repo with no tags, and
**aborts on the first run**, before the rule has ever protected anything. `^[Ss]ync` is exactly the two
spellings in use and nothing wider, because looseness is not free here: the reference point is the **most
recent** match, so a pattern that matches more commits can only move the floor *forward*, and a floor
that is too recent protects fewer files.

## When it refuses, and why each refusal is the safe answer

| it says | what to do |
|---|---|
| the working tree is not clean | commit or stash. Your work would otherwise be committed as third-party drift. |
| `Get-ShopifyLiveThemeId` does not answer with a theme id | run `shopify theme list` and answer it -- see the `adopt-shopify-floor` skill. |
| no store domain | answer `Get-ShopifyStoreDomain`, or pass `-Store` for this run. |
| **no reference point: no matching commit and no tag** | this is the important one. Without a floor **every file looks untouched by the trunk**, so the exclusion rule would pass everything through -- the exact failure it exists to stop, arriving as a green run. Tag the current state, or sync by hand this once. |
| this repo publishes plugins | you are in the repo this script is maintained in, not a Shopify consumer. There is no live theme here to mirror. |

## Why this ships instead of being written per repo

Two Shopify consumers wrote this script independently, and the first version of it **destroyed work** --
one of them recorded the same wholesale procedure reverting merged work three times in one week. The
exposed party is the *next* consumer, who has no sibling repo to copy from and no reason to suspect that
the obvious implementation of "mirror live" is the one that eats their unpushed work. Inbound
[#787](https://github.com/DaveKJohn/claude-code-specialists/issues/787) is the report.

**And the two halves of this marketplace interact, which nothing said before.** In a repo that has
adopted a changelog, *"merged into the trunk but not live yet"* is a **designed** state -- it is what an
entry sitting in `CHANGELOG.md` means. Every such entry names work a wholesale sync would have reverted.
So adopting the workflow plugin's changelog model makes the naive sync **strictly more dangerous**.

The rule itself lives in `scripts/lib/sync-rules.ps1` as two named, tested queries rather than inline,
because the risk is in the queries and not in the policy: the policy is one sentence, while "has the
trunk touched this path" has to answer **true for a path the trunk deleted** -- a deletion is also a
touch -- and that is the case the first hand-written implementation got wrong.
