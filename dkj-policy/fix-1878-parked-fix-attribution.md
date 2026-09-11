## fix/1878-parked-fix-attribution

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

Print the author and the age of every parked-fix commit, and say so as a refusal-shaped verdict when the newest one is by an account other than the one being claimed for.

### CREATE

- [x] `ConvertFrom-CommitScanLog` reads four fields (`%H%x1f%an%x1f%at%x1f%s`), with the epoch
      validated as digits so a shifted line reports an age it declines to state rather than a wrong one.
- [x] `Format-CommitAge` -- one coarse unit, `just now` at both ends of the range.
- [x] `Test-SelfAuthored` -- the comparison is against the git AUTHOR name, with the claiming login
      accepted as well; no names configured means no verdict.
- [x] `Get-ForeignParkedCommit` -- the newest scanned commit this checkout did not write. Its own
      function because two callers ask it, and scraping it back out of printed prose is how they drift.
- [x] `Format-ParkedFixReport` prints sha, WHO, WHEN, then the subject, and closes with the
      refusal-shaped `NOT YOURS` block when there is one.
- [x] `claim-issue.ps1` asks git for the two fields, sanitises the author name like the other two
      pushed fields, and its closing verdict no longer says "the work starts here" over the top of it --
      on a fresh claim and on a resume.
- [x] The skill page carries the new output, the comparison rule, and why the verdict refuses nothing.
- [x] Plugin mirrors rebuilt (`build-shared-scripts.ps1`).

### TEST

- [x] `claim-issue.tests.ps1` -- 193 passed, 0 failed. New coverage: the four-field parse and its
      shifted-line case, every unit of `Format-CommitAge` including a commit dated in the future, the
      display-name checkout that must recognise its own commits, the verdict and its absence, an
      unreadable date, a pre-#1878 record, and the three script-shape properties that are otherwise a
      silence (the log format, the self names, the closing line reading the flag).
- [x] `check-plugin-integrity.ps1` -- 0 errors.
- [x] Rendered against the real commit on this branch, with a foreign self name, to see the block a
      reader actually gets.

### DEPLOY: fix/1878-parked-fix-attribution

The parked-fix scan now names WHO parked each commit and HOW LONG AGO, ahead of the subject, and says
so as a verdict where the newest one is not this checkout's own.

The scan landed on September 11, 2026 and was defeated the next day by the one commit shape a parked
branch always has. A session claimed #1874, was told there was one commit on one branch off the trunk,
read it exactly as the warning instructs, found a `park:` scaffold touching only the branch document,
and carried on -- while its author was three minutes in and twenty minutes from opening their pull
request. A park commit is empty by design, so content is the one thing that cannot report a collision.
Both facts that would have stopped it were one git format field away and neither was asked for.

The verdict is refusal-shaped and refuses nothing, which is the precision of the measurement rather
than a hedge: the scan matches any commit *naming* the issue, and a colleague mentioning one is
ordinary. What it does change is the closing line, because a run that says ASK THEM BEFORE YOU WRITE
ANYTHING and then THE WORK STARTS HERE has settled nothing.

**Score:** 4

#### What makes this deploy extra special

The claim step ships in `dkj-policy`, so every consumer running this workflow gets the attribution and
the verdict at the moment a session picks up an issue -- the one moment duplicate work can still be
prevented for free. A reader who has ever dismissed a parked branch on its contents is the audience.

**Score:** 3

#### Pull Request

claim-issue: the parked-fix scan names who parked a commit and how long ago

