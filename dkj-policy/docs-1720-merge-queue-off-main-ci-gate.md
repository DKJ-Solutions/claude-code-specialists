## docs/1720-merge-queue-off-main-ci-gate

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

#### What #1720 reports, and what was verified before anything was written

`CLAUDE.md` carried a forward-looking conditional -- *"Taking the `merge_queue` rule off `main-ci-gate`
is a ruleset change and therefore Dave's own act, so read the queue as live here until he has made it"*
-- on the always-on path. The act has happened, so the sentence handed every session the wrong answer
about how a merge lands here.

Verified before editing, rather than taken from the report:

```
$ gh api repos/DKJ-Solutions/claude-code-specialists/rulesets/19008062 --jq '[.rules[].type]'
["deletion","non_fast_forward","required_status_checks"]
```

`ship-pr.ps1` reads the trunk's rules itself (`Get-MergeQueueVerdict`, `ship-pr.ps1:570`) and folds in its
own step 5 (`ship-pr.ps1:2390`), so nothing mechanical was misled -- the defect is a session's reasoning.

#### The scope is wider than the reported line, and deliberately so

The report names `CLAUDE.md` only. The **same fact** is stated as current in
`.claude/specialists/lenses/05-15-extension.md`, whose September 6 block records the ruleset as holding a
fourth rule and teaches a reader to expect a **two-line** push rejection. That is the same measurement on
the same ruleset id, so repairing one and leaving the other stale in the same branch would be the
inconsistency this repo files issues about. Both are repaired here; the September 6 block is kept rather
than rewritten, because run 34020828593's two-line refusal still needs explaining.

#### What is deliberately NOT touched

The conditional clause further down `CLAUDE.md` -- *"while the merge queue is live on `main-ci-gate`"* --
stays exactly as written. It qualifies a mechanism against whatever trunk the reader has, so it is
correct here and correct in a consumer that does run a queue. #1720 asks for it to be kept, and the
reasoning holds on re-reading.

### CREATE

- [x] `CLAUDE.md`: replace the forward-looking conditional with the measured state, pointing at the two
      lenses rather than carrying the measurement on the always-on path
- [x] `05-15-extension.md`: a dated successor block -- the list is back to three -- plus the reason every
      block there prints its command (a ruleset is GitHub-side state no gate reads)
- [x] `06-16-extension.md`: the writing lesson, in Tessa's own lens -- what to write instead of a
      conditional whose flip nothing in the repo will notice

### TEST

- [x] `gh api .../rulesets/19008062` re-run against the live ruleset, so the repair rests on a measurement
      and not on the report
- [x] `ship-pr.ps1` read for the two claims the new prose makes about it (the queue verdict is read before
      the merge; step 5 folds)
- [x] lint gate + full test suites (`open-pr.ps1` runs both), which is where the dead-link scan holds the
      two new relative links and their anchors

### DEPLOY: docs/1720-merge-queue-off-main-ci-gate

The always-on `CLAUDE.md` told every session to *"read the queue as live here until he has made it"* --
and he had. Measured September 9, 2026: `main-ci-gate` holds
`["deletion","non_fast_forward","required_status_checks"]` and no `merge_queue`. The sentence is replaced
by the state that holds, so a session now reasons correctly about how a merge lands here: `ship-pr.ps1`
merges directly and folds in its own step 5, rather than enqueueing and waiting for `fold-on-merge.yml`.

**Nothing mechanical was ever misled, which is what makes this shape dangerous.** `ship-pr.ps1` reads the
trunk's own rules before it merges, so no gate failed and no merge went wrong -- only a reader's model of
the repo. An always-on document is uniquely able to cause that and uniquely unable to report it.

**The same fact was stale in a second place, and is repaired in the same move.** Sylvester's lens recorded
the ruleset as holding a fourth rule and taught a reader to expect a two-line push rejection; it now
carries the dated successor showing three, with the September 6 block kept intact so an old run stays
explainable. The generalisable half went to Tessa's lens: **a conditional in always-on prose needs a
detector behind it, or it is written as the dated state instead** -- and the removal above has no date of
its own, because a ruleset is GitHub-side state that no commit records, no gate reads and no session is
told about.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches a subscriber. All three files are this repo's own governance and lens layer -- `CLAUDE.md`
and two `.claude/specialists/lenses/` documents -- none of which ships in a plugin. A consumer's own
merge-queue conditional is untouched, deliberately.

**Score:** N/A

#### Pull Request

Record that the merge_queue rule is off main-ci-gate
