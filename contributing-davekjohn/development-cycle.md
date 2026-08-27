## Development cycle: `fix/record-count-assert-counts-what-it-claims-v1` · 20260827-200440

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

Issue #999: the assert enforces a floor of 29 and explains it as 'the twenty-eight below plus Get-LiveStage', while the table below has 23 rows and the lib has ~36 records. Decide the floor as well as the prose -- seven records of slack means a record can be deleted without the guard noticing, which contradicts the message's own claim that a retired record forces a conversation.

### CREATE

- [x] Re-measure with the assert's OWN regex rather than a loose grep, because the two disagree: the
      regex matches **36** records in `scripts/lib/script-contract-lib.ps1`, and there are 36 `Returns`
      lines beside them. The `$expectedContract` table below the assert holds **23** rows.
- [x] Decide the floor as well as the prose. `-ge 29` becomes `Assert-Equal 36`.
- [x] Rewrite the message so it says what it counts (the lib) and states the other number (the table)
      instead of conflating the two, keeping the record-by-record history that was already there.

### TEST

- [x] `script-contract.tests.ps1`: **293 pass, 0 fail** with the exact assert in place.
- [x] **The assert was proven to bite before it was trusted.** One record (`Get-ReleaseMajorMinMinors`)
      was retired from the lib and the suite re-run: it fails with `expected: '36' got: '35'`, along with
      the two asserts that name that record. Restored from git and back to 36 and green.
- [x] **And the old floor is proven not to bite**, which is the finding: at 35 records `-ge 29` passes.
      Seven records could have gone, one at a time, with nothing turning red -- while the comments in the
      table promise that a retired record forces the count assert to change.
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr`.

### DEPLOY: `fix/record-count-assert-counts-what-it-claims-v1`

The contract drift guard's record-count assert enforced a floor of **29** and explained it as *"the
twenty-eight below plus the dedicated Get-LiveStage block"*. Neither number was real: the lib holds 36
records and the table below the assert holds 23, so the arithmetic described neither set. It is
`Assert-Equal 36` now, against the lib, and the message says so -- with the table's own count stated
beside it rather than folded into the same sentence.

**Score:** 2

#### What makes this deploy extra special

**The slack was the defect, not the prose.** Seven records of headroom meant a record could be deleted
and the guard would say nothing -- measured, not argued: with `Get-ReleaseMajorMinMinors` removed the lib
has 35 and `-ge 29` still passes. That contradicts what the table's own comments promise twice, that a
retired record *"would have to change the count assert too, which is the conversation that should
happen."* A floor cannot force a conversation in either direction; an equality does, and the message now
says to change the number in the same commit and name which record moved.

**The two numbers were never the same set, and the old sentence made them look like one.** The lib's
records are what the check reads; `$expectedContract` is what this test pins by name. 36 and 23, with
`Get-LiveStage` asserted separately after the loop -- so the test file names 24 of the 36 and the rest
rest on the `Returns` assert alone. Stating that plainly is worth more than the count it replaces: it
tells the next reader which records are actually guarded by name.

**Score:** N/A

#### Pull Request

the contract record-count assert counts what it claims, and stops explaining a floor with arithmetic that never matched