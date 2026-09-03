## Development: `fix/asana-mirror-concurrency-drops-state-event` · 20260903-135958

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

Repair the shipped bwj-codex asana-mirror.yml concurrency block per issue #1301: split the per-issue
group by what the arrival can lose, and pin it in the bwj-codex suite.

#### What the report got right, and the half it got wrong

The report's **mechanism** stands, and it is #1294's: a concurrency group holds at most one
in-progress run plus one *pending* run, and a third arrival drops the waiting one without consulting
`cancel-in-progress` at all. Measured on this system's own `ci.yml`, where the dropped runs had zero
jobs allocated -- so they never left the queue rather than being killed mid-flight.

Its **consequence** does not. *"A dropped middle event is a lost card move"* is false: `Invoke-EventMode`
derives the move from `Get-IssueLinkState`, which reads the issue's state, labels and project status
**live at run time** rather than from the event payload, and the script says so in its own comment
(`asana-mirror.ps1`, above the `Resolve-TargetStage` call). The last arrival of a burst always runs, so
the card converges on where the whole burst put it and a dropped label event costs nothing.

What is actually lost is narrower, and in one place **worse** than the report says. `closed` and
`reopened` are keyed on `-Event`, not on live state:

- a dropped `closed` loses its Asana comment, recovered within a day by reconciliation sweeps (a)/(b),
  which de-duplicate -- this is the backstop the report credits;
- a dropped `reopened` is **not backstopped at all**. No sweep comments on a reopen, and line 1392 is
  the only place `-Reopened` is set, which is the only thing that grants `AllowBackward` while every
  sweep moves a card forward only. So it loses the 'hold off on testing' notice permanently *and*
  leaves the card stuck at its forward floor.

So the report's own reason for filing it as not urgent -- *"it has a genuine backstop"* -- holds for
`closed` and fails for `reopened`.

#### Why the group is split rather than dropped

The report's first open question was whether per-issue serialisation is wanted at all, or whether each
delivery should be its own group. Neither extreme is right here. Per-delivery would let a `closed` run
and a `reopened` run on one issue race, and they write in opposite directions -- one moves the card
forward from a closed state, the other backward from a reopened one, and whichever finishes last wins
regardless of which event happened last. A single shared group is what drops them. Splitting the key by
what the arrival can lose keeps both properties: label events still coalesce (correct -- their target is
recomputed), while `closed`/`reopened` get a queue a triage burst cannot reach into, and still serialise
against each other.

### CREATE

- [x] Verify the report against the tree before repairing it -- symptom, reason, proposed repair, size,
      subject, repo. The reason survived; the stated consequence did not (see PLAN above).
- [x] Split the concurrency key in `plugins/workflows/bwj-codex/templates/asana-mirror.yml`, and rewrite
      the comment above it to say which arrivals are expendable and which are not -- the report's second
      open question.
- [x] Pin the split in `scripts/tests/bwj-codex.tests.ps1`, beside the existing assertions over the
      workflow text.

### TEST

- [x] `scripts/tests/bwj-codex.tests.ps1` -- 192 asserts pass, including the four new ones.
- [x] Negative check: the two asserts that carry the fix were run against the pre-fix group text and
      both return false, so they can fail. The per-issue assert stays true on both, which is its job --
      it guards that the split did not throw the per-issue keying away.
- [x] Lint gate + all suites (`check-plugin-integrity.ps1`), via `open-pr.ps1`.

### DEPLOY: `fix/asana-mirror-concurrency-drops-state-event`

`asana-mirror.yml`'s concurrency key is now split into two groups per issue instead of one, so a burst
of label events on an issue can no longer drop a pending `closed` or `reopened` run. `cancel-in-progress`
was never what protected them: a group holds one in-progress run plus one *pending* one, and a third
arrival drops the waiting one without consulting that field -- the mechanism measured on this repo's own
`ci.yml` in #1294. `labeled`/`unlabeled` keep the shared per-issue group and coalesce, which is correct
for them: their card move is recomputed from live state, so the last arrival of a burst lands the card
where the whole burst put it. `closed`/`reopened` get a group of their own, because their comment is
keyed on the event and a dropped one is a comment nobody ever posts -- and a dropped `reopened` is
unrecoverable, since no sweep comments on a reopen and the reopen is the only thing that grants a
backward move. The comment above the block now names which arrivals are expendable, and the bwj-codex
suite pins the split.

**Score:** 3

#### What makes this deploy extra special

A consumer running the Asana mirror keeps a reopen notice that could previously vanish without trace:
no red run, no failed check, just a `cancelled` run nobody investigates and a card left in the wrong
column. The daily reconciliation sweep never covered this one -- it comments only on closed issues and
only ever moves a card forward.

**Score:** 3

#### Pull Request

asana-mirror's concurrency group is split, so a triage burst can no longer drop a pending close or reopen
