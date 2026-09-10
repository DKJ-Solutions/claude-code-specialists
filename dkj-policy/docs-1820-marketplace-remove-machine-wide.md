## docs/1820-marketplace-remove-machine-wide

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

#### The decision this branch had to make first

#1820 filed the defect and deliberately left the repair shape open — two candidates, "worth Dave's
word or at least a considered decision rather than a side effect". Put to Dave, who chose **keep the
order and state the consequence once**: the three sequences are unchanged, so a reader following one
section top to bottom (the common case) is unaffected, and the multi-checkout reader gets one measured
block plus a pointer from each step 3. The rejected option was hoisting `marketplace remove` out of
the per-checkout sequence, which serves the multi-checkout reader better and breaks the single-section
reader's pasteable block.

### CREATE

- [x] `INSTALL.md`: one new `## If this machine has more than one checkout` section above the three
      migration sections, carrying the record counts, both verbatim CLI failure messages, the
      per-checkout sequence step 3 decomposes into, and the bounds of the measurement.
- [x] `INSTALL.md`: a pointer in the step-3 comment block of all three migration sequences, saying the
      command is machine-wide and naming the section to read first. Placed inside the fence, which is
      where the reader is standing when it matters.
- [x] Sylvester's **portable** manual: the mechanism as a hard rule beside its sibling (the
      settings.json round-trip rule), pointing at `INSTALL.md` for the numbers rather than restating
      them. Portable and not the lens, because it is a property of the CLI rather than a fact about
      this repo — the source-is-the-default rule in `CLAUDE.md`.
- [x] Verified the report before repairing it: all three sequences still carry step 3 inside a
      per-repo procedure, and `INSTALL.md` had just moved upstream (442a250b) without touching them.
- [x] Filed the sibling finding rather than widening this branch:
      [#1823](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1823) — `UNINSTALL.md`'s
      Step 5 carries the same machine-wide reach, and there nothing reinstalls afterwards. Its repair
      is a procedural decision of its own, not a sentence.
- [x] Sharpened the instruction after Sebastian's review, which asked whether a checkout skipping
      step 3 is left with a stale marketplace source key. It would have been: `marketplace remove` and
      `marketplace add` do **not** share a reach, and the first draft treated step 3 as one step and
      told later checkouts to start at step 4. `remove` is per machine; `add --scope project` writes
      into the repo it is run in — which this page states about that flag two sections down — so it is
      owed to every checkout. The section and all three fence notes now say skip the `remove`, run the
      `add`. This is a better repair than the one #1820 proposed, and it came from the review rather
      than from the report.

### TEST

- [x] Lint gate + all suites via `open-pr.ps1`, which validates the new in-page anchor under GitHub
      slug rules (check 4) and holds every printed `claude plugin` command to its flags (check 6).
- [~] No automated test added. Dropped: the deliverable is prose in two documents, and the checks that
      can hold it — anchors, dead links, install-command flags — are the lint gate's already and run
      over these files unchanged.

### DEPLOY: docs/1820-marketplace-remove-machine-wide

`INSTALL.md`'s three migration sequences now say that step 3's `claude plugin marketplace remove` is
machine-wide over install records, and a new section states what that means for a machine with more than
one checkout. It also splits step 3, which is two commands with two different reaches: `remove` drops the
registration for the whole machine and is run once, while `marketplace add … --scope project` writes the
source key into the repo it is run in and is owed to every checkout. So the first checkout runs the whole
sequence and each one after it skips step 2 and the `remove`, then runs the `add` and step 4. The section
carries the measured record counts, both of the CLI's failure messages verbatim — the second reads as a
`--scope` mistake by the operator and is not one — and the bounds of what was measured. The same
mechanism is now a hard rule in the system administrator's portable manual, so it travels to every
consumer rather than living only on this page.

Before this, a reader with three checkouts was told by the page's own per-checkout framing to run the
sequence three times, and the first run silently made steps 2 and 3 impossible in the other two — with
two error messages that name a missing plugin or the wrong scope rather than the cause.

**Score:** 3

#### What makes this deploy extra special

A consumer migrating more than one checkout hits this on the second one, and the page gave them a red
error at a step its own step 3 had already made impossible. Nothing was broken on their machine and the
CLI's wording says otherwise. It is a procedure repair on the page consumers are told to follow, so it
reaches anyone still to migrate.

**Score:** 3

#### Pull Request

State that marketplace remove ends the other checkouts' migration
