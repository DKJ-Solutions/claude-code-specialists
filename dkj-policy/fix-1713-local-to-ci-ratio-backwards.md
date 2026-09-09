## fix/1713-local-to-ci-ratio-backwards

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

Replace the 3.6-4.0x-faster claim with both measured readings and the statement that the ratio is not
fixed.

#### The filing left the repair open on purpose, and this is the answer taken

#1713 declined to propose a replacement constant — *"n=1 solo on one suite is exactly the thin evidence
this issue is complaining about"* — and said whoever picked it up should decide between publishing a new
number and stating that the ratio is not a constant. **The second, and a third reading is what settles
it**: this session's own runs put the whole 85-suite pool at about **255s of wall clock on a 32-thread
machine at 30 lanes**, which agrees with neither the 18-thread workstation figure nor CI. Three readings
on three configurations is what *"not a constant"* looks like, so no divisor is published.

**The conclusion the old number supported is untouched and comes out stronger**, exactly as the filing
predicted: `record-suite-durations.ps1` refuses to pack CI from a workstation reading, and that refusal
needs no ratio at all — CI is a different machine, not a scaled one.

### CREATE

- [x] `scripts/lib/native-capture-lib.ps1`, both sites: the claim replaced by *there is no ratio to
      divide out and the sign is not fixed*, with both readings and the ~10x error a reader dividing by
      3.8 would make.
- [x] `scripts/maintenance/record-suite-durations.ps1`, both sites — its docstring and the `note` array
      it writes into every regenerated hints file.
- [x] `scripts/tests/suite-durations.json` — the note **already written** into the committed file, by
      hand. Checked first that nothing gates it: `ci-shard.tests.ps1` asserts the file parses and holds
      usable durations, and no test or lint holds the note text against the recorder's array, so the
      hand edit is safe and the next regeneration writes the same corrected words.
- [x] The two plugin mirrors, via `build-shared-scripts.ps1`. No hand edit.
- [x] **A site the filing did not list, and it is the one that used the ratio hardest**:
      `.claude/specialists/lenses/06-25-extension.md` — the same file #1713 cites as its evidence —
      states *"at their measured 3.6-4.0x local-to-CI ratio it predicts ~65s"*. So the evidence document
      carried both the new measurement and the old claim. The prediction is **left in place** with the
      correction beside it, because it is the worked example of the trap; what is added is that the
      conclusion it reached was independently settled by the recorded CI numbers, which that lens
      already says one section down.
- [~] Publishing a replacement constant — dropped, per the reasoning above.
- [~] The four archived release documents under `dkj-policy/releases/**` — out of scope by the history
      carve-out in [`.claude/rules/language-layers.md`](../.claude/rules/language-layers.md), as the
      filing itself noted.

### TEST

- [x] Every remaining `3.6-4.0x` in the tree, outside archived history, now sits **inside a sentence
      saying it was wrong** — the standing "recognise the old wording, write the new one" shape rather
      than a silent deletion.
- [x] `ci-shard.tests.ps1` 74 asserts and `native-capture.tests.ps1` 102 — the two suites that read the
      changed files — green after the hand edit to the hints file.
- [x] Lint gate: 0 errors, including the shared-scripts drift check that would refuse a mirror edited by
      hand.
- [x] The lint gate and every suite, via `open-pr.ps1`.

### DEPLOY: fix/1713-local-to-ci-ratio-backwards

A shipped lib, its recorder and the hints file that recorder writes all stated the local-to-CI suite
ratio as a fact — *"3.6-4.0x faster on a developer machine"* — and it was backwards. Measured: one suite
took **759.1s solo on an 18-thread workstation against a 290.9s mean over three 4-lane CI runs**, which
is 2.6x *slower*, and a third configuration agrees with neither. So there is **no ratio to divide out and
the sign is not even fixed**, and every site now says that instead of a number. A reader who trusted the
old sentence and converted a local figure by ~3.8 landed about ten times out.

**The conclusion it was there to support is unaffected and reinforced.** The reason `suite-durations.json`
is committed rather than written by the gate was never the size of the ratio: CI is a different machine,
not a scaled one, so its durations cannot be derived from a workstation at all.

**And the evidence document carried the old claim too**, which the filing had not caught — the
performance lens used the ratio to predict a suite's CI duration, in the same file that measured its
absence. The prediction stays as the worked example of the trap, with the correction beside it.

**Score:** 3

#### What makes this deploy extra special

A consumer receives the corrected docstring in `native-capture-lib.ps1` through both plugin mirrors, and
the hints note in their own regenerated `suite-durations.json` if they run the recorder. Nothing they run
behaves differently — the gate never read the number — but anybody sizing their own CI off a local run
was being told to divide by a figure that does not exist.

**Score:** 2

#### Pull Request

The local-to-CI suite ratio is not a constant, and it was stated backwards
