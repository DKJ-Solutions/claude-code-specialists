## Development cycle: `docs/install-skill-counter-figures-v1` · 20260826-165525

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

- [x] Hold each of [#922](https://github.com/DaveKJohn/claude-code-specialists/issues/922)'s four claims against the tree before scoping anything -- symptom, reason, proposed repair, size, subject
- [x] Decide between correcting the three figures and dropping them, and record which, since #873 answered the same question a day earlier

### CREATE

- [x] Rewrite the skill-counter paragraph in `INSTALL.md` so it states no totals and names examples from both plugin kinds

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors
- [x] Every suite in `scripts/tests/` via `Invoke-TestSuiteGate`, the runner CI uses -- 52 of 52 passed
- [x] Confirm no other live claim in the tree repeats these figures; the archived note `releases/development/4.x/4.13.0.md` records them as a past measurement and stays as it is

### DEPLOY: `docs/install-skill-counter-figures-v1`

`INSTALL.md`'s warning about the skill counter states no totals any more
([#922](https://github.com/DaveKJohn/claude-code-specialists/issues/922)). It told a consumer that
**"14 of the 19 skills across the six shipped plugins"** carry `disable-model-invocation: true`; measured
on this branch that is **16 of 24 across five** -- three figures, every one of them stale, in the document
a consumer reads first.

**The fourth claim needed a rewrite rather than a new number, which is why this was a separate issue.**
The four named examples -- `cut-release`, `fold-changelog`, `open-pr` and `ship-pr` -- were introduced as
*"all four of them `contributing-davekjohn`'s rather than `team-alpha`'s"*. True of those four, and it
reads as *`team-alpha`'s are not flagged* while **three of `team-alpha`'s four** carry the flag. The
paragraph now names those three beside the other four and says the flag is found in the team plugins and
the workflow plugin alike, which is the point it was making and the half that does not go stale.

**The totals are gone rather than corrected, the same answer [#873](https://github.com/DaveKJohn/claude-code-specialists/issues/873)
got the day before.** The argument is that the counter is unreliable *because the flag exists*, and that
lands without a cardinality. Nothing in the gate holds a bare count in prose to the tree: check 16
(`[measured-figure]`) covers byte counts and file sizes, and the enumeration span check 10 enforces on the
root `README.md` holds the *names* listed inside it rather than a number in a sentence --
so a corrected figure would only be waiting for the next skill to be added, which is how this one got
here. The repo's own name-count lesson in `CLAUDE.md`, applied to a consumer-facing page: a tally is
wrong when typed and wrong again after the next edit.

**Score:** 2

#### What makes this deploy extra special

`INSTALL.md` is the page a consumer reads while adopting, and a wrong figure there costs more than it
does here: a reader whose own `/reload-plugins` count differs cannot tell whether they mis-installed or
the page went stale -- which is the exact harm check 16 exists to prevent, in the one class of figure
that check cannot see. The misleading clause was worse still, since it pointed a consumer at `team-alpha`
as the unflagged team while three of its four skills are flagged. Nothing needs migrating and no plugin
payload moves: `INSTALL.md` is this repo's own root document, and no plugin ships a copy of it.

**Score:** 2

#### Pull Request

INSTALL.md's skill-counter warning names examples instead of totals
