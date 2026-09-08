## fix/1566-truncated-plugin-links

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

16 absolute links across four plugin pages carry only `Get-RepoBlobUrl`'s base -- the path, and where
there was one the anchor, were dropped -- so every one of them resolves to the repository front page
while its link text names a specific file. Repair all 16, and extend the `[plugin-link]` check to
report that shape, since it is the check's own suggestion pasted without its tail.

#### Two corrections to the report, both verified before the work started

Neither changes the repair; both are recorded because the issue is what a later reader will find first.

- **`[plugin-link]` is check 30, not check 28.** Check 28 is `[import]`. The report identifies
  the check by its tag as well, and the tag is what does not go stale under renumbering -- which is why
  the substance stood.
- **Four plugin pages, not five.** The report's prose says five and its own table lists four
  (`specialists-init` 8, `specialists-teardown` 2, `dkj-policy/scripts/README.md` 3,
  `dkj-policy/README.md` 3 = 16). The count of links was right; the count of files was one high.

#### The owner name travelled with the repair

All 16 were still written on `DaveKJohn/` -- the report's excerpt shows two of them on the new owner,
which is the shape after the repair it cites rather than what stands on the trunk. They are corrected to
`DKJ-Solutions/` here under the standing rule that an existing citation is corrected when its line is
edited for other reasons; these lines are being rewritten anyway. Nothing beyond the 16 edited links was
swept, and the four files still carry `DaveKJohn/` issue and pull-request citations on lines this branch
never touched.

### CREATE

- [x] Repair the three links in `plugins/dkj-policy/README.md` -- the teams directory, `INSTALL.md`,
      `UNINSTALL.md`.
- [x] Repair the three in `plugins/dkj-policy/scripts/README.md` -- the root `scripts/` tree,
      `shared-scripts-lib.ps1`, the connectors README.
- [x] Repair the eight in `specialists-init/SKILL.md`. Six of them name a section rather than a file,
      so each got its anchor back: the orchestrator-delivery section and the bootstrap-path section of
      the root README, the seam specification, the install page's quickstart, and both spellings of
      *Staying up to date* -- the two-command one for the pair, the adoption-half one for the mechanics.
- [x] Repair the two in `specialists-teardown/SKILL.md` -- the seam specification, and the ideal-shape
      section that states the *no live reference* requirement.
- [x] Extend check 30 (`[plugin-link]`) in `../scripts/lint/check-plugin-integrity.ps1` with the
      truncation half: an absolute link whose target is this repo's blob/tree base and nothing else.
      Both spellings (`blob`/`tree`), a missing trailing slash and the anchor-only form all count; the
      branch is read out of the seam rather than assumed to be `main`.
- [x] State in the coverage note what this half did -- and, where the repo has no
      `scripts/repo-config.ps1`, that it did not run at all. It is the one place this check needs the
      seam for a verdict instead of for advice.

### TEST

- [x] `scripts/tests/check-plugin-integrity-links.tests.ps1` -- five new scenarios on the truncation
      half: the honest gap without the seam (and the coverage sentence that admits it), the finding with
      its line number and message, all four live spellings plus a fenced fifth that must stay masked,
      and the narrowness of the rule -- a base with a real path after it passes, and so does another
      repository's bare root, which is what pins the verdict to the seam rather than to a hardcoded
      name.
- [x] `grep -rn "blob/main/)\|tree/main/)" plugins/ --include=*.md` returns nothing, and the same sweep
      widened to the whole tree and to the anchor-only and slashless forms returns nothing either.
- [x] The full gate: `check-plugin-integrity.ps1` plus every suite, via `open-pr.ps1`.

### DEPLOY: fix/1566-truncated-plugin-links

Sixteen links in the plugin payload named a file and pointed at the repository front page. A consumer
reading `specialists-init` -- the first page a new adopter opens -- was told to read `INSTALL.md` and
landed on the repo's home page to find it themselves. All sixteen now carry the path they name, and the
six that named a section carry its anchor.

Nothing could have caught them. GitHub answers `.../blob/main/` with the repo root, so all sixteen
returned 200 and were never dead links; the dead-link scan skips absolute targets, and `[plugin-link]`
skipped them too, because its subject is a *relative* target escaping the plugin root. The defect sat
in the gap between "not dead" and "not relative".

So the check that produced the shape now holds it. `[plugin-link]`'s suggestion hands the author the
absolute form of an escaping link, anchor included; sixteen base-only links against the seventeen
repairs that suggestion was written for is close enough to name the mechanism -- the advice was right,
and nothing held the *result* of taking it. The new half reports an absolute link that is this repo's
blob/tree base with nothing after it: the one absolute shape that is provably not what the author
meant, since the link text always names something more specific. Absolute links stay otherwise out of
scope. It keys on `Get-RepoBlobUrl`, so it cannot disagree with the suggestion about which URL counts
as this repo's -- and in a repo without that seam it does not run and the coverage line says so.

That keying has one named cost: a base-only link written on the *previous* owner name is out of reach,
which is where all sixteen of these were. Widening to reach it was declined -- recognising a retired
owner path would bless a spelling the repo-citation rule is retiring -- and there is no instance left to
justify it: zero base-only links on either owner remain anywhere in the tree, and every future one comes
from the suggestion, which writes the current base. A test pins the pass, so reaching for it later has to
be a deliberate edit.

**Score:** 3

#### What makes this deploy extra special

A gate whose own advice creates a defect class it cannot see is the shape this repo keeps paying for,
and the reach is a consumer's first read rather than an internal document. Not a required migration and
nothing breaks, so it stops short of 4: a reader who never clicked those links loses nothing, and one
who did now lands where the text said.

**Score:** 3

#### Pull Request

Give the 16 truncated absolute plugin links their real paths, and gate the shape
