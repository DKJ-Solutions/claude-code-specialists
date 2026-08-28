## Development: `fix/skill-page-promises-a-version-scan-v1` · 20260828-231831

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

Inbound [#1049](https://github.com/DaveKJohn/claude-code-specialists/issues/1049): the `new-branch`
skill page describes the version suffix as a scan for the lowest free number, checked locally and on
the remote. The script does the opposite and says so in capitals
(`scripts/task/new-branch.ps1:220`), and the code behind it is three lines with no `git branch` and no
`ls-remote` in them.

Verified before routing: grepped the tree for `lowest free` outside `releases/` -- four statements
agree with the code (`new-branch.ps1:220` and its mirror, `DEVELOPMENT-portable.md:68`,
`05-05-extension.md:63`) and only `skills/new-branch/SKILL.md:36` disagrees. So the page is the
outlier and the repair is the page.

#### The second defect on the same lines, repaired with it

That sentence also sat inside the bullet describing `Test-BranchName`, attributing the completion to
the validator. It is deliberately *not* there -- `branch-info.ps1` is repo-owned and does not travel,
and a hard refusal would break every branch in flight -- and the completion runs *after* validation,
which is what keeps `-Name main` from becoming `main-v1`. Leaving the misattribution while correcting
the scan claim would have left half a false statement, so the suffix is now a step of its own.

### CREATE

- [x] `plugins/workflows/contributing-davekjohn/skills/new-branch/SKILL.md`: replace the scan claim
      with what the script does -- appends `-v1` and nothing else, an explicit `-vN` left as typed --
      and state the consequence the right way round: a second run *resumes* the branch, which is what
      `-Park` relies on.
- [x] Lift the suffix out of the `Test-BranchName` bullet into its own numbered step, after
      validation, and renumber the three below it.
- [x] Point the reader at `DEVELOPMENT-portable.md#the-version-suffix` for the full reasoning, using
      the relative form the page already uses at line 190, rather than restating it here.

### TEST

- [x] Grepped the page for every other mention of `suffix`, `-v1` and `-v2`: no second copy of the
      claim.
- [x] Anchor target verified -- `### The version suffix` exists in `DEVELOPMENT-portable.md`.
- [x] `check-plugin-integrity.ps1` + the full suite via `open-pr.ps1` (dead-link scan covers the new
      relative link).

No script changed, so no suite gained an assert. The behaviour this page now describes is already
asserted in `scripts/tests/new-branch.tests.ps1` -- "HEAD stays on the same branch after the second
run" -- which is the test the old sentence contradicted.

### DEPLOY: `fix/skill-page-promises-a-version-scan-v1`

The `new-branch` skill page said the script completes a missing version suffix by scanning for the
lowest free number, "checked against the branches that exist locally and on the remote". It does not,
and it has never claimed to: `new-branch.ps1` appends `-v1` and nothing else, in three lines with no
`git branch` and no `ls-remote` anywhere near them, under a comment block explaining in capitals why
the scan is deliberately absent. Four other statements in the tree already said so; this page was the
lone outlier.

Both halves of the sentence misled. It promised a remote read that does not happen, and its stated
consequence -- "a second cycle on the same subject becomes `-v2` rather than colliding" -- was the
reverse of the asserted behaviour: a second run on the same name *resumes* the `-v1` branch, which is
the idempotence the `-Park` flow is built on and what `new-branch.tests.ps1` pins directly.

The same lines carried a second, quieter error: the completion was described inside the bullet about
`Test-BranchName`, and it deliberately does not live there. It is now a step of its own, placed where
it actually runs -- after validation, which is what stops `-Name main` from becoming `main-v1` -- with
the reasoning left to `DEVELOPMENT-portable.md` instead of restated.

**Score:** 2

#### What makes this deploy extra special

A consumer has the plugin mirror and this page, not the source tree, so for them the false statement
was the only statement -- the four correct ones live in files they never see. And the specific thing
it promised, a check against what exists on `origin`, is the class of gap
[#1046](https://github.com/DaveKJohn/claude-code-specialists/issues/1046) was filed about days ago: a
reader would have had every reason to believe `new-branch` already reached the remote for them.
Worse, acting on the stated consequence means expecting a fresh `-v2` where the script hands back the
branch you were already on.

**Score:** 3

#### Pull Request

new-branch skill page promises a version-suffix scan the script refuses to do
