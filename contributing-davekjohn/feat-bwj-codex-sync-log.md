## feat/bwj-codex-sync-log

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

#### What this branch answers -- inbound #1382

`bwj-codex` is today "BWJ's shared ticket workflow". In practice it is the shared layer for the two
BWJ Shopify store repos, and it is missing its second chapter: **the sync log**. A `sync/` branch is
the only branch in that workflow that owes nothing durable -- the entry gate exempts `sync/`, nothing
folds, and the only account of what a third party did on the live theme is the PR body on GitHub. In
a repo whose standing rule is that a sync PR does **not** wait for review, that body is the whole
review moment, and it lives nowhere the tree can index.

#### Verified on pickup, before anything was built

All six inbound checks pass. `WORKFLOW-portable.md` is 584 lines; `contributing-davekjohn` does ship
three portable pages; `Get-EntryGateExemptPrefixes` does default to `sync`; `Get-SyncFileVerdict`,
`New-SyncPrBody` and the `Get-ShopifySyncPrBody` seam all exist where the report says they do.

#### Two decisions this branch takes that the report did not

- **The PR link is not a field of the entry; the branch name is.** The entry is composed and
  committed *on* the sync branch, before any PR exists -- and the non-merging path, which is the
  default, never learns a PR number at all. The branch name IS the PR's head ref, so the page gives
  the one-line lookup instead of a field that would be blank on the common path.
- **Point 6's conditional gate is DECLINED, and write-at-creation replaces it.** `sync-main.ps1`
  creates the branch and writes the entry in the same commit, exactly as `new-branch.ps1` does -- so
  a sync branch cannot be entry-less and there is nothing left for a gate to catch. Building it would
  also make `contributing-davekjohn`'s generic entry gate learn a `bwj-codex` concept, which is the
  layering the report's own "why this belongs here and not in team-shopify" section argues against.

### CREATE

- [x] `plugins/workflows/bwj-codex/SYNC-LOG-portable.md`: the policy page -- what a sync owes, where
      the record lands, one file newest-first, what it must stay out of, and the entry's shape
- [x] `plugins/workflows/bwj-codex/README.md`: widen from "the ticket workflow" to "the two-repo
      layer", name both chapters, point at the new page
- [x] `plugins/workflows/bwj-codex/.claude-plugin/plugin.json`: widen the description to match
- [x] `.claude-plugin/marketplace.json`: not in the plan, and required by it -- the entry said
      "today it carries one rule", which this branch makes false. The same rewrite retires a claim
      that was already wrong there and in `plugin.json`: that closing the GitHub issue *resolves* the
      Asana task, which both the README and the `report-issue` skill say it deliberately never does
- [x] `scripts/lib/sync-rules.ps1`: `New-SyncLogEntry` -- the second rendering of the SAME rows,
      reusing `Get-SyncPrBodySection` and `Get-SyncFileKind` rather than composing a second time
- [x] `scripts/lib/sync-rules.ps1`: `Add-SyncLogEntry` too, which the plan had inside `sync-main`.
      WHERE an entry goes in the file is pure, and it fails silently -- this file's own stated reason
      for existing -- so it sits where a suite can walk it without running a sync
- [x] `scripts/task/sync-main.ps1`: the `Get-ShopifySyncLogPath` seam -- unanswered means no log, so
      a generic Shopify consumer is untouched; answered means the entry is prepended and rides in the
      branch's own commit
- [x] `scripts/task/adopt-shopify-floor.ps1`: document the new seam in the commented optional block
- [x] `scripts/sync/build-shared-scripts.ps1`: regenerate the plugin mirrors

### TEST

- [x] `scripts/tests/sync-rules.tests.ps1`: `New-SyncLogEntry` -- both halves, the empty halves, and
      that it renders the same rows the PR body renders, bullet for bullet
- [x] `scripts/tests/sync-rules.tests.ps1`: `Add-SyncLogEntry` -- masthead, no masthead, masthead
      with no entries yet, and CRLF in. The headline case is a log whose first line is already an
      entry: `$lines[0..-1]` is "0 through the LAST index" in PowerShell, so the naive arm hands back
      the whole file and duplicates the log rather than prepending to it
- [x] `scripts/tests/sync-main.tests.ps1`: source asserts on the wiring, in that suite's own style --
      the seam's empty default, the two early returns, the fault that costs the log and not the sync,
      and the ordering one that matters: the entry is written BEFORE the path-bounded `git add`, or
      it sits untracked while the run reports a clean success
- [x] Lint gate: 0 errors. The suites are `open-pr`'s own run, which refuses on any failure -- not
      pre-run here, since a second copy proves nothing that gate would not catch

### DEPLOY: feat/bwj-codex-sync-log

`bwj-codex` is now the shared **extra layer** for BWJ's two Shopify store repos rather than only their
ticket workflow, and it has a second chapter: **the sync log**,
[`SYNC-LOG-portable.md`](../plugins/workflows/bwj-codex/SYNC-LOG-portable.md).

A `sync/` branch mirrors what a **third party** changed on the live Shopify theme. It is exempt from
the changelog by design -- that is somebody else's change, not the repo's -- which left it the only
branch in the workflow owing **nothing durable at all**: the sole account of what was taken and what
was held back was the PR body on GitHub, in two repos whose standing rule is that a sync PR does *not*
wait for review. A sync now owes a sync-log entry where an ordinary branch owes a changelog entry:
`bwj-codex/SYNC-LOG.md`, newest at the top, one entry per sync branch, never folded and never released.

**The mechanism is `team-shopify`'s and the policy is `bwj-codex`'s**, which is the seam split the
consumer repos already run. `sync-rules.ps1` gains `New-SyncLogEntry` and `Add-SyncLogEntry`;
`sync-main.ps1` reads one new seam, `Get-ShopifySyncLogPath`. **Unanswered means no log** -- every
Shopify consumer gets the machinery through the update, and none of them finds a new file in its tree
because of it.

Two things are deliberately *not* built, both named on the page rather than left as gaps. There is
**no PR field** in an entry: it is committed on the sync branch before any PR exists, and the default
seam never opens one, so the field would be blank on the common path -- the branch name is the head
ref instead. And there is **no gate**: `sync-main.ps1` writes the entry in the same commit that
creates the branch, the shape `new-branch.ps1` already uses, so a sync branch cannot land record-less
and `contributing-davekjohn`'s generic entry gate never has to learn a `bwj-codex` concept.

The entry is a **second rendering of the same rows**, not a second measurement: it shares
`Get-SyncPrBodySection` and `Get-SyncFileKind` with the PR body, and a suite asserts the two produce
identical bullets from identical rows -- the one assert that fails if they ever fork.

Closes [#1382](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1382).

**Score:** 3

#### What makes this deploy extra special

The two BWJ store repos get a record of third-party live-theme drift that survives the merge, in the
tree, greppable -- where before it lived only in a PR body nobody re-reads. It costs them one line in
`scripts/repo-config.ps1`. Every other consumer notices nothing, which is the design.

**Score:** 3

#### Pull Request

the sync log: bwj-codex chapter two, and a sync branch that leaves a record in the tree

