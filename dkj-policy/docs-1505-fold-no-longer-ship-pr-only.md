## docs/1505-fold-no-longer-ship-pr-only

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

CLAUDE.md:293 still said the fold runs from `ship-pr.ps1` **only**, and framed the miss it causes as a
PR "merged from the GitHub UI". Both halves went stale on September 6, 2026, when
`.github/workflows/fold-on-merge.yml` landed under #1493 (PR #1496) and the merge queue went live under
#1492. This branch corrects the statement to what is true and adds no policy.

#### Why this branch exists at all, and why it is not #1505's own repair

#1505 asks for a session-independent home for the fold and lists three candidates. That question was
already decided and built under **#1493**, which is still open and assigned to Dave: `fold-on-merge.yml`
is candidate 1, verbatim. #1505's acceptance criteria are #1493's, so it is a duplicate and is closed as
one. Verified before any work started, live:

- `gh api .../rulesets/19008062 --jq .bypass_actors` -> `OrganizationAdmin` + `RepositoryRole 5` only.
  The GitHub Actions app (`integration_id 15368`) is **absent**, which is #1493's single remaining
  blocker and a repo-settings change reserved to Dave.
- Run `34024187136` (the #1504 merge push): the fold itself **succeeded** -- `Folded and removed:
  dkj-policy/fix-1500-stale-check-citations.md`, `Committed: fold: ...` -- and only the push was
  rejected, `GH013`, naming both `required_status_checks` and `merge_queue`.
- `git log` confirms today's `fold:` commits are still human-authored (`613dd8f6`, `dd7f2627`,
  `653d69a0`), i.e. the bot has never landed one.

So the only part of #1505 with nothing standing behind it was the documentation half, and that is this
branch. The policy half it also raises -- whether a bot may make the fold commit under the bounded
direct-on-`main` exception -- was deliberately **not** answered here (Dave's call, this session): adding
an actor to a bounded exception is a constitutional change, not a fact to record.

### CREATE

- [x] `CLAUDE.md`: replace the "runs from `ship-pr.ps1` only" claim with what actually runs -- the
      shipping session's step, the two merges it never observes (GitHub UI, and the queue since #1492),
      and `fold-on-merge.yml` as the second runner since #1493, named as code-complete but inert while
      `main-ci-gate` does not bypass the GitHub Actions app.
- [x] `scripts/lib/shared-scripts-lib.ps1`: the `check-unfolded-entry` registry comment carried the same
      stale sentence; corrected in place, ASCII-only per the script-layer rule.
- [~] Recording the bot as a sanctioned actor under the fold exception -- dropped: Dave chose the
      fact-only repair, and this is a policy grant that is his to make.
- [~] Repairing the fold gap itself -- dropped: already built under #1493 and blocked on a ruleset
      change this branch cannot and must not make.

### TEST

- [x] Verified the corrected lens citation still resolves: the fold-on-merge red-run diagnosis sits at
      `05-15-extension.md:171`, inside `### What Sylvester owns here` (lines 16-839), so the existing
      `#what-sylvester-owns-here` anchor is correct and was not left pointing past its section.
- [x] Swept the tree for the same stale claim elsewhere: `grep` over `*.md` and `*.ps1` returns only the
      two files changed here.
- [x] Lint gate + all test suites, via `open-pr.ps1`.

### DEPLOY: docs/1505-fold-no-longer-ship-pr-only

`CLAUDE.md` said the changelog fold runs from `ship-pr.ps1` only. It has not since September 6, 2026:
`fold-on-merge.yml` runs it from a `push` to `main` as well (#1493), which is what makes the fold
survive a merge the shipping session never sees -- the GitHub UI, and the merge queue since #1492. The
always-on text now says both, and says plainly that the second runner is code-complete but inert while
`main-ci-gate` does not bypass the GitHub Actions app: its fold succeeds and its *push* is rejected, so
a red run there is not evidence of a refused fold. The same stale sentence is corrected in the
`check-unfolded-entry` registry comment in `shared-scripts-lib.ps1`.

**Score:** 3

#### What makes this deploy extra special

N/A -- `CLAUDE.md` is this repo's own always-on constitution and ships to no consumer, and the
registry comment is an internal script comment. No subscriber of the plugins reads either.

**Score:** N/A

#### Pull Request

The fold no longer runs from ship-pr.ps1 alone
