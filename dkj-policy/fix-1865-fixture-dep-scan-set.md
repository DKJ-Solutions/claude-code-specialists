## fix/1865-fixture-dep-scan-set

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

#### What #1865 reported, and what was verified before repairing it

The report's symptom holds: `Get-FixtureDepReport` built its scan set with
`Get-ChildItem -Filter '*.tests.ps1'`, and `scripts/tests/check-plugin-integrity-fixture.ps1` is not
named that way. Two of its figures were re-measured rather than taken:

- It says the builder copies **eight** libs. It copies **fourteen** -- so the blind spot is larger
  than reported, not smaller. Nothing in the repair turns on the number.
- It leaves as **not measured** whether the three `.measure.ps1` files in that directory copy a lib.
  Measured here: none of them contains `Copy-Item` at all. That is what decides the repair, because
  it means widening the filter is born green rather than born red -- the state this repo requires of
  a new gate (the stale-path check, declined at 124 findings all false).

#### Which of the three options, and why

Option 1, widen the filter. Option 2 -- follow each suite's own dot-sources, so a builder is reached
because a suite *loads* it -- is strictly more correct and strictly more code, and buys nothing this
tree can measure today; it is recorded in the lib as the repair to reach for on the day a builder
moves out of `scripts/tests`. Option 3, do nothing, is what #1860's branch already measured: the four
lint suites do go red, in four unrelated files, with no line naming the cause.

### CREATE

- [x] `scripts/lib/fixture-dep-lib.ps1`: scan set widened from `*.tests.ps1` to `*.ps1`, with the
      measurement and the declined option recorded on `Get-FixtureDepReport`.
- [x] The vocabulary follows the scan set: `Suites` -> `Files` on the report, `-SuitePath` -> `-Path`
      and the finding's `Suite` -> `File` on `Get-FixtureDepFinding`. A subject is a file that copies a
      lib, of which a suite is the common case -- the shared builder is not one.
- [x] `scripts/tests/fixture-lib-deps.tests.ps1`: call sites, header and section heading follow.

### TEST

- [x] `fixture-lib-deps.tests.ps1` green: 26 asserts, 97 files read, 13 subjects (was 12), 0 findings.
- [x] Three new asserts, because every existing figure is a threshold and a threshold cannot notice
      the non-suite files leaving the scan set again: the report's file count is compared against what
      the directory actually holds, that the directory still holds a non-suite `.ps1` at all, and the
      builder by name.
- [x] The gate proved to BITE for the builder, not merely to read it: with a temporary uncopied
      sibling added to `seam-lib.ps1` (a lib the builder copies), the report went from 0 findings to 8,
      three of them naming `check-plugin-integrity-fixture.ps1` and walking the closure -- exactly the
      shape #1860's branch produced. Reverted; `git diff` on that lib is empty.
- [x] The four `check-plugin-integrity-*` suites and the full lint + test gate.

### DEPLOY: fix/1865-fixture-dep-scan-set

The fixture dependency gate reads every `.ps1` under `scripts/tests` instead of only the files named
`*.tests.ps1`, so the fixture builder that four lint suites share is now a subject rather than the one
blind spot in a gate built to prevent exactly its failure mode. On #1860's branch that gate reported
seven findings, was right about all seven, and the four lint suites died on lib load anyway.

**Score:** 3

#### What makes this deploy extra special

N/A -- a test gate in this repo's own tree. No subscriber of anything reaches it, and it ships in no
plugin payload.

**Score:** N/A

#### Pull Request

The fixture dependency gate reads every file under scripts/tests, not only the suites
