## fix/1816-retired-doc-name-citations

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

#### What #1816 reports, and what the tree actually says

Three present-tense citations of `check-retired-doc-name.ps1` and `check-supremacy-declaration.ps1`,
two scripts #1421 folded into `check-consumer-prose.ps1` behind the single
`consumer-prose-sessioncheck` hook. Verified against the tree before any repair, and two things came
back different from the report:

- **The SKILL.md row is stale in BOTH columns, not half right.** The report says its `check` column
  "names the two detector *functions*, which do still exist inside the merged script". It does not:
  the functions are `Get-RetiredDocNameMention` and `Get-SupremacyDeclaration`, and that column held
  the two retired *script* stems. So the repair names the functions rather than keeping the column.
- **The same block carries a fourth stale claim the report did not list.** `check-policy-drift.ps1`'s
  own printed heading said *"Each has its own SessionStart hook"*, and its `[skipped]` line said
  *"their own checks"* -- both plural, both about the pair that no longer exists. Repairing the
  comment three lines below while leaving the output claiming two hooks would have put a fresh
  contradiction on one screen, so both are in scope.

`scripts/lib/check-report-lib.ps1:237` is the fifth present-tense citation and is deliberately **not**
here: it is #1813's own subject, and its repair is parked on `fix/1813-safe-prose-docstring`. Touching
it here would conflict with that branch.

The four historical citations stay exactly as written -- `seam-lib.ps1:116`, `consumer-check-lib.ps1:8`,
`shared-scripts-lib.ps1:180` and the three sites in `05-15-extension.md` all narrate the fold in the
past tense on purpose, which is the same thing this repo's own prose-check skip exists to protect.

### CREATE

- [x] `scripts/task/check-policy-drift.ps1`: name `check-consumer-prose.ps1` and
      `consumer-prose-sessioncheck` in the skip comment, the printed heading, the `[skipped]` line and
      the split comment at the finding loop -- with a paragraph saying what #1421 folded and when
- [x] `plugins/dkj-policy/skills/check-policy-drift/SKILL.md`: the table names the two surviving
      detector functions and the one hook, followed by the fold's own history in the
      `seam-lib.ps1:116` shape; the six `DaveKJohn/...` URLs corrected as the #1526 ride-along
- [x] `scripts/sync/build-shared-scripts.ps1` run, so `plugins/dkj-policy/scripts/task/` carries the
      repaired mirror

### TEST

- [x] `check-plugin-integrity.ps1` green (frontmatter, dead links, the shared-scripts drift lint)
- [x] all suites green -- `policy-drift-report.tests.ps1` in particular, which asserts on this
      script's `[retired-name]` output
- [x] no citation of either retired script or either retired hook name left in the present tense

### DEPLOY: fix/1816-retired-doc-name-citations

`check-policy-drift`'s report and its consumer-facing skill page no longer send a reader after two
scripts and two hooks that #1421 folded away before either had ever shipped. The report's explanation
of *why* it copies the hook's publishing-repo skip now cites the script that makes it, so the reasoning
can be checked; its printed heading names `consumer-prose-sessioncheck` instead of claiming a hook each;
and the skill page's table names the two detector functions that do exist, with the fold's own history
under it in the shape `seam-lib.ps1` already uses. The four citations that narrate the fold in the past
tense are untouched.

**Score:** 2

#### What makes this deploy extra special

A consumer holding the `check-policy-drift` skill page was told to look for `retired-doc-name-sessioncheck`
and `supremacy-declaration-sessioncheck`, two hook names no release ever carried, and would find one
hook called `consumer-prose-sessioncheck`. That page is the reference for a check whose whole subject is
documents contradicting each other, so it was the worst place in the tree for this to sit.

**Score:** 3

#### Pull Request

Name check-consumer-prose.ps1 where the retired detector scripts were still cited in the present tense

