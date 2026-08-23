# Development cycle: `feat/development-cycle-v1` · 20260823-122016

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

- [x] Four course-defining questions answered by Dave: the fold takes the DEPLOY section verbatim, the
      explanatory prose leaves this document, `templates/` is retired, and every older file name stays
      readable.
- [x] The `-vN` suffix: advised as a completion in `new-branch` rather than a refusal in
      `Test-BranchName`, because a validator can only see the shape and this branch's own name is the
      first thing it had to complete.

## CREATE

- [x] `entry-scaffold-lib.ps1`: one path seam, one formatter, `Split-DevelopmentCycle`, tier 0 without a
      heading of its own, the audience tier at H3, the merge stamp on the entry heading, and the
      title-first heading shape.
- [x] `Get-EntryTierSubLevel` — the level a tier sub-heading is WRITTEN at depends on the shape, so a
      repo that has stated no audience tier keeps the document it had yesterday.
- [x] `new-branch.ps1`, `fold-changelog-entry.ps1`, `open-pr.ps1`, `check-branch-entry.ps1`,
      `adopt-workflow-folder.ps1`: one document instead of two.
- [x] `check-plugin-integrity.ps1`: the reset state held to the formatter, the entry-heading check
      reading the DEPLOY section with its line offset, and three path exclusions narrowed from the
      workflow folder back to the one document.
- [x] The docs: `DEVELOPMENT-CYCLE-portable.md` (rewritten and renamed), this folder's three pages, the
      root `CLAUDE.md`, `INSTALL.md`, six skills, both PR templates, `CHANGELOG.md`'s intro, and three
      specialist lenses.
- [x] Regenerate the plugin mirrors and the config blueprint.

## TEST

- [x] The suites pass, with six of them rewritten for one document.
- [x] The lint gate is green.
- [~] A migration script for branches in flight — dropped: the resolver reads whichever file NAMES the
      branch, so an open branch keeps working without one, and writing a migration nobody has to run is
      the pre-emptive fix this repo declines.

## DEPLOY: `feat/development-cycle-v1`

<!--
     Why the deploy matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --
     everything below that line is discarded. Then Score: 1-5 against the rubric
     new-branch printed when it wrote this file.

     Relative links resolve FROM THE REPO ROOT, not from this directory: this text is
     folded verbatim into CHANGELOG.md at the root. So write scripts/x.ps1, never
     ../../scripts/x.ps1 -- the second reads correctly here and is dead once it lands.
-->

A branch carries one document again. `workflow-davekjohn/branch/` is gone, and everything a branch needs
is `workflow-davekjohn/development-cycle.md`: `## PLAN` / `## CREATE` / `## TEST` carry the steps, and the
fourth phase, `` ## DEPLOY: `<branch>` ``, **is** the changelog entry that folds into `CHANGELOG.md` at the
merge.

**The split was right about the problem and wrong about the shape.** One file used to do both jobs and
shipped three of v3.2.0's twenty-one entries with a to-do heading still in them; two files fixed that and
meant the plan a branch is working through and the claim it will make were never on one screen. What makes
the merge safe is that the separation is now **structural** rather than a written instruction: the entry is
a named section with the branch in its heading, so
[`Split-DevelopmentCycle`](scripts/lib/entry-scaffold-lib.ps1) is the one place that finds the boundary —
the fold takes that section, the step gate counts only above it, and the scaffold gate reads only inside
it. Nothing does two jobs at once, so nothing has to be replaced before the PR.

Three things came along because the merge forced them, and each is the kind of change that fails silently
if it is got wrong:

- **The reset test is the branch NAME, not the heading level.** Two files could open with an `#` while
  empty and an `##` once written; one document cannot, because its `#` is its title in both states. So
  `Test-BranchChangelogIsFilled` reads the name — the trunk's means nothing pending — which is also what
  makes folding twice impossible.
- **`Resolve-BranchFilePath` resolves on content, not existence.** Every rename before this one could use
  `Test-Path`, because the new name did not exist until something wrote it. This one lands on the trunk in
  its reset state, so every branch in flight *has* the new file, empty, beside the pair holding its real
  work. Resolving on existence would have handed those branches an empty document and called their entry
  missing — the stranded half-finished branch the dual-read exists to prevent.
- **The tier sub-heading level depends on the shape being written.** In the named shape tier 0 has no
  heading and the audience tier is the entry's first inner heading, at `###`. In the numbered shape the
  tiers are sub-sections *of* the entry's opening question and must stay at `####`. Measured: a fixture
  stating no audience tier went from four scaffold findings to five, the fifth being the opening question
  its own tiers had just orphaned. So a repo that has stated no audience tier gets the document it had
  yesterday, byte for byte.

**And the guidance came back into the file, which is what let `branch/templates/` go.** Inbound
[#810](https://github.com/DaveKJohn/claude-code-specialists/issues/810) measured what the bare working file
cost — an author met the form in the neighbouring file or not at all — and the fold already stripped HTML
comments, so nothing had to be built for it. The reference and the file you write in are the same page now,
and the copy on the trunk is what the lint holds to the formatter.

**Score:** 5

### What makes this deploy extra special
<!--
     Why the deploy matters AT THIS REACH specifically. For tier 2 audiences: the subscriber of a service.
     That reader and nobody else -- what matters only inside this repo is said in the section above.

     If it has no significance at this reach at all, then explain shortly why and insert N/A in Score.
     That reason goes above the Score line too, and one or two lines is the whole of it: N/A is a
     complete answer and the common one.
-->

Anyone running this workflow works in one file instead of two, and the difference lands the first time
they open a branch: the plan they are working through and the paragraph they have to write are on one
screen. The reference copy beside it is gone and nothing is poorer for it — the guidance is in the document,
which is where inbound #810 said it should have been.

Two changes are visible without being asked for. A branch name now ends in `-v1`, completed by
`new-branch` rather than demanded, so a second cycle on the same subject is a deliberately typed `-v2`
instead of a name arguing about whether it is final. And a branch already open keeps working: the resolver
reads whichever file names your branch, so a plugin update mid-branch strands nothing and there is no
migration to run.

**Score:** 4

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

The branch folder becomes one development cycle

