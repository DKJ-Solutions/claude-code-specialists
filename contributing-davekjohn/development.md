## Development: `docs/trim-always-on-path-v1` · 20260828-091134

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

Nolan measured the path at 86,619 B / ~27,762 tokens over four documents. Seven evidence passages move to destinations the documents already name; every decision stays put. Repo-owned documents only -- Chris's persona is plugin payload and is out of scope by Dave's choice.

### CREATE

- [x] Lens `01-01` -- keep the rule and the checklist for *Verify the stand against the repo*; move the three measured briefing modes (29 Jul truncation, 4 Aug `ls-remote`, 19 Aug transcription) to the specialists handbook
- [x] Lens `01-01` -- the inbound bullet already points at `triage-inbound` and then restates all six failures with issue numbers; keep the rule and the pointer, drop the restatement
- [x] `CLAUDE.md` -- the safety-implementation intro: keep which page layers over which and that the plugin wins; move the #886 merge and the removed root `CONTRIBUTING.md` to `CONTRIBUTING.md`
- [x] `CLAUDE.md` -- the three exceptions: keep each bound, exact and checkable; move the histories behind them to the page this document already names as their home
- [x] `CLAUDE.md` -- *the how vs the what*: keep the how/what split; move the *portable*-word repair and the `grep -c` miscount to Tessa's lens
- [x] `CLAUDE.md` -- *source-is-the-default*: keep the rule; drop the 1,700-vs-26,914 measurement, which the handbook it points at already carries
- [x] `SPECIALISTS.md` -- keep that every shipped specialist is listed and that adoption needs no approval; move the `Get-RosterIgnoredIds` history to the handbook
- [x] Re-measure with `measure-always-on.ps1` and record the before/after in DEPLOY

### TEST

- [x] `check-plugin-integrity.ps1` green -- every relocated passage leaves a live link behind
- [x] Every moved paragraph reads at its destination without the sentence that used to precede it

### DEPLOY: `docs/trim-always-on-path-v1`

Every session paid 27,762 tokens of instruction documents before its first assignment. It now pays
25,195 -- **2,567 fewer, 9.2%**, across `CLAUDE.md`, `SPECIALISTS.md` and Chris's lens.

Nothing was decided differently. Eight passages of *evidence* moved to destinations those documents
already named, under the rule the repo states itself: the decision belongs on the always-on path, the
measurement behind it does not. Two of the eight turned out to be neither evidence nor decision but
**duplication** -- the `contributing-davekjohn/CONTRIBUTING.md` layering history and the
1,700-vs-26,914 lens measurement were already written out in full at the pages `CLAUDE.md` was pointing
at -- so those were deleted rather than moved. Every bound on the three direct-on-`main` exceptions is
still stated here, verbatim and checkable; what left them is their history.

The evidence has three new homes, each of which is read on demand and costs a session nothing until it
is opened: a `## Measured instances kept off the always-on path` section in the specialists handbook
(the three ways a briefing fails, why `Get-RosterIgnoredIds` is empty, why the branch check fires on
the follow-up assignment), a section in Tessa's lens for the *portable*-word repair and the `grep -c`
miscount that came with it, and inbound #388 in the `triage-inbound` skill, beside the five other ways
a report fails on pickup.

Chris's persona carries another 35% of the path and was deliberately left alone: it is plugin payload
that ships to every consumer, and trimming it is a release-bound change rather than a repo-local one.

**Score:** 3

#### What makes this deploy extra special

N/A -- every file touched is repo-owned. Nothing here ships in a plugin, so no consumer sees a
difference.

**Score:** N/A

#### Pull Request

Move the measured evidence off the always-on document path
