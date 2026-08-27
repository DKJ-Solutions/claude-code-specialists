## Development cycle: `docs/portable-contributing-floor-v1` · 20260827-161545

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

#### Where this branch comes from

Two items that outlived [#969](https://github.com/DaveKJohn/claude-code-specialists/issues/969). That
branch dropped the root `CONTRIBUTING.md`, opened at 09:39 UTC on August 27, 2026 and never merged:
`claude-review` died 34 seconds later on a 429 session limit, and the session that would have merged and
folded went with it. By the time anybody looked, #980 had done the same job from the other end -- it
deleted the root page itself and moved `CHANGELOG.md` and the release history into this folder -- leaving
#969 conflicting in nine files. It is closed with the reasoning in a comment; three of its five parts had
landed, one had been refuted on `main` (taking `CONTRIBUTING.md` off `Get-ReservedRootMd` breaks the
portable cut, which that list's own comment now records), and these two had reached nobody.

Both are **payload**. Nothing about this repo's own layout changes here -- that already happened in #980.

### CREATE

- [x] `CONTRIBUTING-portable.md`: the "two contributing pages" section becomes two **layers**, because
      which file carries the floor is the consumer's answer rather than a fixed path. Names the source's
      own exception as housekeeping, and keeps the root page as the recommendation with the two reasons no
      gate can express.
- [x] `adopt-workflow-folder.ps1` (both copies -- `scripts/task/` and the plugin's): the refusal stops
      claiming the source keeps `CONTRIBUTING.md` and `releases/` at its root. Since #980 both halves are
      false, and the refusal's real ground is that a source arranges that folder by hand.

#### Three more places said it, and only one was in the branch's brief

The refusal was the item on the list. Grepping the payload for the same claim found it three more times,
all in text `adopt-workflow-folder` owns or is read beside: the skill page repeated the refusal verbatim,
the scaffold's own layout diagram still told a consumer the release list sits at their repo root, and
`check-script-contract.ps1`'s comment explained an existence-only check by saying the source keeps its
docs at the root. All four are now one statement, and the two mirrored scripts stay byte-identical.
Only `check-script-contract.ps1` is a different command, and it is the same sentence.

**Not repaired here, filed as #989 instead:** `Get-DefaultReleaseHistoryPath`'s docstring in `seam-lib.ps1` still
says the source "still keeps its root file". That one is a question about whether the computed default is
still right for a source that now declares the seam, not a sentence to rewrite.

### TEST

- [x] `check-plugin-integrity.ps1` + the suites, via `open-pr`. The two script copies must stay
      byte-identical, which that gate checks.

### DEPLOY: `docs/portable-contributing-floor-v1`

Payload only: the portable contributing page and the folder scaffolder. Nothing about this repo's own
layout moves -- #980 did that on August 27, 2026, and this is the half of #969 that #980 did not carry.
#969 itself is closed rather than rebased; the comment on it holds the forensics, including the 429
session limit that stopped it 34 seconds after it opened and the one hunk of it that `main` has since
refuted.

**Score:** 2

#### What makes this deploy extra special

**`CONTRIBUTING-portable.md` stops naming a path where it means a role.** It described "two contributing
pages", the root one being the floor -- so a consumer who keeps that floor somewhere else was reading a
page that had no room for their answer. It now describes two **layers**: a floor, normally your root
`CONTRIBUTING.md`, and the workflow's own page that wins on conflict. Nothing about the workflow depends
on which file carries the floor, because every gate reads the branch's `development-cycle.md` and never a
contributing page, and the page now says so.

**The root page is still the recommendation, and it now says why in terms no gate can express.** GitHub
links a root `CONTRIBUTING.md` from the new-issue and new-pull-request pages and from the sidebar, and it
recognises that file only in the root, `.github/` or `docs/`; and it is the name a drive-by contributor
looks for. Both reasons matter most in a public repo whose contributors have installed nothing, which is
the reader the floor exists for. The source's own August 27, 2026 decision to delete its root page is
recorded there as housekeeping rather than as the model -- which is the honest shape, since a consumer
inheriting the source's answer by imitation would lose both of those for nothing.

**And the scaffolder stops describing a source that moved.** Its refusal in a plugin-publishing repo said
the source keeps its `CONTRIBUTING.md` and `releases/` at its root; since #980 neither half is true, and
the refusal's real ground -- a source arranges that folder by hand -- was never the part that could go
stale. A consumer who read the old text and copied the source's layout was copying a root that no longer
exists.

**Score:** 3

#### Pull Request

the portable contributing page states which file carries the floor, and the folder scaffolder stops claiming a root that moved
