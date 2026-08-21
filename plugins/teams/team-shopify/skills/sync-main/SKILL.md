---
name: sync-main
description: Mirror the live Shopify theme into this repo's trunk without letting live overwrite the trunk's own work -- the pre-task sync, with the content rule that makes it safe. Use it at the START of any theme task, before creating a branch, since a live theme has no locking and third parties edit it through the theme editor while you work. Reads from live into a mirror outside the repo and writes to git only: it never pushes to live, publishes a theme, or deletes one. Run it with -DryRun first to see every verdict without writing anything. Stops before the merge by default, so somebody sees what changed on live before it becomes the base of new branches.
---

# sync-main -- mirror live into the trunk, without losing what the trunk did

A live theme has **no locking, no merge and no conflict detection**. Third parties edit it through the
theme editor and the last write wins, silently. So work in a Shopify repo starts by mirroring live into
the trunk -- and the obvious implementation of that, a wholesale pull committed straight onto the trunk,
knows nothing about what the trunk has done since and therefore **overwrites it**.

This command is that step with the rule that fixes it:

> Has this path ever held live's content in the trunk's history? Then the **trunk** wins. Otherwise
> **live** wins -- and if the trunk also changed it, **nobody** wins and a human looks.

## Run it

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/sync-main.ps1" -DryRun
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/sync-main.ps1"
```

`${CLAUDE_PLUGIN_ROOT}` resolves **only inside a plugin-owned component** -- that is, when your Claude
runs this skill. Typing the command by hand in a terminal means spelling out the absolute path to your
own plugin cache instead, so the easy route is to ask for the skill rather than to copy the line.

**Run `-DryRun` first.** It pulls live into a mirror, prints the verdict for every differing path, and
writes nothing at all -- no branch, no commit, no push, and the working tree untouched. It is deliberately
allowed on a **dirty** tree, because a dirty tree is exactly when somebody wants to ask what the sync
would do to it.

## What it does, in order

1. **Refuses unless the working tree is clean.** A sync must not carry your work into it. `-DryRun` is
   exempt: it writes nothing.
2. **Switches to the trunk and fast-forwards** from `origin`.
3. **Reads the conflict-check reference point** -- *before* the pull, on the state the pull is about to
   change. Reading it afterwards would read it off a tree that already holds live's version of
   everything, which is the one ordering mistake that leaves the check useless while looking fine.
4. **Decides the sync branch's name**, before anything is pulled. A name that cannot be created is a
   reason to stop while the tree is still clean, not after several hundred files have been written.
5. **Pulls the live theme into a mirror outside the repo** and compares it against the trunk. Two stages,
   for speed: an in-process object-id comparison first, then the same comparison with CR bytes ignored --
   which is how the CLI's line-ending rewrites (measured at **37 of 712 files** on one real store) drop
   out before any rule sees them. Both halves are in
   [Steven's manual](../../manuals/05-22-manual.md#the-cli-rewrites-line-endings-and-that-is-a-property-of-the-tool)
   with the measurements (inbound
   [#788](https://github.com/DaveKJohn/claude-code-specialists/issues/788)).
6. **Decides a verdict per differing path** -- `keep-trunk`, `take-live` or `conflict` -- and prints all
   three lists. What it held back is the half a reviewer cannot see from the diff: the diff shows what
   came in, not what was kept out.
7. **Writes, commits and pushes only the `take-live` paths** on a sync branch. Whether it then merges is a
   seam answer, and the default is no.

## The three things that make it unable to destroy work

Not "unlikely to" -- these are structural, and each one replaces a specific way the wholesale version
lost work:

- **Live is pulled into a mirror outside the repo, never over your working tree**, and the tree is written
  only for the paths whose verdict is `take-live`. The wholesale version pulled over the tree first and
  then restored what it should not have taken -- so every bug in the rule was a bug that had **already**
  overwritten the file, and any failure in between left the damage standing. Not theoretical: the run that
  exposed the floor bug died at `git checkout -b` with 31 files staged.
- **It never deletes.** A path the trunk has and live does not is either a file the trunk added and never
  pushed, or one a third party deleted on live -- indistinguishable, and deleting is the irreversible
  option. It is reported, not acted on.
- **Both sides changed the same path is a refusal, not a choice.** Nothing is written at all, and you get
  the `git diff --no-index` line that compares your copy with the mirror's.

## Why content replaced the time window

The rule used to be *"has the trunk touched this file since the last sync? then the trunk wins"*, and that
was the **wrong measurement** rather than a buggy one. Nothing pushes the trunk *to* live except the
per-file release step, and a deletion cannot be pushed that way at all -- so the trunk's changes are
permanently invisible to live and sink below the floor as soon as one more sync commit lands. After that,
**every future sync tries to overwrite them again, forever.**

Content answers the question exactly. If live's bytes are bytes this repo has held for that path before,
live is holding an older version of *our own* file and the trunk has moved on: the trunk wins, however
long ago that was. If they appear nowhere in our history for that path, somebody outside this repo wrote
them -- which is the drift the sync exists to capture.

**Measured both ways in a consumer before it was built** (inbound
[#807](https://github.com/DaveKJohn/claude-code-specialists/issues/807)), because a rule that is safe by
capturing nothing is useless:

| | |
|---|---|
| against live that day | **31** differing files, all 31 content that repo has held. The new rule captures **zero**, correctly -- there was no third-party drift, only the trunk having moved forward. The old rule captured all 31 and was about to revert three merged PRs. |
| replayed over every past "from live" commit | **10 of 11** real third-party drift files come back foreign and are captured. The 11th reverted a single trailing blank line. |

**The floor survives, demoted.** Its only remaining job is to notice that live's content is foreign *and*
the trunk changed the same path recently -- both sides moved -- and refuse. So a wrong floor now costs an
extra conflict report, never silent data loss, which is a far better failure mode for the piece of this
that is hardest to get right.

## Why it stops before the merge

The whole point of the step is a moment where somebody **looks** at what third parties changed on live
before it becomes the base of new branches. Auto-merging removes exactly the review the step exists to
add. The two Shopify consumers this shipped from answer it differently -- one merges once CI is green,
one stops at the push -- which is why it is a seam rather than a decision made for you.

## Parameters

| parameter | what it does |
|---|---|
| `-DryRun` | pull into a mirror, print the verdict for every differing path, and **write nothing at all**: no branch, no commit, no push, and the working tree is not touched. Allowed on a dirty tree, deliberately -- refusing there would make the check unavailable at the one moment it is worth running. Run this first. |
| `-Store` | store domain to pull from, overriding `Get-ShopifyStoreDomain`. For a repo whose seam is not answered yet, or a one-off against a second store. |
| `-MirrorPath` | use a live mirror you already have instead of pulling one, for rehearsing the rule offline. The mirror is read and never modified. |
| `-KeepMirror` | do not delete the pulled mirror afterwards. A **refused** run keeps it regardless, because the conflict report names files inside it. |
| `-StopBeforeMerge` | push the sync branch and stop, even where `Get-ShopifySyncMerges` says to merge. The escape valve runs in the **safe direction only**: there is no switch that forces a merge the seam has not asked for. |
| `-ChecksTimeoutMinutes` | how long to wait for CI on the sync PR before giving up and leaving it unmerged. Only used when the seam says to merge. Default: `15`. |
| `-SkipPull` | **retired.** It meant "run the rule over the working tree", which cannot mean anything now that the pull goes to a mirror and the tree is written only for `take-live` paths. It is still accepted, purely so the refusal can name what replaced it: `-DryRun` or `-MirrorPath`. |

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
**aborts on the first run**. `^[Ss]ync` is exactly the two spellings in use and nothing wider.

**And no pattern can fix a body line, which is why that one is handled in the lookup itself.** `--grep`
matches any *line* of a message, so it cannot tell "the subject starts with sync" from "a body line
starts with sync". A merge commit carries the merged commit's subject in its body, so right after a sync
PR lands the merge matches and the floor becomes `HEAD`; the lookup took `--no-merges` for that (inbound
[#801](https://github.com/DaveKJohn/claude-code-specialists/issues/801)).

**That flag was necessary and not sufficient, and the lookup no longer uses `--grep` at all** (inbound
[#819](https://github.com/DaveKJohn/claude-code-specialists/issues/819)). `--no-merges` removes merge
commits and nothing else, so an *ordinary* single-parent commit whose body happens to open a line with
`sync` still became the floor -- a commit message that merely **discusses** the sync script was enough.
Measured in a consumer that had already taken the `--no-merges` repair: the floor landed 48 minutes too
late, on a `fix:` commit, and `floor..HEAD` fell from 13 commits to 5 -- eight commits of trunk work
reading as untouched and about to be overwritten by live, on a run reporting a reference point and
looking green. So the pattern is now matched against the commit **subject**, read as its own field.

Nothing about the seam changed: `Get-SyncDefaultReferencePattern` and the pattern you pass still mean
exactly what they did, and still narrow. `--no-merges` stays because a merge's own subject is `merge:`
and keeping the flag makes the intent legible. The suite pins the true positive, the merge, the body
line, and both old shapes, so neither can come back as a cheaper equivalent.

**Which directories are compared is not a seam**, deliberately: the set is defined by the platform
(`assets`, `blocks`, `config`, `layout`, `locales`, `sections`, `snippets`, `templates`), not by your repo.
Naming them explicitly is what keeps everything of the repo's own -- `scripts/`, `CLAUDE.md`, the workflow
folder -- out of the comparison and therefore out of any commit. **Gitignored paths are skipped too**;
`config/settings_data.json` is the case that matters, since a repo that ignores live's settings file would
otherwise see it arrive as brand-new foreign content on every single run.

## When it refuses, and why each refusal is the safe answer

| it says | what to do |
|---|---|
| the working tree is not clean | commit or stash. Your work would otherwise be committed as third-party drift. Or pass `-DryRun`, which writes nothing. |
| `Get-ShopifyLiveThemeId` does not answer with a theme id | run `shopify theme list` and answer it -- see the `adopt-shopify-floor` skill. |
| no store domain | answer `Get-ShopifyStoreDomain`, or pass `-Store` for this run. |
| **no reference point: no matching commit and no tag** | the floor no longer decides who wins a file, but it is what notices that **both** sides changed the same path -- and without it such a conflict would be taken silently. Tag the current state, or sync by hand this once. |
| **REFUSING TO SYNC: both sides changed these paths** | the one case nothing can decide for you. Nothing was written. Run the `git diff --no-index` line it prints for each path, merge the two by hand, commit that, and run the sync again. |
| twenty sync branches already exist for today | something is wrong upstream of this; nothing was written. |
| this repo publishes plugins | you are in the repo this script is maintained in, not a Shopify consumer. There is no live theme here to mirror. |

## Why this ships instead of being written per repo

Two Shopify consumers wrote this script independently, and the first version of it **destroyed work** --
one of them recorded the same wholesale procedure reverting merged work three times in one week. The
exposed party is the *next* consumer, who has no sibling repo to copy from and no reason to suspect that
the obvious implementation of "mirror live" is the one that eats their unpushed work. Inbound
[#787](https://github.com/DaveKJohn/claude-code-specialists/issues/787) is the report;
[#801](https://github.com/DaveKJohn/claude-code-specialists/issues/801) and
[#807](https://github.com/DaveKJohn/claude-code-specialists/issues/807) are the two repairs since.

**And the two halves of this marketplace interact, which nothing said before.** In a repo that has
adopted a changelog, *"merged into the trunk but not live yet"* is a **designed** state -- it is what an
entry sitting in `CHANGELOG.md` means. Every such entry names work a wholesale sync would have reverted.
So adopting the workflow plugin's changelog model makes the naive sync **strictly more dangerous** -- and
it is exactly the state a time window cannot protect, which is why the rule now reads content.

The rules live in `scripts/lib/sync-rules.ps1` as named, tested queries rather than inline, because the
risk is in the queries and not in the policy: the policy is one sentence, while *"has this path ever held
these bytes"* has to answer correctly **for a path the trunk deleted** -- and that is the case both
hand-written implementations got wrong, the second time by writing `--` inline into a native call where it
never reaches git.
