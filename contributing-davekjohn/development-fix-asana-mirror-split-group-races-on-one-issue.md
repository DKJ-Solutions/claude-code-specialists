## Development: `fix/asana-mirror-split-group-races-on-one-issue` · 20260903-144410

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

Issue #1306 verified against the tree: all six inbound checks pass. Repair is the comment half only -- state that a state run and a triage run can now overlap on one issue, and that sweep (d) is what recovers the needs-info case. Compare-and-set in Sync-AsanaTaskStage declined per the issue's own recommendation. Plus a matching assert in bwj-codex.tests.ps1.

#### What the verification found, since it changed the scope

All six inbound checks pass, but the working copy was 16 commits behind when the issue was picked up --
PR #1305 merged 13 minutes AFTER #1306 was filed, so the split the issue describes was not in the tree
on first reading. Read against a fetched trunk it is exactly as reported.

Both of the issue's "measured" claims hold: `Sync-AsanaTaskStage` reads membership at
`asana-mirror.ps1:1135` and moves at `:1165` with no compare-and-set, and its forward-only guard
(`:1157`) blocks a BACKWARD move only -- so the stale forward write is not blocked. Sweep (d) does pass
`-Labels` and `-AllowBackward`, so the recovery is real, and `-Reopened` is set at the event call site
only, so the reopen path has no equivalent.

The issue's second candidate -- a compare-and-set in `Sync-AsanaTaskStage` -- is DECLINED, per its own
closing sentence: it is a change to the write path for a failure that self-heals within a day.

### CREATE

- [x] state what the split costs in `asana-mirror.yml`'s concurrency comment: the two classes can now
      overlap on one issue, `Sync-AsanaTaskStage` has no compare-and-set, and sweep (d) is the backstop
- [~] compare-and-set in `Sync-AsanaTaskStage` -- dropped, per the issue's own recommendation: a
      write-path change for a failure the daily sweep already recovers

### TEST

- [x] three asserts in `bwj-codex.tests.ps1` pinning that the comment SAYS SO -- the issue number, the
      overlap, and the named sweep -- following `ci.yml`'s precedent in `workflow-concurrency.tests.ps1`
- [x] two more pinning the MECHANISM the comment promises, read through the PowerShell parser:
      `Resolve-TargetStage` is called at exactly two sites, and BOTH pass `-Labels` as a real argument
- [x] three directions negative-tested -- stripping the paragraph fails exactly the three comment
      asserts; removing `-Labels` from sweep (d) fails the argument assert; and removing it while
      leaving a comment reading `# TODO: consider -Labels here` fails it too
- [x] 192 asserts before, 197 after -- measured on both sides of the diff rather than counted by eye
- [x] `check-plugin-integrity.ps1` green -- 0 errors

#### What the review changed, because both findings were real

The `-Labels` assert was a regex over the call's span first, and the code review broke it: dropping the
argument while leaving any nearby MENTION of `-Labels` passed, which is precisely the silence the
assert exists to break. Rewritten to ask the parser whether a `CommandParameterAst` named `Labels` is
on the call -- the rule `check-plugin-integrity.ps1` already states for the Shopify CLI, where a
comment naming it is not a subject. That also dissolved a second, milder finding: the old anchor was
coupled to the call-site formatting, so reordering the arguments or switching to splatting would have
broken it.

The copy edit caught the count. This says five asserts because 192 and 197 were both measured; the
first draft said four, folding two `Assert-*` calls into one. It also caught the yml comment reusing
the "one pending run" trade -- which argues for keeping the KEY split -- in the position that reads as
the reason for declining the compare-and-set. Those are two different declines on two different
grounds, and the comment now says both and says they are different.

### DEPLOY: `fix/asana-mirror-split-group-races-on-one-issue`

`asana-mirror.yml`'s concurrency comment now names what splitting the group COST, not only what it
bought. Splitting `closed`/`reopened` away from `labeled`/`unlabeled` (#1301) stopped a triage burst
displacing a pending close or reopen -- but it also means those two classes can now run CONCURRENTLY on
one issue, where the single group serialised them. `Sync-AsanaTaskStage` has no compare-and-set, so the
later WRITE wins regardless of which EVENT was later, and the one answer that loses is `needs-info`: a
`state` run holding a pre-label reading resolves a forward floor, forward moves need no permission, and
the card leaves the hold somebody just put it in. Reconciliation sweep (d) puts it back within a day,
because it passes `-Labels` into `Resolve-TargetStage` and so re-derives the hold with `AllowBackward`.

The block is unchanged otherwise and the key is untouched: the queue holds one pending run, so
serialise-and-drop versus run-everything is a real trade with no third option, and the split takes the
better side of it. What was missing was the half that is not visible in the key.

Five asserts keep it that way: three that the comment states the property, and two -- read through the
PowerShell parser rather than as text -- that `Resolve-TargetStage` is still called at exactly two
sites and that BOTH of them still pass `-Labels` as a real argument. The parser is the point rather
than a flourish: a regex over the call's span is satisfied by any nearby mention of `-Labels`, so it
would pass while the argument was gone, which is the exact silence the assert exists to break.

The comment also keeps the two declines apart. The queue holding one pending run is why the KEY stays
split; it says nothing about the write path. `Sync-AsanaTaskStage` is left alone on separate grounds --
a compare-and-set would close the window properly, but it is a change to the write path for a failure
sweep (d) already heals within a day.

**Score:** 2

#### What makes this deploy extra special

The template travels into a consumer's `.github/`, so a consumer reading their own `asana-mirror.yml`
now gets the whole trade rather than the half that improved. Nothing they run changes. The failure it
prevents is a maintainer collapsing the key back to one group -- reading a comment that only lists the
split's benefits and concluding the split was free -- which would silently restore the unrecoverable
dropped `reopened` that #1301 was filed for.

**Score:** 1

#### Pull Request

asana-mirror's concurrency comment names the overlap its split introduces
