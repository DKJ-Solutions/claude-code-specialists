## docs/1790-figure-gate-script-comments

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

#### The question, and why it is a decline

The issue asks whether check 16's byte-shaped `$figurePattern` should read `scripts/**` and
`plugins/**/scripts/**` comments as well as `$consumerDocs`. It names the haystack count as the
precondition, exactly as #1784 did for line counts. Measured, it declines: check 16's gateability
premise ("no authored, non-measured reason to write a byte figure") is false in a `.ps1` — design
ceilings are authored byte figures, and a script has no fence to separate prose from code.

### CREATE

- [x] Measure the haystack: `scripts/*.ps1` under check 16's pattern + window logic — 49 hits, 26
  flagged, 0 real defects; plugin mirrors add 26 more raw hits
- [x] Record the decline and the measurement in `.claude/specialists/lenses/05-15-extension.md`,
  beside the #1784 line-count decline
- [x] Update the two existing #1790 pointers in that lens ("filed on its own rather than answered
  here" → "measured and declined, write-up below")

### TEST

- [~] No script changed, so no suite changes — the lint + test gate in open-pr covers the dead-link
  and frontmatter checks on the edited lens

### DEPLOY: docs/1790-figure-gate-script-comments

The `[measured-figure]` gate stays byte-shaped and `$consumerDocs`-scoped. #1790 proposed pointing its
existing pattern at `.ps1` comments; measured over `scripts/*.ps1` it flags 26 sites and zero real
defects — encoding prose, ANSI escapes in test strings, authored design ceilings, code read as prose,
and the check's own fixtures and docstring. Declined for the same reasons as #1784's line-count
proposal, recorded in the system-administration lens.

It prevents nothing that has failed; it closes a proposal so the next reader does not re-measure the
same haystack.

**Score:** 1

#### What makes this deploy extra special

A lens write-up about an internal lint gate; no consumer of the plugins notices.

**Score:** N/A

#### Pull Request

Decline extending the measured-figure gate to .ps1 comments, and record the haystack

