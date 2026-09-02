## Development: `fix/bwj-codex-english-stage-examples-v1` · 20260902-130339

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

Dave: repo content is English, the terminal reply is the only place Dutch is allowed. The board's sections were renamed to English via the Asana MCP already; this branch repairs the five Dutch lines that shipped in #1223 -- one docstring example, one portable-page example, three test fixtures.

#### Why it happened, which is the part worth keeping

The section names of #1222 were written in the language of the board's readers, and the language rule
does not bend for that: `.claude/rules/language-layers.md` is exhaustive over repo content, and the
one exception it grants is *citing* an external object's live name, not choosing one. Renaming the
board to English removed the citation, and the examples had to follow. Dave, September 2, 2026: keep
it to English, and the terminal reply is the only place another language is allowed -- never in
anything being built. **Which this document is**, so the instruction is paraphrased rather than
quoted; a verbatim quote here would have been the same defect in the file repairing it.

Worth noting where the rule already held on its own: the folded changelog entry came out clean,
because the only Dutch in that document sat in `PLAN` -- a quotation of Dave's own gate sentence --
and the fold takes the `DEPLOY` section alone.

### CREATE

- [x] The board's six sections renamed to English through the Asana MCP -- stages 1 to 4; `5. Waiting`
      and `6. Completed` are Dave's own words and already English, so both were left alone
- [x] `asana-mirror.ps1`: the `Get-StageFromSectionName` docstring example
- [x] `WORKFLOW-portable.md`: the same example in step 6
- [x] `bwj-codex.tests.ps1`: three fixture section names, and the assert column realigned

### TEST

- [x] `bwj-codex.tests.ps1`: green, still 128 asserts -- the fixtures changed, the assertions did not,
      which is the point: the helper reads the number and never the words
- [x] All three touched files re-checked for non-ASCII by code point, not by eye
- [x] Tree-wide sweep for the five phrases: none left in `plugins/` or `scripts/`

### DEPLOY: `fix/bwj-codex-english-stage-examples-v1`

The stage examples that shipped with the board-section model were written in Dutch -- one docstring in
`asana-mirror.ps1`, one in step 6 of `WORKFLOW-portable.md`, and three fixture names in the test
suite. All five are English now, and the board's own sections were renamed to match, so the examples
cite what a reader actually sees.

Nothing behavioural moved. The suite is green at the same 128 asserts with three of its fixtures
rewritten, which is the model's own claim demonstrated rather than asserted: a section is recognised by
the number its name starts with, so translating every word after that number changes nothing.

**Score:** 2

#### What makes this deploy extra special

A consumer reading step 6 of the portable page now sees examples in the same language as the rest of
it. Previously the one paragraph explaining *"the words after the number are yours"* was the only
paragraph on the page that was not in the page's language -- which made the example look like a
prescription for what to name a section rather than an illustration of what does not matter.

**Score:** 2

#### Pull Request

the stage examples and fixtures follow the repo's English rule

