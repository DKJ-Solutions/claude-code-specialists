## docs/closeout-receipt-ceiling

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

#### The assignment

Issue [#1402](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1402): Chris's close-out
keeps growing back into a report, and the report's diagnosis is that this is not a missing rule but a
rule that keeps losing. Two seams were named, both verified against the tree before anything was
written:

1. `01-01-persona.md`'s *"names what it filed, with numbers"* reads as licence to describe each
   filing -- and a paragraph per ticket is exactly what the September 4 close-out produced.
2. The three permitted shapes have no room for a finding that genuinely cannot be filed from this
   checkout, so it arrives as a fourth one. Verified: `CLAUDE.md` reserves an issue on somebody
   else's repo for Dave's explicit word and the `inbound` carve-out runs the other way, while
   [#1389](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1389) shows the honest
   answer already existed -- the un-filable finding was recorded *inside* the issue that could be
   filed here.

#### The prior decision this had to answer, not override

`contributing-davekjohn/releases/changelog/4.x/4.21.0.md` records the August 27, 2026 decision that
**refused a word budget**, on the ground that one would cut the single sentence only the session can
give while leaving three tidy paragraphs that restate the PR. That reasoning still holds, so the
ceiling is ordered rather than absolute: duplication filters first, the ceiling meets only what
survives, and the surplus moves to a durable home instead of being deleted. The same document supplies
the figure -- it already observed that *"two or three lines is the usual size as a consequence"*, so the
change promotes a described consequence to a stated rule rather than inventing a new number.

### CREATE

- [x] `plugins/teams/team-alpha/personas/01-01-persona.md`: the filing line now gives the **numbers and
      nothing else**, with the worked receipt (`"Filed #1388, #1389, #1399."`) and the September 4
      measurement, so "name what you filed" can no longer be read as "describe each one".
- [x] Same file: a finding that cannot be filed from this checkout is recorded inside the nearest issue
      that **can** be filed here and cited by number -- shape A carries it, and no fourth shape is added.
- [x] Same file: the ceiling. Shape A now says *two or three lines* where it said only `SHORT`, and the
      duplication test is restated as subordinate to it -- naming, in the text, that *"the test is
      duplication, not length"* was itself being quoted in defence of length.
- [x] Compressed the receipt paragraph's lead to hold the always-on growth down, and folded the
      September 4 repetition into its existing August 27 attribution rather than restating it.
- [x] **Acted on the review, which caught the trap this branch had set out to avoid.** The first draft
      stated the figure *three* times inside forty lines -- on the one page whose subject is brevity --
      and the un-filable-finding rule arrived as a paragraph of its own. Nolan measured +1,429 B
      (~458 tokens every turn, in every consuming repo, 100% of it inside step 6) with ~250-350 B of it
      restating the page; Edith reached the same finding independently. So the figure is now stated
      **once**, in shape A, and the other two places back-reference it; the un-filable-finding rule is
      one sentence inside the paragraph that already enumerates the forbidden fourth things, which is
      where it belongs -- it is another instance of that ban, not a new rule. Final delta **+1,112 B**
      (~356 tokens), and Edith's dropped conjunction in the durable-homes list is restored.
- [~] Did **not** move the un-filable-finding rule to the on-demand manual, which was Nolan's third
      proposal (-366 B). The manual's test is right -- one situation, not every turn -- but the trigger
      here is invisible: a session with a finding it cannot file does not know it is in a special case,
      so it reaches for a fourth shape instead of reaching for the manual. Compressed to one sentence in
      the persona instead, which takes most of the saving and keeps the rule where the failure happens.
- [~] No change to `plugins/teams/agent-shared/findings-become-issues.md`. The un-filable-tracker case
      would generalise to every specialist, but the shared block is stamped into 15 agent defs and the
      close-out shapes live only in the persona -- promoting a rule that currently has one home would
      cost 15 copies to no benefit. Its neighbouring bullet (no repo at all -> the finding goes in the
      reply) stays correct and does not contradict the new paragraph.
- [~] No change to `plugins/teams/team-alpha/manuals/01-01-manual.md`. Its phase table still reads
      "one of the three permitted shapes", which is still true -- the count did not change.

### TEST

- [x] Grepped the tree for every restatement of the close-out shapes and of *"duplication, not
      length"*: the shapes exist only in the persona, and the one other hit is the archived 4.21.0
      release note, which is history and is answered in the new text rather than swept.
- [x] Edith (copy edit) and Nolan (always-on cost) reviewed the diff in parallel, and both independently
      returned the same primary finding; acted on above, before the PR.
- [x] `check-plugin-integrity.ps1` + the full suite, via `open-pr.ps1`'s own gate.

### DEPLOY: docs/closeout-receipt-ceiling

Chris's close-out is bounded by a number now, not only by a principle. *"Names what it filed, with
numbers"* was being read as licence to give each ticket a paragraph, so it says **the numbers and
nothing else** -- `"Filed #1388, #1389, #1399."` is a complete receipt and the reader clicks. Shape A
carries a stated size (two or three lines) where it said only `SHORT`, and the duplication test is
explicitly subordinate to it, because a session can always find something non-duplicative to say and
*"the test is duplication, not length"* had started doing duty as the defence of length. A finding that
cannot be filed from this checkout is no longer shapeless either: it is recorded inside the nearest
issue that can be filed here and cited by number, which is what closes the seam that produced *"one
thing needs your word"* as an unauthorised fourth shape.

**Score:** 4

#### What makes this deploy extra special

Every consumer's main loop reads this persona on every turn, so the same drift was shipping to all of
them -- and the fix travels the same way. The August 27, 2026 refusal of a word budget is answered
rather than reversed: duplication still filters first, so the ceiling only ever meets material the
requester cannot get anywhere else, and anything over it moves into the branch document or an issue
instead of being cut.

**Score:** 3

#### Pull Request

Chris's close-out bounded: the numbers only, a hard ceiling, and no fourth shape for a finding that cannot be filed here
