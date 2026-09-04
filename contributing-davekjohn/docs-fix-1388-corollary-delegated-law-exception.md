## docs/fix-1388-corollary-delegated-law-exception

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

Inbound #1388: `CONTRIBUTING-portable.md`'s corollary ("point, state this repo's answer to a seam,
or say nothing -- never restate the law") and `cut-release/SKILL.md` Block 2 ("a repo running the
non-default order states it in its own `CLAUDE.md`") give a consumer contradictory instructions for
the same case -- a law the plugin deliberately declines to build a seam for. The reporter's own
inference is that the right repair is a named fourth category on the corollary side, not a change to
`cut-release`'s reasoning (which the report itself calls sound). Add that fourth move to the
corollary in `CONTRIBUTING-portable.md`, cross-reference it from `cut-release/SKILL.md` Block 2, and
leave the "no seam" reasoning there untouched.

### CREATE

- [x] Add the fourth-move paragraph to `CONTRIBUTING-portable.md`'s corollary section, naming #1388
  and cross-referencing `cut-release/SKILL.md` Block 2 as the measured instance.
- [x] Add a short cross-reference from `cut-release/SKILL.md` Block 2 back to the corollary's fourth
  move, so the two pages read as agreeing rather than as two independent claims.

### TEST

- [x] Re-read both passages after editing -- the corollary's three moves plus the new fourth move
  now cover `cut-release` Block 2's instruction without a gap: it is scoped to a law the plugin
  explicitly declines to answer, which is the one thing the original three did not have room for.
- [x] Lint + tests green, then PR + merge + fold.

### DEPLOY: docs/fix-1388-corollary-delegated-law-exception

`CONTRIBUTING-portable.md`'s restatement corollary named three permitted moves for a consumer document
(point, state a seam's answer, say nothing) and forbade a fourth (restate the law). `cut-release/SKILL.md`
Block 2 instructs exactly that fourth move for the release-order law, which it deliberately answers with
no seam. The corollary now names a fourth permitted move -- prose for a law the plugin explicitly declines
to answer at all -- scoped to a plugin page that says so in as many words, and `cut-release` Block 2 now
cross-references it. Neither page's underlying reasoning changed; only the corollary's coverage did.
Fixes #1388.

**Score:** 2

#### What makes this deploy extra special

A consumer repo that reads both pages while deciding whether to keep a non-default release order note in
its own `CLAUDE.md` no longer meets a contradiction between the two.

**Score:** 2

#### Pull Request

Add the fourth move (deliberately delegated law, no seam) to CONTRIBUTING-portable.md's restatement corollary

