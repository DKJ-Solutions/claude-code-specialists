## Development cycle: `docs/the-close-out-is-a-receipt-not-the-report-v1` · 20260827-211004

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

Dave, 2026-08-27: the close-out is too long to read. Shape A is 'allowed to be short' and nothing says the detail belongs elsewhere -- so it gets retold in the terminal after already being written into the branch document, the PR body and the issues. Make A name the outcome, point at where the report lives, and say the session can be cleared.

### CREATE

- [x] Locate the rule: step 6 of Chris's ritual, in the persona body. NOT a shared `agent-shared` block,
      so this is a one-file change and the build confirms it -- 0 carriers regenerated.
- [x] Make shape A say what it is for: outcome, where the detail is written, and that the session can be
      cleared. It read *"allowed to be short"*, which permits brevity without asking for it.
- [x] Add the reason, because the permission was not the missing part: by the time a chain closes, the
      reasoning already sits in the branch document, the changelog entry it folds into, the PR body and
      the issues -- so the reply retells it in the one place nobody can search.
- [x] State the test as DUPLICATION rather than length, so the rule does not turn into a word budget that
      drops the one sentence only the session has.

### TEST

- [x] No script or gate reads this text, so there is nothing to assert and nothing is claimed. Stated as
      a gap rather than covered by a test that would only pin wording.
- [x] `build-agent-defs.ps1`: 0 files updated -- confirms the block is the persona's own, so no consumer
      carrier drifts out of step.
- [x] Always-on cost, measured rather than estimated: Chris's persona is on the always-on path, so the
      addition is paid every session. 25,822 -> 27,535 B, **+1,713 B, about 549 tokens**. Measured on the
      git blob and the working tree, August 27, 2026.
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr`.

### DEPLOY: `docs/the-close-out-is-a-receipt-not-the-report-v1`

Chris's close-out is a receipt now, not a second report. Shape A said it was *"allowed to be short"* and
nothing said where the detail belonged -- so a finished chain got retold in the terminal after it had
already been written into the branch document, the PR body and the issues. It now names what happened,
where to read it (the PR or issue number), and that the session can be cleared.

**Score:** 3

#### What makes this deploy extra special

**The test is duplication, not length, and that distinction is the whole rule.** A word budget would cut
the one sentence a requester can only get from the session -- a decision taken on their behalf, or
something that turned out differently than asked -- while leaving three tidy paragraphs that restate the
PR. So the rule names the habit instead: no per-item table, no rundown of who did what, no walk through
the reasoning, when a link carries all three. Two or three lines is the usual size as a consequence.

**"You can clear the session" is stated in as many words, because it is the one fact no PR carries.**
Whether anything is still in flight *here* cannot be read off GitHub, and without it the requester
re-reads the turn to check before starting the next subject -- which is the cost the whole change is
about.

**Score:** 3

#### Pull Request

the close-out is a receipt: outcome, where the detail is, and that the session can be cleared

Plugins: team-alpha