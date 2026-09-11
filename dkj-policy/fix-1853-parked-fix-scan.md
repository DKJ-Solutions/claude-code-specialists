## fix/1853-parked-fix-scan

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Give `claim-issue.ps1` the one pickup signal none of the existing checks can carry: a fix that is
finished, committed and **pushed on a branch with no pull request**. The issue's state, its
assignees, and `Get-TargetIssueWarnings` all read exactly the same whether the work is untouched or
already done and parked, because that last one resolves an issue to a **PR** and a parked branch has
none. The commit message is where a parked fix announces itself and the only place it does.

#### Verified before it was built

The report's symptom, reason and proposed repair were all held against the tree first:

- `claim-issue.ps1` made **no git calls at all** -- confirmed by reading it. So there was nothing to
  extend; the read is new.
- `Get-TargetIssueWarnings` (`scripts/lib/pr-issues-lib.ps1`) takes `-OtherPrsJson` from
  `gh pr list` and reports `ClaimingPrs`. It is PR-shaped, exactly as the report says, so #1409's
  repair -- already built, in `new-branch.ps1`'s `-Resolves` block -- does not reach this case.
- The cited commit `f686b0af` does carry `(#1847,` in its body. It is now an **ancestor of `main`**,
  so the scan correctly reports nothing for #1847 today: that branch merged after the report was
  filed, which is the check working rather than a gap.

#### Where it went, and why not `new-branch`

In `claim-issue.ps1`, which is the argument the issue makes for itself: it is the moment the session
has spent nothing. The cost the issue weighed against that -- a `git fetch` -- is one bounded,
best-effort call, and it is `fetch --quiet` rather than `--all`, so a checkout with three remotes
does not pay for two of them here. It runs **only** where the verdict is `claim` or `skip`, so the
two refusals below it pay nothing for an answer they would not use.

`new-branch` was left alone deliberately. Its `-Resolves` block already runs the PR-shaped check, and
by the time it runs the claim has warned; a second copy of the same finding one step later is noise,
not a second chance.

### CREATE

- [x] `scripts/lib/claim-issue-lib.ps1` -- four pure functions: `Get-IssueMentionPattern` (the three
      spellings), `ConvertFrom-CommitScanLog`, `Get-ContainingBranchNames`, `Format-ParkedFixReport`.
- [x] `scripts/task/claim-issue.ps1` -- the git half: the trunk-ref probe, the bounded fetch, the log,
      the `branch -a --contains` per match, and the report. Plus `Get-TrunkBranchName` read from the
      same optional seam block that already reads `Get-RepoName`.
- [x] `plugins/dkj-policy/skills/claim-issue/SKILL.md` -- the consumer-facing section, the worked
      output, and `git` added to the requirements.
- [x] Mirrors regenerated (`scripts/sync/build-shared-scripts.ps1`).

#### Three things the pattern had to get right

1. **Three spellings, not one.** #1853 proposed `--grep='#<n>\b'`. Hash-only would have missed the
   commit it was measured against: `fix(1842): apply the parallel review findings` puts the number in
   the **conventional-commit scope**, and a branch cut for an issue writes that scope on every commit.
   The third is `/1853-`, the branch name inside a subject -- the only shape a **freshly parked**
   branch has, since `new-branch`'s own creation commit is `park: fix/1853-x (the branch files only)`.
2. **`\b` is not portable.** git's grep engines are POSIX, where `\b` is a GNU extension. The trailing
   `([^0-9]|$)` does the same job and keeps `#18530` out.
3. **No trunk ref, no scan.** `git log --all` with nothing subtracted reports the issue's own merged
   repair back at the reader, which is the noise that teaches them to skip the warning.

### TEST

- [x] `scripts/tests/claim-issue.tests.ps1` -- 55 new asserts, 68 -> 123: the pattern's three positives and four
      negatives, both parses against the shapes git actually emits (missing separator, empty sha, a
      subject holding pipes/tabs/colons **and a second separator**, CRLF), the branch cleaner's five
      drops and its case-sensitive exclusion, the report's grouping, counting, cap and overflow, and
      five structural asserts on the scan block itself -- that it is gated on the verdict, that
      nothing in it exits, and that the fetch is bounded.
- [x] Full gate: `check-plugin-integrity.ps1` -- **0 errors**. All suites green.
- [x] Exercised live, which is the half a suite cannot reach: `claim-issue.ps1 1853 -DryRun` on this
      branch prints **nothing**, which is correct (the only commits naming 1853 are this branch's own
      and are excluded); the same pipeline run against `#1852` reports its real parked branch
      `origin/fix/1852-timeout-decisive-in-sessioncheck` with both its commits.

#### One existing assert had to be repaired, and it was arguing for the defect

`claim-issue.tests.ps1` held *"every gh call carries the shared bound"* as a **whole-file count** of
the bound compared with a whole-file count of the gh calls. That was exact only while `gh` was the
only bounded caller in the script, and the bounded `git fetch` broke it -- so the suite failed on a
script where every gh call was in fact bounded. It now reads each gh invocation on its own, delimited
by backtick continuation. Checked in both directions: `main`'s copy of the suite, run against this
branch's script, fails on exactly that one assert (67 passed, 1 failed) -- so the repair was necessary
rather than cosmetic; and a mutation dropping the bound from one gh call is still caught by the new
one.

#### Two Windows PowerShell 5.1 traps met while building it

Both produced well-formed wrong behaviour rather than an obvious error, so both are written down at
the line they bit:

- `@()` over a `List[object]` throws `ArgumentException` -- and reports the fault at the `return`
  line, not at the construction. `List[psobject]` and `List[string]` are fine, which is why the three
  sibling functions in the same file never met it.
- `String.Split(@($sep), 2, ...)` binds to no overload: `@()` builds an `Object[]` and the overload
  needs `String[]`. Same symptom, same misattributed line.

### DEPLOY: fix/1853-parked-fix-scan

`claim-issue` now reads the **branches** as well as the tracker. Before this, all three signals a
session has when it picks up an issue -- the issue's state, its assignees, and any pull request
resolving it -- read exactly the same whether the work was untouched or already finished and pushed
on a **parked** branch, because the PR-shaped check has nothing to find when there is no PR. Measured
September 11, 2026 ([#1853](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1853)): #1847
was claimed correctly, read, repaired and committed, and only `open-pr`'s remote-ahead gate revealed
that the identical fix was already sitting on `origin/feat/1842-unify-prio-labels-bwj` and said so in
its own commit message. The claim step now scans the commit messages off the trunk for the issue
number -- in the three spellings this workflow writes: `#1853`, the commit scope `fix(1853):`, and
the branch name `/1853-` that a freshly parked branch carries -- and names the branch and the commits
it found, grouped by branch and capped so a long branch cannot bury the rest of the output. It
**warns and never refuses**: an issue can be legitimately named by a commit that does not fix it, and
a claim that blocks costs the whole assignment. It runs on a resume as well as a fresh claim, and it
is silent about the session's own branch and about the trunk.

**Score:** 3

#### What makes this deploy extra special

N/A. The audience here is whoever picks up an issue in a repo running this workflow -- a developer,
never a subscriber of any service either consumer repo sells. What it saves them is the work between
a claim and the first gate that would have noticed: in the measured instance, one file read, one line
edited, one lint run and one commit, all discarded. That cost scales with how long the fixing branch
stays parked without a PR, which can be indefinite.

**Score:** N/A

#### Pull Request

claim-issue reads the branches for a fix already pushed without a PR

Plugins: dkj-policy

Closes #1853
