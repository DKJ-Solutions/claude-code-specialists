## Development: `fix/the-429-headline-names-the-wrong-window-v1` · 20260829-091808

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

Cause of #1055 established from the run logs before anything was written: all eight red runs carry
`api_error_status: 429` with `You've hit your weekly limit ... resets Aug 31, 7am (UTC)`. The report
inferred nothing about the cause and stated the log did not name one -- that second half is falsified,
and the diagnostic step added after #966 named it on the FIRST red run.

#### What the verification actually found

The reported symptom stands and there is nothing to repair in the credential. What the verification
found instead is a defect one layer over: the annotation the reader lands on **contradicts the reason
printed beside it**. It asserts "out of session quota, which resets on the clock", while the reason
says the limit is weekly and comes back in three days. That is why #1055 could be filed against a run
whose log already carried the answer -- the same shape as #966, which is what the diagnostic was
built for in the first place.

### CREATE

- [x] Establish the cause from the run logs rather than from the report's inference -- 429, weekly
      limit, present on every one of the eight runs including the first (33201227571, 18:51:40Z).
- [x] The 429 headline stops naming a window the status cannot tell it: it now states only what holds
      for both limits and points at the reason line for which one it is.
- [x] The prose block above the step corrected -- it explained the outage as a session window only,
      which is the model that produced the wrong headline.
- [~] A test suite for the diagnostic -- dropped. Nothing in `scripts/tests/` covers this step (it is
      bash embedded in YAML, and `jq` is not on the dev machine), so a suite would mean building a
      harness for one workflow step. The step's own comments record that it was measured against a
      hand-built fixture, which is the convention already in place here.

### TEST

- [x] `bash -n` on the extracted step: syntax OK.
- [x] The changed `case` driven with the values the real run produced (`status=429`, the measured
      reason string): annotation and job summary now agree with each other. Before, the headline said
      session/clock and the reason said weekly/Aug 31.
- [x] Regression on the three branches this change does not touch -- `''`, `529` and a numeric
      fall-through -- all unchanged.
- [x] File still pure ASCII (`grep -P '[^\x00-\x7F]'` empty), as it was before the edit.

### DEPLOY: `fix/the-429-headline-names-the-wrong-window-v1`

The review check's failure annotation told the reader the wrong outage horizon. On a 429 it asserted a
**session** quota "which resets on the clock", while the reason string printed beside it in the same
annotation said `You've hit your weekly limit ... resets Aug 31, 7am (UTC)`. A subscription credential
draws on both a session window measured in hours and a weekly cap measured in days, both arrive as the
same 429, and nothing in the status separates them -- only the reason string does. So the headline was
guessing, and on the eight red runs of August 28, 2026 it guessed wrong by three days.

It now states only what holds for either limit -- out of quota, resets on the clock, a re-run does not
help -- and points at the reason line for which one it is and when it returns. The prose block above
the step is corrected in the same movement, because the session-only model it described is what
produced the headline.

That distinction changes what a reader does: told the window is a session, the reasonable move is to
wait a while and re-run, which on a weekly cap is three days of waste. Issue #1055 was filed against a
run whose log already carried the answer -- the second time this diagnostic has been read past, after
#966 -- so the defect being repaired is legibility, exactly as it was then.

**Score:** 3

#### What makes this deploy extra special

N/A -- `.github/workflows/claude-code-review.yml` is this repo's own CI and is not plugin payload, so
nothing here reaches a consumer of the marketplace.

**Score:** N/A

#### Pull Request

The quota annotation stops naming a window its own reason contradicts
