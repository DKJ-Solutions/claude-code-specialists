## Development cycle: `docs/contributing-numbered-steps-v1` · 20260826-140545

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `
###
` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `
####
` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `
###
 PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `
####
`
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

The spec on [#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894) was edited again after
[#911](https://github.com/DaveKJohn/claude-code-specialists/pull/911) shipped the previous delta, and this
branch builds what is left. Two ambiguities in the body were settled by Dave in session on August 26, 2026,
and both are recorded on the issue:

- **Four `##` headers**, not `###`. The body's prose says "4 ### headers in total" while its own example
  structure writes the four sections as `##`; the example holds.
- **The gates are numbered `2.2.1` through `2.2.4`**, all four ascending from 1. The body names three
  numbers (`2.2.3`-`2.2.5`) for four gates, which is an off-by-two in the filing rather than an instruction
  to leave the scaffold gate unnumbered.

**Scope: one file.** Nothing parses `contributing-davekjohn/CONTRIBUTING.md` and nothing links to an anchor
inside it -- measured on this branch, a `CONTRIBUTING.md#` sweep over the tree returns nothing. So this is a
text change, not a scaffolder or parser change, which is what separates it from #911.

**One genuinely new section, and it is the only content that is not a renumbering:** step `2.3`, the merge
queue, owned by [#912](https://github.com/DaveKJohn/claude-code-specialists/issues/912). Nothing on the page
mentions queuing or serialised merges today.

#### One stale cross-reference gets corrected on the way

The fold paragraph reads **"2C and 2D are one command"** while the headings it points at are `2D` and `2E`.
It went stale when "Open the PR" became its own step and everything below it shifted one letter. The
renumber makes it `2.5` and `2.6`, which is what it always meant.

#### The two sections that were not steps

Dave, in session, after the renumber: the page still carried six `##` headings, because the seam table and
the pointer list sat between the title and step 1 and were `##` as well. Both are folder-index material
rather than steps in the cycle, so they moved to
[`contributing-davekjohn/README.md`](contributing-davekjohn/README.md), which already is that index. That is
what makes "four `##` in total" literally true rather than true-if-you-only-count-the-steps.

### CREATE

- [x] Lift the four section headings: `# [ 1 NEW DEVELOPMENT TASK ]` -> `## 1. NEW DEVELOPMENT TASK`, and the same for 2, 3 and 4 -- brackets out, ordinal and period in
- [x] Renumber section 1: `1A`+`1B` -> `1.1`, `1C`+`1D`+`1E` -> `1.2`, `1F` -> `1.3`, `1G` -> `1.4`, `1H` -> `1.5`, all at `###`
- [x] Renumber section 2: `2A` -> `2.1`, `2B` -> `2.2`, `2C` -> `2.4`, `2D` -> `2.5`, `2E` -> `2.6`
- [x] Renumber the four gates from `### Gate n` to `#### 2.2.n`, ascending from 1
- [x] Write the new `### 2.3` -- the merge queue -- with `2.3.1`, `2.3.2` and `2.3.3` under it
- [x] Renumber sections 3 and 4: `3A`-`3G` -> `3.1`-`3.7`, `4A` -> `4.1`
- [x] Repoint every in-text cross-reference to a step or a gate, including the stale `2C and 2D` in the fold paragraph
- [x] Reword the two places that say "shifts one letter" / "differ by one", since the steps are numbers now
- [x] Move the seam table and the pointer list to `contributing-davekjohn/README.md`, repointing the two references inside them that said "below" / "above" while they lived on the other page
- [x] Rewrite the front matter's heading-level paragraph, which described the levels #911 had just set and was stale the moment this branch moved them again

### TEST

- [x] Sweep the file for a surviving letter-step (`1A`-`4H`) or `Gate n` reference -- expect none; none found
- [x] Confirm the heading tree matches the spec exactly: four `##`, and `###`/`####` beneath them -- `grep -c '^## '` returns 4
- [x] `check-plugin-integrity.ps1` green -- it carries the dead-link scan, and both the renumber and the move relocate headings. 291 links and 291 imports re-scanned, 0 findings
- [x] Every `scripts/tests/*.tests.ps1` suite green -- 52 suites, all passing
- [x] Re-checked `sync-rules.tests.ps1`, which first read as failing: it prints `OK: all 61 asserts passed` and is the one suite ending without an explicit `exit 0`, so an IN-PROCESS run leaves `$LASTEXITCODE` at the last `git` call inside it. Both `open-pr` and CI run each suite as its own process (`Invoke-TestSuiteGate` reads `Process.ExitCode`), where it exits 0. A measurement artefact of how it was invoked, not a defect -- nothing filed
- [~] No test was added. Dropped with the reason: nothing reads this page. The lint gate's link scan is the only automated statement about it, and it already covers the class of defect a move introduces

### DEPLOY: `docs/contributing-numbered-steps-v1`

`contributing-davekjohn/CONTRIBUTING.md` now carries the step numbering
[#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894) asks for: four numbered `##` sections,
their substeps as `###`, and the four gates as `####` under the step where they fire. The letters are gone --
`1A`-`1H`, `2A`-`2E`, `3A`-`3G`, `4A` became `1.1`-`1.5`, `2.1`-`2.6`, `3.1`-`3.7` and `4.1` -- and every
in-text reference to a step or a gate moved with them.

**Four `##` *in total*, which needed more than a renumber.** The seam table and the pointer list sat between
the title and step 1 as `##` sections that were not steps, so the page read as six. Both moved to
[`contributing-davekjohn/README.md`](contributing-davekjohn/README.md), the folder index they always were.

**One new section, and it is the only content here that is not a renaming:** `2.3`, the merge queue
([#912](https://github.com/DaveKJohn/claude-code-specialists/issues/912)). Two PRs must not merge at once,
because every branch's fold writes into the same place in `CHANGELOG.md` -- the top of `## [Unreleased]` --
and it writes there after the merge, on `main`. Two folds racing break in the gap between the merge and the
fold, which is the state nothing reports: the later run's fold push is rejected as non-fast-forward, or
`ship-pr.ps1` step 5 aborts on its ff-only merge before folding at all. Either way the PR is merged, the entry
has not landed, and every gate stays green until a release trips over it. **No gate enforces the queue**,
which the section says out loud rather than leaving a reader to assume a script is watching.

**The sync in `2.3.3` is written as hygiene rather than as ordering, deliberately.** The fold inserts at the
top of `## [Unreleased]` on whatever `main` it is standing on, so the order entries end up in follows merge
order and not branch freshness -- syncing a stale branch does not move its entry up. The queue is what keeps
the order; the sync keeps a branch from merging a tree it was never tested against. Both claims were checked
against `ship-pr.ps1` step 5 rather than inferred from the shape of the problem.

**Two stale statements were corrected on the way, both of which had gone stale within the last two days.**
The fold paragraph said "2C and 2D are one command" while pointing at `2D` and `2E` -- it had been left behind
when "Open the PR" became its own step. And section 3 opened by explaining that its letters differed from #894
by one, because the issue asked for a release-note step this page did not have; the August 26 edit dropped
that step, so the two now agree and the paragraph was describing a gap that had closed. The subject itself did
not go away with it and is now [#914](https://github.com/DaveKJohn/claude-code-specialists/issues/914).

**Score:** 2

Reason: it changes how the page reads for anyone following the cycle here -- every step reference in it is a
different string than it was -- but the cycle it describes is unchanged, and the one genuinely new step is a
convention rather than a mechanism. A reader notices the moment they open the page; nobody has to do anything
differently except queue behind an in-flight merge.

#### What makes this deploy extra special

**Score:** N/A

Nothing here reaches a consumer. This page is this repo's own set of answers; the portable half that ships
with the plugin is untouched.

#### Pull Request

CONTRIBUTING.md's four steps become numbered ## sections with dotted substeps, and the PR gains a merge queue
