## docs/1408-closeout-ceiling-order

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

#### What #1408 reports, and what verified

Two live statements that cannot both be read as written. `plugins/teams/team-alpha/personas/01-01-persona.md`
carried *"the ceiling holds regardless"*, which reads as the ceiling applying **independently of** the
duplication test -- and `contributing-davekjohn/releases/changelog/4.x/4.21.0.md` (the archived reasoning
behind the August 27, 2026 decision the same paragraph cites) refused exactly that: *"a word budget would
cut the one sentence a requester can only get from the session."* Both quoted texts were held against the
trunk before anything was edited; both stood.

The reason verified too, and it is narrower than "they contradict each other": the archive objects to a
budget that **cuts**, and a ceiling that **rehouses** is not one. So the reconciliation is the order --
duplication filters first, the ceiling caps what survives, and the surplus over it moves rather than
shrinking. Stating that is the whole repair.

#### Why the archive is not amended

An archived release note is the record of what a release contained; rewriting its argument would falsify
history to settle a live rule, and the argument is not wrong -- it is aimed at a different mechanism. Once
the live rule states the order and names that decision, a reader arriving from the archive meets the
reconciliation in the rule they are standing under. The archive's own observation, *"two or three lines is
the usual size as a consequence"*, is promoted to the stated figure instead, which is what #1402 asked for:
a session can argue about what counts as a handful and cannot argue about three.

### CREATE

- [x] Rewrite the ceiling paragraph in `plugins/teams/team-alpha/personas/01-01-persona.md`: the order
      (duplication first, ceiling second), the figure (**two or three lines**), and why it is not the word
      budget that decision refused (the surplus is rehoused, not cut).

### TEST

- [x] Held both quoted texts against the trunk at the paths and lines the issue gives -- symptom stands.
- [x] `grep` for every live statement of the rule (`duplication, not length`, `handful of lines`,
      `two or three lines`): the persona is the only one. Chris's manual and
      `agent-shared/findings-become-issues.md` carry none, so no second copy drifts.
- [x] Read the archive's claim against the new wording: *"a word budget would cut..."* stays true of a
      budget, and the persona now says in so many words that this is not one. Both live, neither edited
      into agreement.
- [~] No suite covers persona prose -- the lint gate's frontmatter and dead-link checks are what apply,
      and `open-pr` runs them.

### DEPLOY: docs/1408-closeout-ceiling-order

Fixed [#1408](https://github.com/DaveKJohn/claude-code-specialists/issues/1408): the length ceiling
[#1406](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1406) put into Chris's close-out
stood beside the archived August 27, 2026 reasoning that had **refused a word budget**, with nothing on
either page saying how the two fit -- so the next session to read the archive found a recorded argument
against the guardrail it was standing under. The paragraph said *"the ceiling holds regardless"*, which is
the one reading under which the objection lands.

The repair is the order, because the objection was aimed at a ceiling applied *instead of* the duplication
test and not *after* it. The persona now states both in sequence -- duplication filters first, so the
sentence only the session can give is never what the ceiling meets; the ceiling then caps what survives,
because *"not a duplicate"* is always satisfiable -- and says why that is not a budget: over the ceiling a
surplus is **rehoused** into the branch document or an issue the receipt cites, not cut. And the figure the
archive recorded as the observed consequence, *"two or three lines"*, becomes the stated rule in place of
*"a handful of lines"*, which is the cruder form #1402 asked for.

The archive is deliberately left as written. It is the record of a decision, its argument is true of the
budget it was aimed at, and the live rule is where a rule is repaired.

**Score:** 2

#### What makes this deploy extra special

Every consumer's orchestrator gets a number where it had *"a handful"*, and stops carrying a rule its own
shipped history argues against -- a contradiction a consumer can only ever find at the moment it costs
them, mid-close-out, with the archive quotable in defence of the length the ceiling exists to stop.
Line-count neutral but one: the ordering and the figure are paid for by dropping the restatement of what
the receipt contains, which the paragraph above it already names.

**Score:** 2

#### Pull Request

state the order between the close-out's duplication test and its length ceiling
