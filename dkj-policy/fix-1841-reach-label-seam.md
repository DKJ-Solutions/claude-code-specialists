## fix/1841-reach-label-seam

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

#### What the inbound report asked for, and what verification found

[#1841](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1841), filed from
`BWJ-Development/smartwatchbanden`: that repo renamed its reach label from `tier-1` to `minor` on
September 11, 2026, and `dkj-policy-bwj` wrote that name as a literal. Verified against this tree
before routing -- all six axes stand:

- **Symptom** -- the four call sites are in the source, not only in the installed copy.
- **Reason** -- `adopt-dkj-policy-bwj` step 4 checks `grep -E '^(tier-1|documentation)\b'` and then
  `gh label create tier-1`, so a re-adopt makes a second, empty label for one axis, silently.
- **Repair** -- a seam in `scripts/repo-config.ps1` is the shape this plugin already uses, and
  `Get-AsanaStageMap`'s `NeedsInfoLabel` is the precedent for a LABEL NAME living in one.
- **Size** -- narrower than it first reads. Most `tier-1` in `plugins/dkj-policy/` belongs to the
  release TIER MODEL and is untouched; inside `dkj-policy-bwj` only the commands change.
- **Subject and repo** -- the files exist here, and the consumer's own tree hard-codes the name
  nowhere, which the report measured and this branch did not need to re-measure.

#### The intent behind the guardrail, read before touching it

[#1201](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1201) is where the label came from:
135 issues classified by hand, and the label exists to keep `is:open label:<reach>` a short list
somebody can work. A seam for the NAME leaves that intact -- it changes which string is typed, not
which issues carry it.

### CREATE

- [x] `skills/report-issue/SKILL.md` -- the frontmatter description, a `Get-ReachLabel` line in
      *Before you start*, the filing command, the decision table's row, and both after-the-fact
      `gh issue edit` lines
- [x] `skills/adopt-dkj-policy-bwj/SKILL.md` step 2 -- propose `Get-ReachLabel` beside the Asana
      answers, with the reason it is the odd one out and the rule to propose it only where the
      repo's label is NOT the default
- [x] `skills/adopt-dkj-policy-bwj/SKILL.md` step 4 -- check and create the CONFIGURED name, and
      pause before creating: read the whole label list first, because a missing reach label means
      either "never had one" or "renamed it", and only the first is safe to add
- [x] `WORKFLOW-portable.md` -- the classification table, the section heading, the worklist query
      and the add-label line; the axis keeps its own name in the explanatory prose, which is the
      distinction the report itself drew
- [x] `README.md` -- the chapter-one paragraph and a `Get-ReachLabel` entry in the seam list
- [x] The retired-owner URL beside the edit in `WORKFLOW-portable.md` corrected to
      `DKJ-Solutions/dkj-claude-plugins` -- the correct-on-edit rule, not a sweep

### TEST

- [x] `scripts/tests/dkj-policy-bwj.tests.ps1` -- a guard that refuses the literal in the two
      operational shapes (`--label tier-1`, `gh label create tier-1`) and in the search query, plus
      asserts that the seam is named in all four documents and defaults to `tier-1`
- [x] Suite green: 234 asserts
- [x] The new asserts verified to BITE -- each of the four original call-site strings matched,
      so the guard is not passing on absence of a pattern nothing could produce

### DEPLOY: fix/1841-reach-label-seam

`dkj-policy-bwj` no longer writes the reach label's name as a literal. The string GitHub stores comes
from `Get-ReachLabel` in the consumer's own `scripts/repo-config.ps1`, defaulting to `tier-1`, so
every existing consumer is unchanged and silent; the reach axis itself keeps its own name in the prose
that explains it, because what a consumer renames is a row in their label settings, not the model. The
filing command, the decision table, both after-the-fact `gh issue edit` lines, the worklist query and
`adopt-dkj-policy-bwj`'s existence check and `gh label create` all read the seam. Step 4 also stops
before creating: a missing reach label means either that the repo never had one or that it renamed it,
and only the first is safe to add -- creating it in the second case leaves two labels for one axis,
one of them empty, with nothing reporting it. A guard in `dkj-policy-bwj.tests.ps1` refuses the
literal in the command shapes if it is ever written back.

**Score:** 2

#### What makes this deploy extra special

`BWJ-Development/smartwatchbanden` renamed its reach label to `minor` on September 11, 2026 and
`report-issue` has been failing outright there since -- `gh issue create` errors on a label the repo
does not have. Answering `Get-ReachLabel` with `'minor'` is now the whole fix on their side, and the
next `adopt-dkj-policy-bwj` run no longer quietly re-creates `tier-1` beside the label that carries all
24 of their issues.

**Score:** 4

#### Pull Request

A seam for the reach label's name, so a consumer that renames it keeps report-issue working
