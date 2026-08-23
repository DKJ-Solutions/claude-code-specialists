# Development cycle: `docs/development-cycle-answers-v1` · 20260823-145333

<!--
     The plan for this branch. Every step must be resolved before the PR: open-pr and
     ship-pr both refuse while anything is still "- [ ]", and there is no -Force.

       - [ ] not done yet
       - [x] done
       - [~] dropped -- why it turned out not to be needed

     The dropped mark exists so nobody is pushed into ticking a box for work they did
     not do. It keeps its line and its reason, which is the half worth reading later.

     PLAN / CREATE / TEST / DEPLOY are the arc, not a quota: a phase with nothing
     under it is a statement that this branch had nothing there. The headings are
     invisible to the gate, which reads step marks only.

     DEPLOY takes no steps of its own. It is not a step but the result -- the
     section at the foot of this file, which is the part that travels verbatim into
     CHANGELOG.md at the merge. So a step written for after the merge is refused
     here: what happens after the merge is what DEPLOY describes, not a box to tick.
-->

## PLAN

- [x] Dave read the merged `CONTRIBUTING.md` and found the hole: the page names the development cycle only
      in a footnote, and none of this repo's answers about it landed anywhere.

## CREATE

- [x] `CONTRIBUTING.md`: a section stating what this repo's answers make of the document — the audience
      tier and the headings that follow from it, the version suffix, and which of the shape's rules the
      lint enforces here.
- [x] The seam table gained `Get-ReleaseAudienceTier` and `Get-BranchFileWordingOverrides`.
- [x] `CLAUDE.md` now says WHICH half of the retired page went where, instead of naming both pages.
- [x] The split-entry rule accepts the audience tier's heading as an opener — it became the entry's first
      named section when tier 0 lost its own.

## TEST

- [x] The lint gate is green, which it was not: the entry folded an hour ago was reported as split.

## DEPLOY: `docs/development-cycle-answers-v1`

<!--
     Why the deploy matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --
     everything below that line is discarded. Then Score: 1-5 against the rubric
     new-branch printed when it wrote this file.

     Relative links resolve FROM THE REPO ROOT, not from this directory: this text is
     folded verbatim into CHANGELOG.md at the root. So write scripts/x.ps1, never
     ../../scripts/x.ps1 -- the second reads correctly here and is dead once it lands.
-->

`workflow-davekjohn/CONTRIBUTING.md` now states what this repo's answers make of the development cycle,
which nothing did. The merge that retired `branch/README.md` claimed its answers had moved into this
folder's two pages; only the **file rules** actually arrived, in `CLAUDE.md`. The **seam answers** — the
ones that decide what a contributor here sees in the document — went nowhere, and the seam table did not
even list `Get-ReleaseAudienceTier`, the single most consequential answer for the entry's shape.

The new section says three things a reader cannot derive from the portable half: that the audience tier
is `2`, so the entry asks two questions and both sit at the section level while a repo answering nothing
gets the `#### Tier N` fallback instead; that `new-branch` completes a `-v1` and a bump is typed rather
than guessed; and that the lint holds the document's shape here in three ways a consumer's repo cannot,
which is also why the guidance lives inside the document rather than beside it.

**And the split-entry rule was refusing this repo's own changelog.** Tier 0 lost its heading in that
merge, so an entry's first named section is now `What makes this deploy extra special` — and the gate,
which asks whether an entry starts at its first section, read the freshly folded entry as one that had
been cut in two by a stray heading. That is the **fourth** time a change to the entry's headings has made
correct entries read as split, and the first that was a level move rather than a rename: the three
repairs already recorded above that check all key on names. Found by running the lint on `main` straight
after the fold, which is the only moment it could have been seen.

**Score:** 3

### What makes this deploy extra special
<!--
     Why the deploy matters AT THIS REACH specifically. For tier 2 audiences: the subscriber of a service.
     That reader and nobody else -- what matters only inside this repo is said in the section above.

     If it has no significance at this reach at all, then explain shortly why and insert N/A in Score.
     That reason goes above the Score line too, and one or two lines is the whole of it: N/A is a
     complete answer and the common one.
-->

Nothing here reaches a subscriber of the service. The repaired page is this repo's own answer sheet, and
the lint that was refusing its changelog runs nowhere else — the plugin ships no `scripts/lint/`. The one
part that does travel, the entry's heading shape, was already correct in the payload; what was wrong was
this repo's gate reading it.

**Score:** N/A

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

The development cycle's repo answers land in CONTRIBUTING.md

