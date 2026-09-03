## docs/prose-phase-heading-levels

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

Sweep the docs that show the development document's phase headings at the pre-shift levels. Both levels come from seams (Get-BranchCycleHeadingLevel = 2, Get-BranchCycleSectionLevel = 3, Get-EntryHeadingLevel = 3, Get-EntrySectionLevel = 4); each site is read before it is changed, because some fenced blocks deliberately show an old shape as history. Issue #1338.

### CREATE

- [x] Sweep the repo-local layer: `.claude/specialists/lenses/05-06-extension.md`, `INSTALL.md`, and the drift-linted `pull_request_template.md` pair (`.github/` + `plugins/workflows/contributing-davekjohn/templates/`)
- [x] Sweep the portable layer under `plugins/workflows/contributing-davekjohn/`: `CONTRIBUTING-portable.md`, `DEVELOPMENT-portable.md`, `RELEASES-portable.md`, and the `new-branch` / `open-pr` / `cut-release` / `fold-changelog` skill pages
- [x] Repair the PR-template half in the SEAM rather than in the file, once check 23 refused the direct edit
- [x] Bring this branch's own document to today's heading shape -- it was scaffolded before the #1335 merge landed

#### Both halves of the shift, swept together

The August 26, 2026 shift moved three levels, not one. #1338 names only the phase headings; the entry's
inner sections moved with them, and correcting one half alone leaves `### DEPLOY:` with a `###` section
claimed as sitting *under* it. So the sweep covers both, and the scaffolder's own output is the ground
truth it is held against.

#### Not mechanical, per site

Both levels come from seams, so the right figure is the shipped default -- and some fenced blocks
deliberately show an OLD shape as history ("it used to be", "still read wherever an older entry carries
it"). Each site is read in context before it is changed, and the ones left standing are reported with the
phrase that identified them.

#### Where a level swap was not enough, and what was filed instead

Three passages had to be rewritten rather than digit-swapped, because the shift expired their *reasoning*
and not just their figure: the entry-promotion paragraph in the lens and its twin in `fold-changelog`, both
still describing the pre-[#953](https://github.com/DKJ-Solutions/claude-code-specialists/issues/953)
regex-range promotion, and `CONTRIBUTING-portable.md`'s claim that a creation stamp stands on the document's
own heading, which #1335 retired along with the title word and the backticks.

The same defect class in **script comments** was filed as
[#1341](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1341) rather than swept here -- it
is `scripts/**` and it includes check 13's own header, which describes the gate as holding an entry to
"an H2 with three named H3 sections" while the gate derives H3, two, and H4 from the seams. Two plain level
statements in `pr-body-lib.ps1` were done here anyway, since the seam repair had the file open; the third,
`Get-EntryDescription`'s heuristic rationale, is on that issue with the analysis, because its premise was
that the two formats sit at *different* levels and the shift collapsed that.

### TEST

- [x] `check-plugin-integrity.ps1` green -- 0 errors across all 30-odd checks, after the seam repair and a
      `build-shared-scripts.ps1` mirror rebuild
- [x] The defect class greps back to zero outside the deliberate-history sites, in both halves
- [~] The full suite -- dropped as a step: `open-pr` runs every suite as its own gate at the push, so a box
      here could only be ticked in advance of the measurement it claims

### DEPLOY: docs/prose-phase-heading-levels

The documents that teach the branch document's shape now show the shape the scaffolder actually writes.
The August 26, 2026 level shift moved three things -- the document's own heading to `##`, the four phase
headings to `###`, and the entry's inner sections to `####` -- and the prose describing all of it was left
at the pre-shift levels for a week, in eleven files. Nothing caught it, because the gates hold real branch
documents and real entries to their level and never prose about them.

Both halves are corrected together, which is the part worth knowing: repairing only the phase headings
would have left `### DEPLOY:` with a `###` section claimed as sitting *under* it -- the same level, so the
sentence would have become false in a new way. Where the shift expired a passage's *reasoning* rather than
its figure, the passage was rewritten; where it expired a script comment's, it was filed as #1341 instead.

**Score:** 3

#### What makes this deploy extra special

A consumer copies the shape from exactly these pages, and they ship through a release. `CONTRIBUTING-portable.md`,
`DEVELOPMENT-portable.md`, `RELEASES-portable.md` and the four skill pages were telling them to write `##`
where their own scaffolder writes `###` -- and the shipped PR template told them to paste from a
`'## DEPLOY:'` line their document has not carried since August 26.

That last one was the only half with teeth, and check 23 is what found it: the template is generated from
`Get-PrTemplateReference` and its placeholder must match `Get-PrDescriptionPlaceholderDefaults` verbatim, so
editing the file was refused. The corrected form is **appended** to that list rather than replacing the old
one -- the append-only rule from #952, whose whole point is that a consumer's template is their own file and
still carries the previous wording. So a consumer who has not migrated keeps getting a description, and a
new template is written with the level their document actually has.

**Score:** 3

#### Pull Request

Correct the phase heading levels in prose about the branch document

