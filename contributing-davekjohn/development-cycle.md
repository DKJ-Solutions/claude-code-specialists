# Development cycle: `fix/the-changelog-intro-names-the-current-folder-v1` · 20260826-111358

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `##` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `###` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `## PLAN`** -- everything between the H1 and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `###`
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

## PLAN

### The defect, and why it survived #905's own sweep

`CHANGELOG.md`'s intro pointed at the folder page as
`` [`workflow-davekjohn/CONTRIBUTING.md`](contributing-davekjohn/CONTRIBUTING.md) `` — the **target**
followed the rename in #905, the **text** did not, so the intro named a path that no longer exists.

The reason it slipped through is the rule that was applied correctly everywhere else. #905 renamed a folder
that 42 published release notes link into, and the doctrine those notes carry is explicit: *"links may be
repointed when a target moves, prose is never rewritten."* So the sweep updated link **targets** and left
every prose mention alone — 39 targets moved, 303 mentions stayed. **`CHANGELOG.md`'s intro is the one place
in that set where prose is not a record**, and this repo already says so, in the `[entry-shape]` check's own
reasoning: the entries below the intro are history, *"the intro is a live statement about the present
mechanism that every cut copies through verbatim"*. A rule stated for one file and applied to a set that
contains it is exactly the shape that produces one wrong line.

### Measured rather than assumed to be a single instance

`git grep` for a link whose text names the old folder while its target names the new one, across every live
layer (excluding `releases/` and the folder's own audience notes, where the mismatch is correct): **one**
occurrence, `CHANGELOG.md:16`. Two more in history, left exactly as they are — there the text is testimony
about what the file was called when the note was written.

## CREATE

- [x] `CHANGELOG.md:16` — the link text now names `contributing-davekjohn/CONTRIBUTING.md`, matching its target
- [~] No sweep, no new check. Dropped rather than skipped: the class was measured at one instance and is now zero, and a gate for "a link whose text disagrees with its target" would be born accusing the two history notes where that disagreement is the doctrine working

## TEST

- [x] The class is empty: the same `git grep` that found the one instance returns nothing across the live layers
- [x] The two history occurrences are untouched — verified by the same query scoped to `releases/` and `contributing-davekjohn/releases/`
- [x] Lint gate and all test suites green

## DEPLOY: `fix/the-changelog-intro-names-the-current-folder-v1`

`CHANGELOG.md`'s intro named `workflow-davekjohn/CONTRIBUTING.md` in the text of a link already pointing at
`contributing-davekjohn/CONTRIBUTING.md`. One line, and the intro is the one part of that file which is live
prose rather than history — every release cut copies it through verbatim, so it would have shipped a dead
path into the next release notes.

**What it corrects is the reach of a rule, not a typo.** #905 renamed a folder that published notes link
into, and followed the doctrine those notes carry: repoint targets, never rewrite prose. Applied across
`CHANGELOG.md` that is right for the entries and wrong for the intro, which this repo separately documents
as a live statement rather than a record. Measured after the fix: one instance in the live layers, now zero,
and the two in history left as the testimony they are.

**Score:** 2

### What makes this deploy extra special

N/A — the changelog intro is read by whoever opens this repo's changelog, not by a consumer of the plugins.
A reader who clicked the link landed in the right place either way; only the label was wrong.

**Score:** N/A

### Pull Request

Fix the changelog intro so its link text names the folder that exists
