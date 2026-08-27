## Development cycle: `docs/review-429-tally-needs-no-count-v1` · 20260827-180541

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

Issue #974: replace the 'all FOUR of its red runs' tally in .github/workflows/claude-code-review.yml with a maintenance-free conditional, and stop claiming THE ONE CAUSE for the one run whose log carries no diagnostic.

### CREATE

- [x] Recount the red runs from the logs rather than from the comment, so the repair rests on a
      measurement of its own: 19 red runs in total, 16 of them after the diagnostic step landed
      (`eabc9c00`, 2026-08-26 12:24 UTC). Issue #974 measured 13 at the time of filing.
- [x] Replace the tally in `.github/workflows/claude-code-review.yml` with a conditional that needs
      no maintenance, and record inside it why no number is written.
- [x] Move the one unattributable run (32984348328) out of the absolute claim and into its own
      paragraph, as unknown rather than as a second cause.

### TEST

- [x] The count in the issue was re-measured before the repair, and it had already moved: 13 -> 16 in
      one day. That is the finding's own evidence, so it is stated in the comment.
- [x] `check-plugin-integrity.ps1` + all suites, via `open-pr`'s gate.
- [x] No automated test exists for a YAML comment's prose and none is proposed -- a test asserting the
      absence of a number would pin wording, which is the thing this repair is trying to stop pinning.

### DEPLOY: `docs/review-429-tally-needs-no-count-v1`

The comment above `claude-code-review.yml`'s **Why the review failed** step no longer counts this
workflow's red runs. It said the 429 hit `all FOUR of its red runs`; there were thirteen when issue #974
read the logs and sixteen a day later, when this branch re-measured them before repairing. Wrong by
roughly 3x when it was typed, and wrong again before anybody could correct it -- which is the argument
for a condition rather than a correction: **every red run whose log carries this diagnostic has named
429.** That sentence stays true on the next one. The count was load-bearing, though, and the comment now
says so: four occurrences across two days reads as an oddity, sixteen reads as *most PRs opened in a busy
window get no review*, which is the actual behaviour a reader needs.

**Score:** 2

#### What makes this deploy extra special

**The one run that could not be attributed is now outside the sentence rather than contradicted by it.**
Run 32984348328 reports `conclusion: failure` while its job carries `conclusion: null` and an empty
`steps` array, and `--log-failed` returns nothing -- so the diagnostic never ran and the 429 claim has
nothing to rest on there. Under `THE ONE CAUSE` that run was a silent counter-example. Under a
conditional it is simply out of reach, and the comment says which run and why, so the next reader who
finds it does not re-open the question.

**This is the second time this repo has repaired a tally by deleting it rather than correcting it.**
`CLAUDE.md` already records the first -- a count of Dave's own name, written inside the document that
carries the name, wrong when typed and wrong again after the next edit. Same shape here: a count of a
workflow's red runs, inside the workflow that produces them. The repair is deliberately the same one,
and the comment names the lesson so the pattern is legible rather than coincidental.

**Score:** N/A

#### Pull Request

the review workflow's 429 note states a condition instead of a count that goes stale