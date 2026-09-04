## fix/1416-trunk-gap-one-definition

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

Issue #1416: `new-branch.ps1` carries a second inline copy of the trunk-gap measurement that #1405 moved
into `Get-TrunkGap`. Put the scaffolder on the shared function so the measurement has one definition, and
leave the policy question -- whether `new-branch` should refuse rather than warn -- exactly where the issue
left it, because that is not this branch's to settle.

#### The one thing that is not a straight swap

`Get-TrunkGap` narrows its fetch to `origin <trunk>`; `new-branch.ps1` fetched all of `origin`, and the
resume probe below it reads `refs/remotes/origin/<branch>` off the back of that same fetch. That ref is how
a branch parked from another device is recognised (#1139), and a narrowed fetch never creates it -- so a
naive swap reopens #1139 silently, in a run where both halves look correct. The switch is what makes the
scope the caller's to state rather than the function's to guess.

### CREATE

- [x] `Get-TrunkGap` gains `-FetchAllRefs`: the fetch is `origin <trunk>` by default and every ref when the
      caller says it is reading more than the trunk off it. Header paragraph states why, and the
      `#1313` note above the fetch stops saying "both callers", which is no longer the count.
- [x] `new-branch.ps1`'s inline block is replaced by one `Get-TrunkGap -RepoRoot $repoRoot -Trunk $trunk
      -FetchAllRefs` call. `$tracked`/`$fresh`/`$behind` are gone; `.Measured`, `.Fresh`, `.Behind` and
      `.Ref` take their place, and every printed sentence is byte-identical.
- [x] The mechanism comments (`THE LOCAL QUESTION GATES THE NETWORK ONE`, the `HEAD..` choice, the
      `-DiscardStderr` essay) go with the mechanism -- they are in `Get-TrunkGap` and in
      `Invoke-NativeCapture`'s header already. What stays in `new-branch.ps1` is what it DOES with the
      number: warn rather than refuse, and say it twice.
- [x] Mirrors regenerated with `scripts/sync/build-shared-scripts.ps1` -- both edited files are shared
      scripts.

### TEST

- [x] `scripts/tests/new-branch.tests.ps1` -- 187/187 green, unchanged. The six wording asserts under
      `#1046` are what prove the swap is behaviour-neutral, and the parked-branch fixture under `#1139` is
      what proves `-FetchAllRefs` is load-bearing rather than tidiness: it exists only on the bare origin,
      so a narrowed fetch would have failed that assert.
- [x] No test was added. The suite already pins every sentence this block prints and the one ref-scope
      consequence a regression would take; a new assert would restate what those hold.
- [x] The lint + test gate via `open-pr.ps1`, which is also where the other `Get-TrunkGap` caller (the
      fold) is re-proven.

### DEPLOY: fix/1416-trunk-gap-one-definition

`new-branch.ps1` no longer measures the trunk gap itself. The ref probe, the fetch, the
`HEAD..origin/<trunk>` count and the fresh-versus-last-seen distinction are `Get-TrunkGap`'s, which is
where #1405 put them, and the scaffolder now calls it instead of carrying a second copy.

The two copies existed for one merge. `Get-TrunkGap` was written *because* `new-branch.ps1` had already
established the shape -- the function's header cites that block for the ref-gating, the `HEAD..` choice and
the fresh/stale wording -- and moving the scaffolder onto it was deliberately scoped out of a fix for the
fold. Nothing was broken; the cost was the ordinary one, that two copies of a measurement drift when only
one of them is corrected.

`Get-TrunkGap` gains one switch, `-FetchAllRefs`, and it is load-bearing rather than thoroughness. The
default fetch is narrowed to the trunk, which is right for the fold and wrong for the scaffolder: the
resume probe reads `refs/remotes/origin/<branch>` off the back of that same fetch, and that ref is the only
thing that tells a branch parked from another device from a fresh cut (#1139). A narrowed fetch never
brings it into existence, so the swap without the switch would have reopened #1139 -- silently, in a run
where the scaffold, the commit and the push all look correct and only the branch's *work* is missing. So
the scope is the caller's to state, and the suite's parked-branch fixture is what holds it in place.

**What did not change, deliberately.** `new-branch.ps1` still warns and does not refuse. The issue names
that as a separate question and it is not this branch's: the fold refuses because its next act is a commit
directly on the trunk, while a stale base under a branch is recoverable with an ordinary pull, and the
scaffolder is mirrored into every consumer's plugin cache and arrives by plugin update rather than by
choice. That asymmetry may well be correct and permanent; #1416 stays open for it.

Every sentence the script prints is byte-identical, which is what the wording asserts in
`new-branch.tests.ps1` hold. One measurement did move: the gap is now taken on a resume too, since the
count is a local `rev-list` against a ref already on disk. It is not printed there, for the reason it never
was -- on a resume `HEAD` is wherever the operator was standing, so the trunk's gap is not that branch's.

Reason: nothing observable changes for anyone running this script. What it prevents has not happened yet
-- one of the two copies being corrected and the other left behind, which is how the next reader gets two
answers to "how far behind is this checkout" and no way to tell which one their script took.

**Score:** 1

#### What makes this deploy extra special

N/A. A consumer running the mirrored `new-branch.ps1` sees exactly the run they saw before -- same
warning, same count, same two places it is printed, same silence where the question cannot be asked.

**Score:** N/A

#### Pull Request

new-branch reads the trunk gap from Get-TrunkGap instead of measuring it again
