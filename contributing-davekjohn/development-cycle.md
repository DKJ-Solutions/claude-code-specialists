## Development cycle: `fix/refresh-body-drops-the-resolves-block-v1` · 20260826-160639

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### What this branch repairs

`open-pr.ps1 -Resolves <n> -RefreshBody` published a PR body with **no closing keyword in it**
([#919](https://github.com/DaveKJohn/claude-code-specialists/issues/919)). Measured on PR #916: before the
run GitHub reported #913 as a closing reference, after it nothing. The run printed its lost-section warning
and exited **0**, so it read as a success.

The two body edits on the existing-PR path are **sequential on one variable**, not independent: the
resolves block was appended first and the refresh below then replaced it. The comment above them claimed
the opposite invariant -- *"Both are computed against the SAME starting body"* -- which is what let the
ordering stand unexamined.

#### Why the refresh reaches that far

This repo's `.github/pull_request_template.md` carries **no headings at all**, and neither does the
reference template the plugin ships. With no heading above the placeholder the description is the body's
**leading section**, and with no heading below it there is no stop -- so the leading section is the whole
body. Both halves are `Update-PrBodySection`'s documented behaviour and both are right on their own. It is
the order that loses the block, which is why the repair is a reorder rather than a new boundary.

### CREATE

- [x] Reorder the two edits on the existing-PR path in `scripts/release/open-pr.ps1`: `-RefreshBody`
      first, `Add-ResolvesBlock` last.
- [x] Compare the append against the body **as it went in** (`$beforeResolves`) rather than against
      `$currentBody` -- from the new position the refresh may already have changed `$newBody`, and the old
      comparison would credit this edit with the refresh's change and announce a closing keyword that was
      never added.
- [x] Rewrite the ordering comment above the block: it stated the wrong invariant, and stating the right
      one is what stops the next reader swapping them back.
- [x] Mirror both to `plugins/workflows/contributing-davekjohn/scripts/release/open-pr.ps1`, held
      byte-identical.
- [~] Treat a lost `### Resolved issues` heading as a **refusal** rather than a warning -- the issue's
      second candidate repair. Dropped: with the reorder the block is restored before
      `Get-LostBodyHeadings` runs, so the warning no longer fires for it at all. A refusal would now guard
      a state that cannot be reached, and the existing warning keeps covering the hand-written sections it
      was written for.

### TEST

- [x] `scripts/tests/pr-issues.tests.ps1` gains a `#919` section: the composition of the two libs, which
      is the seam the defect fell through -- each lib was correct alone.
- [x] Asserted in **both** directions, as this suite does elsewhere: append-then-refresh **loses** the
      closing keyword (pinning the mechanism, so a template that gains a heading makes this section
      re-read itself), refresh-then-append **keeps** it.
- [x] Idempotence asserted alongside it -- a body the refresh did not eat comes back unchanged, and the
      assembled body carries exactly one `Closes #919`.
- [x] A source-order assert reads `open-pr.ps1` and requires the `Add-ResolvesBlock` call to sit **after**
      the `-RefreshBody` block. The composition asserts prove the pattern; this one proves the script uses
      it, which is the half that was wrong. Same precedent as the placeholder coupling in
      `pr-body.tests.ps1`: nothing else can see a re-swap, and it fails silently.
- [x] Suite green: 177 asserts.

### DEPLOY: `fix/refresh-body-drops-the-resolves-block-v1`

`open-pr.ps1` now refreshes the PR description **before** it appends the closing block, instead of after
([#919](https://github.com/DaveKJohn/claude-code-specialists/issues/919)). The two edits on the
existing-PR path run sequentially on one variable, so the second consumed the first: with the block
appended first, `-RefreshBody` replaced it and the run published a body that closes nothing. It printed a
lost-section warning and exited 0, which is why it read as a success -- measured on PR #916, where #913
stopped being a closing reference and was reinstated by hand.

The reason a refresh can reach that far is a **heading-less PR template**, which is what this repo and the
shipped reference both carry: with no heading above the placeholder the description is the body's leading
section, and with no heading below it there is no stop, so the leading section is the whole body. Both
halves are `Update-PrBodySection`'s documented behaviour. Nothing about them changes here.

`Add-ResolvesBlock` is idempotent per issue, so appending **last** is a no-op where the block survived and
restores it where it did not -- no new knowledge of stops or heading levels is needed. The comparison moved
with it: the append is now measured against the body as it went in, so a run that only refreshes no longer
announces a closing keyword it never added. And the lost-section warning stops firing for
`### Resolved issues` on its own, because the block is back before that check runs.

**The guard is the half that makes this stick.** `pr-issues.tests.ps1` gains a `#919` section asserting
the composition in both directions -- append-then-refresh loses the keyword, refresh-then-append keeps it --
plus a source-order assert that reads `open-pr.ps1` and requires the append to sit after the refresh. This
suite exists for the #341-#343 failure, where three PRs repaired issues and left eight of them open; #919
is that same failure reached through the door built to prevent it, and nothing asserted that the block
still arrived.

**Score:** 3

#### What makes this deploy extra special

`open-pr.ps1` ships with the `contributing-davekjohn` workflow, and so does the reference
`pull_request_template.md` -- which carries **no headings**, exactly the shape that makes the description
the whole body. So a consumer running `-Resolves` together with `-RefreshBody` met this on their own PRs,
in the tooling rather than in anything they wrote, and met it silently: the run warns, exits 0, and the
issue simply stays open after the merge. They notice the first time they look for a closed issue and find
it open, which may be long after the merge that should have closed it. Nothing they already do changes,
and no template of theirs needs editing.

**Score:** 3

#### Pull Request

open-pr refreshes the body before it adds the Resolved issues block
