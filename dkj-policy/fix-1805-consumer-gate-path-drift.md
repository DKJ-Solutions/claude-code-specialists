## fix/1805-consumer-gate-path-drift

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

Guard the emitted path against a move here, and detect a stale one already written into a registered consumer.

#### What the report got right, and the two places it did not

Verified against the tree before anything was written. The symptom stands: `plugins/workflows/` is gone
from `origin/main` and only `plugins/dkj-policy/scripts/lint/check-branch-entry.ps1` exists. Two
corrections:

- **The subject is three runners, not one.** `adopt-merge-queue.ps1:173` builds the same hard-coded
  prefix for `fold-on-merge.yml` and `verify-resolved.yml`. Repairing only `branch-entry.yml` would
  have left two thirds of the class standing.
- **Option 1 cannot do what the issue claims for it.** "The only one that repairs the two repos that
  are red today without anyone visiting them" is not true of a scaffolder: it writes once, and their
  files are already written. The issue admits this two paragraphs later. Nothing in a scaffolder can
  reach an August adoption, which is why the repair is split across both ends.

And the mechanism behind the five weeks is sharper than reported: `adopt-merge-queue.tests.ps1:202-206`
pins the emitted path as a **literal string**, so it compares the scaffolder's output against itself
and stayed green through the move. `adopt-workflow-folder.tests.ps1` had no assertion about its runner
at all -- not that it lands, not that its script exists.

### CREATE

- [x] `scripts/lib/consumer-runner-lib.ps1` -- `Get-SharedScriptReference` (which scripts of this tree
      a workflow reaches into, read from the file's own `repository:`/`path:` pair) and
      `Test-SharedScriptReference` (does each still exist here, and where did it go).
- [x] `check-connectors.ps1` check 6 -- per registered consumer, every `.github/workflows/*.yml`
      judged; a path this tree no longer holds is an `[ERROR]` naming the file, the line and the
      current location. This is the half that reaches an already-adopted consumer.
- [x] Both scaffolder comments and `adopt-dkj-policy/SKILL.md` -- the `ref: main` argument, which
      weighed the entry's path moving and never the script's. Plugin mirror regenerated via
      `build-shared-scripts.ps1`.

### TEST

- [x] `connectors.tests.ps1` scenario 12 (a-e): current path silent, retired path an error naming the
      new location, an old-owner citation still caught, another repository ignored, an unknown script
      name reported as removed rather than moved. 255 pass, 0 fail.
- [x] `adopt-workflow-folder.tests.ps1` and `adopt-merge-queue.tests.ps1`: the emitted paths are now
      **derived from the emitted file** and asserted to exist in this tree. 100 and 76 asserts, 0 fail.
- [x] `check-plugin-integrity.ps1`: 0 errors.
- [~] A verification of the two red consumers -- dropped: neither is checked out on this machine and
      `gh` here has no access to them, so the reported state is taken as reported. The mechanism is
      what was verified instead.

### DEPLOY: fix/1805-consumer-gate-path-drift

Three CI runners this workflow scaffolds do not vendor the script they run: they check this repository
out beside the consumer's tree and run a path into it. The dependency therefore points the wrong way --
a path INTO this tree, written into a file this tree cannot reach, by a scaffolder that runs once at
adoption -- and when `plugins/workflows/contributing-davekjohn/` became `plugins/dkj-policy/`, two
consumers went red on every pull request for five weeks with nothing anywhere saying so.

Both ends are now held. `check-connectors.ps1` reads the runners a registered consumer actually has and
reports a path this tree no longer holds, naming where that script went; and the two scaffolder suites
derive the emitted path from the emitted file instead of pinning it as a literal, so a move here goes
red the day it lands rather than in somebody else's repository five weeks later. The `ref: main` pin
stays and its argument is completed: tracking the tip protects a consumer from a stale convention and
exposes them to a moved script, and only the first half was ever written down.

**The detector reaches a consumer whose checkout is present on the machine running it, which is the
register's standing limit rather than a new one** -- an absent checkout is `[SKIP]`, as it is for every
other check there. Filed as #1808 rather than widened here, because reading a consumer's workflow over
the network would put a `gh` call per connector into a script SessionStart runs.

**Score:** 3

#### What makes this deploy extra special

A consumer running these runners gets the failure class reported instead of discovered: either from
the register, or -- if they pin a tag instead -- from a page that now states the trade honestly. Nothing
changes for a consumer whose paths are current, which is most of them.

**Score:** 3

#### Pull Request

A consumer's CI runners no longer break silently when a shared script moves here

