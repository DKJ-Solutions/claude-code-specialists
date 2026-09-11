## fix/1831-connector-swb-candidate

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

#### What this branch is

Inbound [#1831](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1831): none of the three
`localCheckout` candidates in `connectors/smartwatchbanden.json` resolves on a machine that lays the
BWJ trees out under `bwj-development/`, so `check-connectors.ps1` prints `[SKIP] checkout ... not
present on this machine`, exits 0, and suppresses that consumer's whole block.

The report arrived from another machine, and the symptom **reproduces on this one** -- so every
verification below is a measurement here rather than a reading of the report.

### CREATE

- [x] Verify the six ways an inbound report fails, against the tree rather than the report.
      Symptom: reproduced verbatim here (`[SKIP]` naming all three candidates, exit 0). Reason:
      confirmed in `check-connectors.ps1` -- the `[SKIP]` arm returns before any plugin block.
      Repair: `localCheckout` is read as a list, first-match-wins, relative-only
      (`scripts/sync/check-connectors.ps1`, the candidate loop), so an append is exactly the right
      shape. Size: one candidate. Subject: the manifest exists. Repo: the register lives here.
- [x] Confirm the consumer at `../../bwj-development/smartwatchbanden` is the tree this manifest is
      about -- its `origin` is `https://github.com/BWJ-Development/smartwatchbanden.git`, the live
      repo #1553 moved the `repo` field to, so arm 4 of the check matches rather than reporting a
      same-named tree.
- [x] Append `../../bwj-development/smartwatchbanden` to `localCheckout`. A pure append: the three
      earlier candidates stay for the machines they are true on.
- [x] Record the dated measurement in `notes`, per this register's convention, keeping every earlier
      sentence's original wording (#952).
- [~] Add a test. Dropped: this is a data correction to a register, not a change to the mechanism.
      The list-with-first-match behaviour is the code #1524 built and `connectors.tests.ps1` already
      covers; a test asserting that a particular string sits in a particular manifest would pin one
      machine's layout into the suite, which is the opposite of what the additive field is for.
- [x] Check `connectors/xoxowildhearts.json` in the same pass -- `../../bwj-development/` holds only
      `smartwatchbanden` here, so that connector's `[SKIP]` is a true absence and it is left alone.

### TEST

- [x] `check-connectors.ps1` with no override: the smartwatchbanden block now reports all five
      plugins, `Summary: 0 error(s), 0 info signal(s)`, and xoxowildhearts still skips correctly.
- [x] Measured what the false `[SKIP]` had been hiding, which #1831 filed as explicitly unmeasured:
      five plugins enabled, all registered extensions present (19 + 3 + 3 + 0 + 0), every machine
      record on v5.0.0. The suppressed block was entirely green -- the register was right about this
      consumer on every field; nobody could see that it was.
- [x] JSON validated after the edit.
- [x] Lint gate and all suites, via `open-pr.ps1`.

### DEPLOY: fix/1831-connector-swb-candidate

`connectors/smartwatchbanden.json` records a fourth `localCheckout` candidate,
`../../bwj-development/smartwatchbanden`, so a machine laying the BWJ trees out that way checks that
consumer instead of skipping it. Before this, `check-connectors.ps1` asserted the checkout was absent
and exited 0, suppressing five plugin blocks, their extension inventories and their version drift --
the silent class #1524 named and #1807 repeated, one machine further.

The append is pure: `localCheckout` is first-match-wins and additive, so the three earlier candidates
keep working on the machines they are true on. #1807's note had anticipated this entry, guessed it as
`bwjdevelopment/` and deliberately declined to record an unobserved layout; the real folder is
hyphenated, so that guess would have been wrong -- which is the argument for the rule rather than
against it.

**Score:** 3

#### What makes this deploy extra special

N/A -- the connector register is this repo's own maintenance bookkeeping. A consumer of the
specialists system neither reads it nor is affected by it; what changes is what a maintainer's own
`check-connectors` run can see on one machine.

**Score:** N/A

#### Pull Request

Record the bwj-development/ layout as a smartwatchbanden connector candidate
