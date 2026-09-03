## Development: `docs/carry-1255-rename-into-portable-pages-v1` · 20260903-102059

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

Issue #1273. Six spots verified stale: new-branch/SKILL.md:176, CONTRIBUTING-portable.md:102 and :771, lenses/05-06-extension.md:75, plugin scripts/README.md:57, and scripts/tests/fold-changelog.tests.ps1:725+730 (the last two found by sweep, not listed in the issue).

#### The two spots the issue did not list

A sweep for the retired argument -- `fixed name`, `fixed path`, `cannot collide`, `filling up with other
people` and every bare `development.md` -- found two more beyond the four #1273 tabled, and both are the
same defect rather than a widening of scope:

| file · line | what it said |
|---|---|
| `plugins/workflows/contributing-davekjohn/scripts/README.md:57` | `new-branch.ps1` *"writes its `contributing-davekjohn/development.md`"* -- a path the script no longer writes. Payload, and this repo's root `scripts/README.md` already carries the per-branch form, so the two pages disagreed |
| `scripts/tests/fold-changelog.tests.ps1:725, 730-731` | *"folded from the fixed path"*, and *"What the fixed path still buys is unchanged -- two branches in flight cannot collide"* -- the retired argument stated as still current, three lines above a comment recording the August 23 reversal |

Three more hits were read and left alone, because each is already correct: `entry-scaffold-lib.ps1:4796`
and `DEVELOPMENT-portable.md:524` record the argument **as expired** (which is the point of writing it
down), and `CLAUDE.md:303` and `contributing-davekjohn/CONTRIBUTING.md:200` were both updated when #1255
landed.

### CREATE

- [x] `skills/new-branch/SKILL.md` -- replace the fixed-name paragraph with the per-branch name, the
      checkout-versus-merge distinction, and a link to `DEVELOPMENT-portable.md`'s measurement
- [x] `CONTRIBUTING-portable.md:102` -- the same paragraph, in that page's shorter register
- [x] `CONTRIBUTING-portable.md:771` -- ``every gate reads your branch's own `development-<branch>.md` ``
- [x] `.claude/specialists/lenses/05-06-extension.md` -- the release lens's copy of the claim
- [x] `plugins/workflows/contributing-davekjohn/scripts/README.md:57` -- the stale path
- [x] `scripts/tests/fold-changelog.tests.ps1` -- the Write-Host label and the comment that said the fixed
      path still bought non-collision

### TEST

- [x] Re-ran the sweep after the edits. Every surviving hit is one of three things and none is a finding:
      a different subject (`unprefixed name`, in the branch-taxonomy lens and `plugins/teams/README.md`), a
      deliberate record of the argument **as expired** (`DEVELOPMENT-portable.md:524`, `CLAUDE.md:303`,
      `skills/fold-changelog/SKILL.md:31`), or this branch's own prose saying the same
- [x] Checked the two link targets the edits introduce. `DEVELOPMENT-portable.md`'s
      `## Why the name carries the branch` heading exists, so the anchor resolves from both pages that
      now cite it, and the lens's `../../../plugins/...` is exactly three levels up to the repo root
- [~] No suite or fixture changed behaviour, so nothing was added to the test tree. The one test file
      touched is a **comment** in `fold-changelog.tests.ps1`; its asserts are untouched, and the lint and
      test gates `open-pr` runs are what prove that rather than a step here

### DEPLOY: `docs/carry-1255-rename-into-portable-pages-v1`

The #1255 rename -- one branch document per branch, `development-<branch>.md` -- is carried into the six
places that still taught the retired argument it replaced. Four are shipped payload
(`skills/new-branch/SKILL.md`, `CONTRIBUTING-portable.md` twice, `scripts/README.md`), and two are read
only here (the release lens, and a comment in `fold-changelog.tests.ps1`). Each now names the reversal,
dates it, and separates *checkout* from *merge* -- which is the part that matters, because the sentence
they carried was not merely stale: it was the reasoning #1255 disproved, offered as current.

Nothing executable changed. The paths and the code blocks on these pages were already per-branch when
#1255 landed; what was missed was the paragraph explaining why, which is why no gate caught it.

**Score:** 3

#### What makes this deploy extra special

`skills/new-branch/SKILL.md` is the page a consumer's session reads **immediately before creating a
branch** -- it is the skill body, so it lands in context at the exact moment the reader is about to act on
it, and it stated a fixed filename while the script it documents writes one per branch. A consumer who
followed its reasoning learned the argument that produced the defect: that the document cannot collide
because git tracks it per branch. That holds for checkout and says nothing about merge, where every merge
to the trunk left every other open pull request conflicting on one path -- and a conflicting PR gets no
check suite at all, so it can never go green and can never merge. Consumers now get the reversal, dated,
with a link to the measurement behind it.

**Score:** 3

#### Pull Request

Carry the #1255 per-branch rename into the six pages that still teach the retired fixed-name argument

