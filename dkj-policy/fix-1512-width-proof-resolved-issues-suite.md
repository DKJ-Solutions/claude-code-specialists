## fix/1512-width-proof-resolved-issues-suite

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

`verify-resolved-issues.tests.ps1` claimed an immunity its normalization does not provide; the claim
and the exposure are repaired in the four suites that share the pattern, and pinned by a guard

#### One correction to #1512, made before anything was built

The issue proposes reusing `Assert-Says` from `scripts/tests/verify-pushed-merges.tests.ps1`, calling
it "the repair, already written." **Neither exists** -- not on `main`, and not on the parked
`feat/1511-verify-resolved-on-merge` branch the issue was filed from, which creates
`verify-pushed-merges.ps1` but no suite for it. So the helper is written here rather than reused.

What the tree *does* already carry is `Test-OutputContains` in `shared-scripts.tests.ps1`, whose
comment records the same class from the other direction. Its call sites were read: all are
metacharacter-free, it already strips all whitespace, so that suite needed no change and is the fifth
of the five the issue names.

### CREATE

- [x] `Test-Says` / `Assert-Says` in `scripts/tests/verify-resolved-issues.tests.ps1` -- strips ALL
      whitespace from both sides and compares with `IndexOf` + `OrdinalIgnoreCase`: literal, so a
      phrase carrying `(`, `)`, `.`, `[` or `]` needs no escaping, and case-insensitive, so it is a
      faithful swap for the `-match` it replaces rather than a quiet tightening
- [x] The false comment replaced -- it named the wrap and then claimed normalization closed it
      ("no assert in this file CAN be width-fragile"). It now says what normalization is for (a
      readable failure line) and that the fix lives at the comparison
- [x] Same helper into `fix-mojibake`, `park-cycle` and `test-suite-gate`, and each one's own
      normalization comment corrected. Defined locally per suite, as `Assert-True` already is in 63
      of the 70 suites here -- these are dependency-free by design, and `fix-mojibake` sources no lib
      at all
- [x] 47 prose asserts converted: 5 in `verify-resolved-issues`, 9 in `fix-mojibake`, 24 in
      `park-cycle` (one of them a negative, via `Test-Says`), 9 in `test-suite-gate`
- [x] `fix-mojibake`'s `$lintOut` block also hardened -- that capture is *not* normalized, and its
      coverage regex would have read the gate as never having run if the line broke after `check`

### TEST

- [x] A guard scenario in `verify-resolved-issues.tests.ps1`, 5 asserts, and deliberately
      **synthetic**: the real wrap column is the child's buffer width, so a scenario that waits for a
      real wrap only fails on the machines where one lands inside the phrase -- which is how the false
      claim stayed believable. The first assert pins the defect itself (normalizing does NOT repair
      `declared no i` / `ssue to close`), the rest pin the repair, both directions
- [x] Mechanism confirmed against the tree before repairing, not taken from the report: a child's
      message arrived as `...so this is n` / `ot the same as...` on this checkout's own path, and
      `not the same as` matched nothing after normalizing while `Test-Says` found it
- [x] The conversion's own defect was caught by the suites: two `fix-mojibake` asserts carried regex
      escapes that a literal comparison then hunted for verbatim. Both unescaped; every converted
      phrase re-scanned for metacharacters
- [x] All four suites green -- `verify-resolved-issues` 36, `fix-mojibake` 38, `park-cycle` 84,
      `test-suite-gate` and `shared-scripts` (547) unchanged in count. Lint gate: 0 errors

### DEPLOY: fix/1512-width-proof-resolved-issues-suite

`verify-resolved-issues.tests.ps1` normalized its captured child output and stated, in as many words,
that this made it impossible for any assert in the file to be width-fragile. Collapsing runs of
whitespace repairs a wrap **between** words and does nothing for one **inside** a word, which is what
PowerShell's formatter produces -- it breaks at whatever character sits at the buffer column. The
comment was load-bearing: it is the reason no assert in four suites was ever written defensively.
The comparison now strips all whitespace, in the 47 places that read prose out of a child.

**Score:** 2

#### What makes this deploy extra special

The defect was a *comment*, and that is the whole of why it was worth an issue. Nothing was failing
when it was filed and nothing needed to: which asserts straddle a break is decided by the console
width, so every one of these suites was one checkout path or one terminal away from a red run that
looked like a bug in the script under test. A green suite was being read as evidence of safety by a
sentence that had promised it, and the promise was the only thing holding.

Two things the report got wrong were caught before they were built on, per this repo's own rule that a
finding's *reason* is verified and not just its symptom. Its proposed repair -- reuse `Assert-Says`
from `verify-pushed-merges.tests.ps1` -- names a helper and a file that exist nowhere; it was written
from a working copy that was never committed. And one suite it lists as needing the same read,
`park-cycle`, turned out to fail the *opposite* way: `Get-FlatOutput` deletes newlines rather than
collapsing them, so it survives a mid-word break and loses the space where the wrap consumed one. No
single substitution survives both, which is the argument for fixing this at the comparison instead.

**Score:** N/A

#### Pull Request

Width-proof the prose asserts, and drop a comment that promised an immunity
