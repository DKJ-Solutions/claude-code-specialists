## fix/1586-fold-on-merge-stale-trunk-deferral

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

#### What #1586 measured, and where its stated mechanism is wrong

The symptom stands: `Fold on merge` run `34206684361` went red at 2026-09-08 08:50:42Z on
`Refused: this checkout is 1 behind origin/main, so nothing was folded.`

The report's mechanism does not. It says *"the run's checkout predates that merge"* -- the checkout
resolved `main` to `e8ca4cb7` (`merge: fix/1572-lane-ship-queue-trunk-holder (#1576)`) at 08:50:31, so
#1576's merge WAS in the tree; that is why `check-unfolded-entry.ps1` found its leftover. What landed
in the eleven seconds between the checkout and the fold was #1576's *fold* (`54fa5d7a`), pushed by the
shipping session. The guard therefore refused on an entry that had already been folded -- exactly the
#1405 duplicate it exists to prevent, not a conservative over-reach.

The report's second claim is wrong the same way: run `34206711452` did not "fold #1572 cleanly". It
was triggered *by* that fold commit, found nothing on the trunk, and skipped the fold step.

#### So the repair is the report's second shape, on the argument #1543 already made

`ref: main` exists (#1543) so the run answers *"does the trunk carry a leftover NOW"*. A trunk that
moved between the checkout and the fold has changed what "now" means, so this run's answer is stale
and it should stand down -- the push that moved the trunk triggers its own run, whose checkout is
at-or-after it. Nothing is lost: the trunk-gap refusal fires in a pre-pass **before anything is
folded**, so a deferral is provably lossless within the run.

Fetch-and-ff-only (the report's first shape) is declined: it narrows the window from ~11s to ~1s
without closing it, which leaves the guardrail red *rarely* -- a worse state than predictably red,
and the same fourth self-healing mode the issue objects to.

#### The signal is an exit code, not a matched sentence

The workflow already reads two phrases out of these scripts' stdout. A third would put the deferral
contract on prose that crosses a plugin release boundary (the script mirrors to
`plugins/dkj-policy/scripts/release/`) and a template boundary (`adopt-merge-queue.ps1`). So the
stale-trunk refusal gets its own exit code -- still non-zero, so every other caller (`ship-pr`, a
person) is unchanged -- and the workflow keys on that.

### CREATE

- [x] `scripts/release/fold-changelog-entry.ps1`: the trunk-gap refusal exits 2 rather than 1, with the
      reason stated at the refusal -- a per-push caller can tell it apart and stand down
- [x] `.github/workflows/fold-on-merge.yml`: the fold step translates exit 2 into a deferral (exit 0
      with a note naming the successor run), and its header stops claiming the trunk-gap guard is
      "unreachable here" -- #1586 is the run that reached it
- [x] `scripts/task/adopt-merge-queue.ps1`: the same two changes in the consumer template
- [x] re-mirror the shared fold script into the plugin (`scripts/sync/build-shared-scripts.ps1`)

### TEST

- [x] `scripts/tests/fold-changelog.tests.ps1`: the stale-trunk refusal is pinned at exit code 2, the
      `-SkipTrunkCheck` valve still folds, and no other refusal path leaks code 2
- [x] `scripts/tests/workflow-concurrency.tests.ps1`: `fold-on-merge.yml` translates exit 2 and only
      exit 2, and still fails on every other non-zero code
- [x] `scripts/tests/adopt-merge-queue.tests.ps1`: the template carries the same translation
- [x] the lint gate and all suites green

### DEPLOY: fix/1586-fold-on-merge-stale-trunk-deferral

The `Fold on merge` CI job no longer goes red when two merges land within seconds of each other. Its
checkout reads the trunk once, and the fold's trunk-freshness guard measures the same trunk again about
eleven seconds later -- so a second merge in that gap left the job refusing on an entry another actor
had already folded. The guard was right and the trunk ended correct; only the red was wrong, and it
described a state that was gone by the time anybody opened it.

That refusal now carries its own exit code -- `2`, the only thing in `fold-changelog-entry.ps1` that
returns it -- and the job stands down green on that code alone, naming the reason in the log. Every
other non-zero code still fails it, so the three real ways the job goes red are untouched. Nothing is
lost by standing down: the guard fires in a pre-pass before a single entry is folded, and the push that
moved the trunk queues its own run of the same job behind this one. The consumer template in
`adopt-merge-queue.ps1` places the same behaviour, and both workflow headers stop claiming -- as
#1543's repair did -- that `ref: <trunk>` puts that guard out of reach.

**Score:** 3

#### What makes this deploy extra special

A consumer who has adopted the CI floor gets a fold runner that stops crying wolf, and the guidance
that goes with it: a `Stood down:` line in the log is the job working rather than a fold that went
missing. `git fetch` + `--ff-only` before the fold was the obvious alternative and is declined in
writing -- it narrows the window without closing it, which leaves the guardrail red *rarely*, and a
guardrail that is wrong rarely is the one nobody reads.

**Score:** 2

#### Pull Request

fold-on-merge stands down on a trunk that moved under it, instead of going red
