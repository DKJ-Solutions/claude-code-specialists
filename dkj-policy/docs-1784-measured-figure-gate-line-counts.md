## docs/1784-measured-figure-gate-line-counts

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

#### What #1784 actually asked for

The issue proposes a new lint check -- a sentence naming a repo file and giving a line count for it,
held against that file's actual length -- and then names its own precondition under **Not measured**:
*"it needs the count before it is worth building."* This repo's convention is that a candidate rule is
measured against the tree before it is adopted, and several rules in this same gate were **declined** on
exactly that evidence. So the assignment is the measurement first, and the check only if it survives.

It did not survive. The deliverable is therefore the recorded decline plus the one real defect the
measurement found -- not the check.

#### One correction to the report, which does not change its subject

#1784 calls the gate **check 13**. Check 13 is the changelog-entry check; the `[measured-figure]` gate it
describes is **check 16**. Its line citation is exact -- `$figurePattern` is at
`check-plugin-integrity.ps1:2426` -- so the subject exists and the report is routable; only the number is
wrong.

### CREATE

- [x] Measured the candidate over every tracked `.md`/`.ps1` outside the archived release history, in two
      variants (wide, and narrowed to require a word boundary before the digit), pairing each count with
      the nearest file token to its left and resolving by path then basename, against a +/-5% band.
- [x] Recorded the decline with the full measurement in Sylvester's lens, beside the stale-path rule it
      had to be measured against -- the five false classes, the pairing failure, the mandatory tolerance
      band, and check 16's own docstring argument that settles it.
- [x] Recorded the confirming instance in Tessa's lens: her portable rule *"a re-derivable figure states
      its method"* already covers #1779 and needs nothing added -- so the lens states that no gate backs
      it for line counts, and why the measurement is the cleanest confirmation of the rule it has.
- [x] Repaired the one real defect the measurement found -- `06-25-extension.md:264`, a present-tense
      `CLAUDE.md` "is 875 lines in 9 sections" against 526 in 3 -- by tense plus the method to re-derive it.
- [~] No check built and no test suite added. That IS the finding: 16 findings, 1 real. A suite would pin
      a rule this branch declines.

### TEST

- [x] The lint gate and all suites, via open-pr's own pre-flight.

### DEPLOY: docs/1784-measured-figure-gate-line-counts

The proposed line-count gate from #1784 is **declined on measurement**, and the measurement is recorded
where the gate's other declined rules live. Extending check 16 (`[measured-figure]`) to line counts
produces 16 findings across the trunk of which exactly **1** is a real defect: six sites are deliberate
historical records where the figure is the point, four are deltas rather than lengths, one is a section
rather than a file, two describe another repo's files, one is history that already carries the binding
check 16 asks for, and one is a pairing failure whose victim is the best-behaved figure in the tree -- a
comment that states its own `wc -l`. That figure went stale by a line during this branch's own
eight-commit fast-forward, which is why a tolerance band is mandatory and why a line count is something a
reader re-runs rather than something a gate pins. And writing this decline up, with each instance cited
verbatim as a measurement here must be, took the same rule from 16 findings to 26 -- so it penalises
measuring and recording the result, which is what the gate's other rules exist to encourage. Check 16's
unit list stays byte-shaped, deliberately, and the writing rule that does hold this class already exists
in Tessa's portable manual. The one real defect the measurement found is repaired.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing here reaches a consumer. The declined rule, its measurement and the repaired figure are all
this repo's own maintenance prose; no plugin payload, script or manifest changes.

**Score:** N/A

#### Pull Request

Record the measurement that declines a line-count figure gate, and the writing convention behind it

