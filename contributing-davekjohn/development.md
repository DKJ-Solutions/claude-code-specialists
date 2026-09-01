## Development: `fix/sync-guard-merged-by-oid-v1` · 20260901-145845

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

Inbound #1190: the standing-predecessor guard at `[3b/6]` decides a still-standing `sync/*` ref is
merged if its **branch name** appears in `gh pr list --state merged`. These names are date-stamped, so a
name whose branch merged and was deleted comes round again the same day -- and the merged branch then
vouches for the new, unmerged one standing in its place.

#### The six checks on the report, before it was routed

- **Symptom** -- stands. `scripts/task/sync-main.ps1:643` was `if ($mergedHeads -contains $name) { continue }`
  on the up-to-date trunk, a bare name match.
- **Reason** -- stands, and the naming loop at `[3/6]` is what makes it reachable: it frees a name the
  moment neither `refs/heads/` nor `refs/remotes/origin/` holds it, which is exactly what a merge with
  `delete_branch_on_merge` produces.
- **Repair** -- the report offered three, and the one it led with does **not** work. `mergeCommit.oid` is
  a commit written *onto the trunk* by a squash or rebase merge, so it never equals any tip the head ref
  held; comparing against it would read every branch as standing forever. Verified against this repo's own
  `gh` output, where the two fields differ on every merged PR. `headRefOid` is the field that answers.
  Its option (c) -- read `gh pr list --state open` as the positive signal -- was declined too: a pushed
  branch with no PR yet is the ordinary state of this workflow, and that reading calls it merged.
- **Size** -- the report cites lines 515-537; the block sits at 600-660 after the merges since 4.27.0. The
  subject is right, the line numbers are stale.
- **Subject** -- exists: `$mergedHeads`, the `[3b/6]` block, `Get-SyncBranchNamesFromRefs` beside it.
- **Repo** -- correct. The root copy is the canonical source and the `team-shopify` copy its generated
  mirror, so the repair lands here and travels by release.

#### Its sibling was already filed, so nothing is filed here

`prune-merged.ps1` carries the identical bare-name test in **both** passes (`:393`, `:515`) and there the
consequence is worse -- it hands over `git branch -D`. That is [#1191](https://github.com/DaveKJohn/claude-code-specialists/issues/1191),
open, with its own measurement. It is deliberately **not** repaired on this branch: it lives in a
different plugin, needs its own lib, and one subject per branch. The code comment at `[3b/6]` says so, so
the next reader is not left to infer that one fix covered both.

### CREATE

- [x] `scripts/lib/sync-rules.ps1`: `Get-SyncMergedRefTips` (parses `<name> TAB <sha>` rows into an
      ordinal-keyed lookup) and `Test-SyncRefMergedByPr` (name **and** tip, or the answer is no).
- [x] `scripts/task/sync-main.ps1`: ask `gh` for `headRefName,headRefOid` via `@tsv`, read the standing
      ref's tip off the same ref the ancestry test uses, and route the decision through the lib.
- [x] Header doc + the `[3b/6]` reasoning block updated, including why the merge commit was declined.
- [x] `plugins/teams/team-shopify/skills/sync-main/SKILL.md`: it claimed the test was "the same two-part
      test `prune-merged` uses", which this change makes false -- corrected rather than left to contradict
      the code.
- [x] Mirrors regenerated with `scripts/sync/build-shared-scripts.ps1`.
- [~] No change to `prune-merged.ps1` -- #1191, see above.

### TEST

- [x] `scripts/tests/sync-rules.tests.ps1`: 18 new asserts, 129 total. The decision is pure, so the
      reused-name case is tested directly rather than inferred.
- [x] `scripts/tests/sync-main.tests.ps1`: 6 static asserts on the wiring, 113 total. The fixture's origin
      is a local bare repo, so `gh pr list` cannot answer there and every existing guard case runs on the
      ancestry half -- the half that was already correct. Static is the only reach this suite has.
- [x] End-to-end against real `gh` output in this repo: 200 rows parsed, a merged branch at its recorded
      tip reads merged, the same name at any other tip reads standing.
- [x] Full lint + test gate.

### DEPLOY: `fix/sync-guard-merged-by-oid-v1`

The pre-task sync's standing-predecessor guard now proves that the *ref* was merged, not merely that
something once carried its name. Branch names are date-stamped and get reused, so a `sync/live-<date>`
branch that merged and was deleted used to vouch for the brand-new, unmerged branch that took its name
later the same day: the guard reported `all merged`, found nothing standing, and pushed a `-2` branch onto
exactly the pile it exists to prevent. It now compares the standing ref's current tip against the tip the
merged PR carried (`headRefOid`), which also declines a branch somebody pushed one more commit to after
its PR landed, and still recognises the squash-merged ref that lingers on a repo without
`delete_branch_on_merge` -- the case the name match was added for.

**Score:** 3

#### What makes this deploy extra special

A consumer running the pre-task sync gets a guard that fires on the case it was silently missing, so
unmerged sync branches stop stacking behind a name collision. The failure needed no unusual setup -- two
syncs on one day, which is what a busy live theme produces -- and it was invisible from the outside, since
a run that misses a predecessor looks exactly like a run that had none. Measured in
BWJ-ecommerce/xoxowildhearts on September 1, 2026: `4.27.0` reported `1 found on origin, all merged` while
that branch had an open PR. It also unblocks that repo's own issue #57, the retirement of the local
`sync-main.ps1` fork it has been carrying as a bridge.

**Score:** 4

#### Pull Request

The standing-predecessor guard proves the ref was merged, not just its name
