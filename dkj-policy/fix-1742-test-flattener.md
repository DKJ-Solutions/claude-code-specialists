## fix/1742-test-flattener

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

#### What #1742 asked for, and what verifying it turned up

The issue reports that `find-specialist-mentions.tests.ps1` carries the one flattener variant #1736
measured to fail (collapse the break to a space -- 68 of 480), and that it is safe today only because
no assert in it reads a formatter-emitted phrase. Both halves verified against the tree before any
edit: the substitution is at line 62, the script under test reaches the error stream exactly once
(`Write-Error`, line 75), and every one of the 31 asserts reads `Write-Host` output.

**The issue's inventory was one copy short**, and the copy it missed is the exposed one.
`shared-scripts.tests.ps1` collapsed the break **inline at a call site** rather than in a named
helper, so a search for `Get-FlatOutput` could not see it -- and its three positive asserts read an
`open-pr` **`Write-Warning`**, which is the formatter path the 68-in-480 was measured on. So this
branch carries a hardening and a repair, and says which is which.

- [x] Verify #1742 against the tree: the variant, the emitter of every phrase asserted, and the single
      `Write-Error` in the script under test.
- [x] Search for the *substitution* rather than the helper, which is what found the second copy.

### CREATE

- [x] `find-specialist-mentions.tests.ps1`: join the records with `''` (the 0-of-480 variant), and
      replace the docstring, which cited two suites that use neither substitution.
- [x] `shared-scripts.tests.ps1`: route the three near-miss placeholder asserts and the negative
      assert beside them through the existing `Test-OutputContains`, and record why the comment that
      argued for collapsing is wrong.
- [x] `prune-merged.tests.ps1`: append to the inventory, whose closing sentence this branch moves --
      no suite is on the failing variant now. The dated measurements above it are left as written.
- [x] Tycho's lens: the top row is out of the tree, and the three-part lesson from the second copy.

### TEST

- [x] `find-specialist-mentions.tests.ps1`: 31 passed, 0 failed.
- [x] `shared-scripts.tests.ps1`: all 660 asserts passed.
- [~] No new assert. A `Test-Says`-style refusal assert would be the thing to add, and adding one is
      what the issue names as the *alternative* repair -- the two positive asserts it would need do not
      exist in that script, which reaches the error stream once with a message no assert reads.
- [x] Full gate: lint + every suite, via open-pr.

### DEPLOY: fix/1742-test-flattener

The one flattener variant measured to drop wrapped phrases is out of the test tree. Two copies were
found where the issue named one: the second, in `shared-scripts.tests.ps1`, was typed inline at a call
site and was genuinely exposed -- its asserts read an `open-pr` `Write-Warning`, and the negative
assert beside them would have reported "no warning on the ordinary path" for a warning that was
printed and merely wrapped mid-word. Nothing was failing before this change, which is the point: the
silence sat where the next assert anyone added would have inherited it.

**Score:** 2

#### What makes this deploy extra special

N/A -- a test-suite flattener reaches no consumer of this marketplace. The suites are green before and
after; what changed is what a future assert inherits.

**Score:** N/A

#### Pull Request

Match find-specialist-mentions.tests.ps1 to the flattener variant that measured zero failures

