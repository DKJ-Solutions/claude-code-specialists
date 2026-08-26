## Development cycle: `fix/intent-placement-in-the-skill-page-v1` · 20260826-162031

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

PR #929 moved `-Intent` into `PLAN` and swept the three documents that described the old placement. It
missed two, and the miss was found the way it should not have to be: a parallel parked branch
(`fix/intent-under-the-first-phase-v1`, repairing the same defect and overtaken by #929) had one of them
in its diff.

- [x] The one that matters is `plugins/workflows/contributing-davekjohn/skills/new-branch/SKILL.md`. It is
      the ONLY documentation a consumer has for a mirrored entry point -- the exact reasoning check 18 of
      the lint gate is built on -- and it still told them the intent lands at the top of the document.
      Check 18 passed it, correctly: it asks whether a parameter is NAMED, not whether the page is true.
- [x] The second is Derek's own lens, `.claude/specialists/lenses/05-05-extension.md`, which states the
      placement in his toolbox list.
- [x] Swept the whole tree for the two phrases rather than fixing what was pointed at. The three remaining
      hits are unrelated: `entry-scaffold-lib.ps1:2600` is about an entry inserted above a section,
      `entry-scaffold.tests.ps1:1774` about the guidance block, and `DEVELOPMENT-portable.md:403` is
      #929's own historical note.

### CREATE

- [x] `SKILL.md`: the parameter's real place, plus a line for anyone holding a branch scaffolded before
      August 26, 2026 -- they have a document their gate will refuse and a one-paragraph repair.
- [x] Derek's lens: same correction, one sentence.

### TEST

- [x] Nothing to assert here that #929 does not already: the placement is pinned by
      `new-branch.tests.ps1` scenario (h) and `branch-entry-gate.tests.ps1` scenario 10. This branch
      changes prose only.
- [x] Lint gate green, including check 18 (every mirrored parameter still named in its page) and the
      dead-link scan over the two edited documents.

### DEPLOY: `fix/intent-placement-in-the-skill-page-v1`

The `new-branch` skill page and the DevOps lens now name where `-Intent` actually writes: the opening
paragraph of `PLAN`, without a heading. Both still described the pre-#908 placement at the top of the
document. The skill page is the only documentation a consumer has for that parameter, so it also tells
anyone holding a branch scaffolded before August 26, 2026 what to move and where.

**Score:** 3

#### What makes this deploy extra special

A consumer reading the skill page would have been told to expect the intent somewhere the scaffolder no
longer writes it, and -- worse -- would have had no way to connect a refused branch document to the
parameter that caused it. The page now carries both the correct placement and the one-line repair for a
branch already in flight.

**Score:** 3

#### Pull Request

the new-branch skill page and Derek's lens name the intent's real place

