## fix/1579-shopify-no-store-seam

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Two edits, both in this repo's own layer: the `Get-ShopifyRepoHasNoStore` seam in
`../scripts/repo-config.ps1`, and the `../CLAUDE.md` repo-slot sentence that still calls the floor
check's permanent `[ERROR]` a gap in the check. Nothing under `plugins/` is touched.

#### The premise of #1579 was half true at cut time, and that is why nothing waited

#1579 opens with "now that both #1570 and #1573 have landed". Checked against the tree before routing:
#1573 is merged and its `CLAUDE.md` sentence is quoted correctly, but **#1570's PR #1578 was still in
the merge queue** (`refs/heads/gh-readonly-queue/main/pr-1578-437366a4`), all eight checks green, so
`Get-ShopifyRepoHasNoStore` did not exist anywhere on `main`. That did not block this branch and no
wait was sat through: #1578 touches only `plugins/dkj-teams/dkj-team-shopify/**`, its suite and its own
branch document, so the two file sets are disjoint, and a seam function nobody reads yet is inert.

#### And confirming step 3 needed the hook from that branch, not the one this session ran

The issue's third step -- "confirm the `shopify-floor-sessioncheck` `[ERROR]` no longer fires at session
start here" -- **cannot be confirmed from a session start on this machine yet**, and that is the release
lag this repo already documents rather than a defect. The SessionStart hook runs the plugin's *cached*
copy (`.claude/plugins/cache/.../dkj-team-shopify/4.32.0/`), which predates #1570 and has no third state
to read the declaration with. So the check was proved directly instead, against the hook on
`origin/fix/1570-shopify-floor-no-store-seam`: silent with the seam, `[ERROR]` with it stashed. The
session start here goes quiet on the next release plus a `claude plugin marketplace update`, which
`CLAUDE.md` now says in place of the old "gap in the check".

**#1578 merged while this branch was being written** (`08:40Z`, followed by its fold), so `origin/main`
carries the third state now and this branch was brought up to it by merge -- not rebase, which would
have needed a force-push. The verification was then repeated against the **in-tree** hook at
`plugins/dkj-teams/dkj-team-shopify/hooks/shopify-floor-sessioncheck.ps1`, which is silent. The cached
copy on this machine is still `4.32.0` and still speaks, which is exactly the lag `CLAUDE.md` now
names, so the sentence stands as written.

### CREATE

- [x] `scripts/repo-config.ps1`: the `Get-ShopifyRepoHasNoStore` seam, `$true`, in the file's own
      house style (`$script:` value + accessor) and placed beside `Get-MachineLocalPaths`, whose own
      comment already argues from this same floor check. Pure ASCII, per the file's stated convention.
- [x] `CLAUDE.md` repo slot: the floor-check sentence recast from "a gap in the check (#1570)" to the
      declaration this repo now makes, with the "do not seed a theme id" warning kept and sharpened --
      answering the seam and seeding an id are different acts, and the paragraph now says why.
- [~] Nothing under `plugins/` -- #1570's scope boundary holds, and #1579 puts the guard behaviour and
      the duplicate-guard finding out of scope explicitly.

### TEST

- [x] `scripts/repo-config.ps1` dot-sources under `Set-StrictMode -Off` in a child scope, exactly as the
      check reads it: `Get-Command` finds the function, `[bool]` of it is `$true`, and `Get-RepoName`
      still answers, so nothing above the insertion broke.
- [x] #1570's own hook run against this working copy: **silent** with the seam present, and the full
      `[ERROR]` back with the seam stashed. That is the mechanism proved end to end.
- [x] Repeated against the hook **on `main`** once #1578 merged mid-branch: silent, with the branch
      merged up to `origin/main` rather than rebased onto it.
- [x] Lint gate + all suites via `open-pr.ps1`, exactly as CI runs them.
- [~] No new suite. The seam is a two-line constant with no branches; the behaviour that could regress
      lives in the check, and #1578 already ships `shopify-floor-sessioncheck.tests.ps1` covering the
      declaration in all three states (absent, `$true`, `$false`) against its own fixture repos. A test
      here would assert that this repo currently has no store, which is a fact about the repo rather
      than about any code, and it would have to be deleted on the day that changes.

### DEPLOY: fix/1579-shopify-no-store-seam

This repo now declares that it has no Shopify store, so `dkj-team-shopify`'s floor check stops asking it
for a live theme id it cannot truthfully give. `scripts/repo-config.ps1` answers
`Get-ShopifyRepoHasNoStore` with `$true` -- the seam inbound #1570 added to the check -- and the
`CLAUDE.md` repo slot no longer describes that permanent `[ERROR]` as a gap in the check, because it is
not one any more. The "do not silence it by seeding a theme id" warning stays: a declaration says there
is no store, an id says there is one and names it, and only the first of those is true here. The
session start on a given machine goes quiet once the plugin change reaches its marketplace clone
through a release, which the slot now states rather than leaving a reader to wonder why the message
persists.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing here reaches a consumer of the plugins. Both files are this repo's own layer:
`scripts/repo-config.ps1` is repo-local configuration and never ships, and `CLAUDE.md`'s repo slot is
explicitly the part a copying repo replaces. The seam it answers was shipped by #1570; this branch only
answers it.

**Score:** N/A

#### Pull Request

This repo declares it has no Shopify store, so the floor check goes quiet
