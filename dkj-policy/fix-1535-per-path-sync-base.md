## fix/1535-per-path-sync-base

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

Verified: Get-SyncFileVerdict escalates M+foreign to conflict only on MainTouchedSinceFloor, and that floor is Get-SyncReferencePoint's GLOBAL answer. A path the previous sync never touched gets a floor that post-dates the trunk's own work, so the trunk reads as stationary and live is taken. Repair: per-path base = the most recent sync commit that touched THAT path; none means no agreement point, which is a conflict rather than a take.

#### The reason was verified in the code before anything was repaired

The report says the base is global and that this turns a conflict into a silent take. Read against the
tree, both halves hold:

- `Get-SyncFileVerdict` escalates `M` + foreign to `conflict` **only** on `$MainTouchedSinceFloor`.
- That value comes from `Test-MainTouchedSince -Since $since`, where `$since` is
  `Get-SyncReferencePoint`'s answer -- taken **once**, before the loop, for the whole run.
- A sync commit establishes agreement with live only for the paths it **took**. For any other path it is
  just a trunk commit that happens to be newer than the trunk's own work there, so the trunk reads as
  stationary, the both-sides-moved arm cannot fire, and `take-live` is returned.

So the repair is the report's **first** proposal, not its cheaper interim guard.

#### Where I differed from the report

- **No superset heuristic.** The report offered "before writing take-live, check whether the trunk's
  version contains content live lacks" as a cheaper interim guard. It is not needed once the base is per
  path, and it is a heuristic where the base is a fact: a superset is evidence, not proof, and a second
  rule in this cell is a second thing to keep in step. Considered and declined, recorded here rather
  than silently skipped.
- **No tag fallback per path**, which the report does not mention either way. A tag is a release marker
  and says nothing about agreement with live; the repo-wide answer uses one only as a deliberately wide
  heuristic window. Accepting a tag as one path's base would reintroduce exactly this defect by a second
  route -- a base post-dating the trunk's work on a path never reconciled -- and silently.
- **The "no reference point at all" refusal is kept**, and its stated reason corrected. It said
  *"without it such a conflict would be taken silently"*, which was true of a global base and is now
  false: a path with no agreement point is reported. Kept as deliberate conservatism (a first-ever
  reconciliation belongs with a person, not in a hundred-path conflict list), and both the script and
  the skill page now say that instead. Removing it is a separate decision and was not taken here.

### CREATE

- [x] `Get-SyncCommitShas` -- the subject scan extracted once, so the per-path lookup is not a second
      copy of the reasoning `Get-SyncReferencePoint` carries about where that pattern may be applied
- [x] `Get-SyncPathReferencePoint` -- the most recent sync commit that touched **that** path, `$null`
      where none exists, no tag fallback
- [x] `Get-SyncFileVerdict` takes `-PathAgreementKnown`, defaulting to `$false` -- the protective
      direction, so an unanswered base is a conflict rather than a take
- [x] The two conflicts carry **different reasons**: both-sides-moved, and nothing-known-to-have-agreed
- [x] `sync-main.ps1` asks the base per path, inside the branch where live's content is already foreign
- [x] `[2/6]` says the printed commit is the repo's, and that each path is judged against its own
- [x] Docs: the `sync-main` skill page, Sandra's manual, and the two seam tables
- [x] Mirrored to the plugin via `build-shared-scripts.ps1`

### TEST

- [x] A git fixture rebuilding the measured ordering -- own work on a locale, then a sync taking a
      different path -- asserting **both** halves: that the global floor reads the trunk as stationary,
      and that the per-path answer is `$null` and the verdict a conflict
- [x] The repair does not turn everything into a conflict: a reconciled path the trunk has not touched
      since its own base is still taken from live
- [x] The both-sides-moved arm, which a global floor could not reach
- [x] The `--` case: a path the trunk **deleted** still finds the sync that took it
- [x] `A` and `D` asserted unaffected by the new fact, so a later "make it consistent" pass has to argue
      with a test
- [x] The unanswered-parameter default asserted directly -- 152 asserts in `sync-rules.tests.ps1`
- [x] `sync-main`, `shopify-cli`, `push-preview` green; full lint + test gate via `open-pr`
- [~] Not measured against the consumer's own theme. This checkout has no Shopify store or live theme,
      so the six paths in the report cannot be replayed here; the fixture reproduces the *shape* the
      report names as the tell (a path whose sync history is empty while the trunk has moved). Recorded
      as the limit of what this branch proves.

### DEPLOY: fix/1535-per-path-sync-base

The pre-task sync judges each path against **its own** base -- the most recent sync commit that touched
that path -- instead of against one base taken per run. A path no sync has ever taken has **no**
agreement point with live, and that is now a **conflict** to reconcile by hand rather than a take.

**What it repairs arrived as a green run, which is why it is worth stating in full.** A sync commit
establishes agreement with live only for the paths it actually **took**. Taken globally, that commit is
simply newer than the trunk's own work on every path the sync skipped -- so `has the trunk moved on this
path since the base` answered *no* for work that had moved, the both-sides-moved arm could not fire, and
live was taken over merged-but-unpushed own work with every gate passing.

Measured in a consumer: **six** paths verdicted *take from live* where the trunk was a strict
**superset** of live. Across five locale files, **0** keys would have come in from live against **6**
key-deletions and **7** string reversions -- four of them reverting English strings back to Dutch in the
*default* locale -- plus a canonical-URL rewrite deleted from `layout/theme.liquid`. The sync it measured
from had taken 167 files, and none of those six was among them.

**The conflict now says which kind it is.** *Both sides moved* means there are two sets of changes to
merge; *nothing is known to have agreed* means the path has never been reconciled at all. They lead to
different work, so they no longer share one sentence.

**A tag is deliberately not accepted as a path's base.** It is a release marker and says nothing about
agreement with live -- the repo-wide answer uses one only as a wide heuristic window. Reading a tag as an
agreement point would rebuild this defect by a second route, and silently, which is how the first one
survived. And the new parameter defaults to *no known agreement*: a caller that does not answer gets a
report, never a take. The old default sat on the other side of that choice by accident.

This is the same hole as #353 one layer down. That one was diagnosed as the time-window rule and
repaired by moving to content provenance. Provenance is the right question; it was being asked against a
base that was not per path.

**Score:** 5

#### What makes this deploy extra special

N/A -- this repo's audience is its own developers and the consuming repos, and a Shopify store's shoppers
are not subscribers of a service.

What the consuming Shopify repos get at the next release is the reason this is scored 5 rather than 3:
the sync stops being able to revert merged work, and the run that would have done it was green. The
consumer that filed this is **holding a live push** on exactly those six paths, because the refusal that
correctly blocked the push pointed at a sync that would have reverted the work. That standoff clears.
No configuration changes and no seam moves; the `Get-ShopifySyncReferencePattern` answer a repo already
gave now applies per path as well as repo-wide.

**Score:** N/A

#### Pull Request

The pre-task sync's conflict base is per path, so merged-but-unpushed work is not taken as live drift

