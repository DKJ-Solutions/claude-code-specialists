## Development: `fix/guard-coverage-comment-counts` · 20260903-162433

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

Issue #1321. The coverage assert in `../scripts/tests/source-repo-guard.tests.ps1` tested for the
source-repo guard with a whole-file `-notmatch` on the lib's *name*, so a **comment** naming the lib
satisfied it. Replace that with a check on the file's parsed syntax, and declare the exemptions the old
check let through.

#### What the issue got right, and the one thing it undercounted

The reported symptom holds exactly as filed -- verified before anything was changed:
`scripts/lint/check-unfolded-entry.ps1` is a registered non-`LibOnly` entry point, is absent from
`$guardExempt`, does not load the guard, and its only occurrence of the string is line 60, prose.

**It names one instance where there are two.** `scripts/task/park-cycle.ps1` is the same case, on the
same registry, for the same reason -- a hook invokes it from the plugin, so a refusal would fire every
turn -- and its guard sentence also happens to name the lib, in its `.DESCRIPTION`. Measured across all
25 registered entry points: 20 genuinely wired, 3 declared exempt, and **2 passing on prose alone**.
That does not change the repair, only its scope: both exemptions are declared here.

#### The control case, which landed on the trunk mid-branch

PR #1322 (issue #1315) merged while this branch was open and added `scripts/lint/check-git-identity.ps1`
to the same `$guardExempt` block -- the one conflict this branch had, resolved by keeping both. It is
worth more than a merge note, because it is the **control** that makes #1321 legible: same class of
script, same hook-invoked reason, and its exemption **was** argued here the way the block intends. The
only difference is that its "no guard" comment does not happen to name the lib, so the old text match
fired on it. Same reason, opposite outcome, decided by comment wording alone. Both are now declared, and
under the new matcher neither could have slipped through in the first place.

### CREATE

- [x] `Get-GuardWiringGap` in `../scripts/tests/source-repo-guard.tests.ps1`: answer what a file is
      missing from its **parsed syntax** instead of its text -- the lib named in a *string literal*, and
      an actual `Assert-OwnCopy` **call**. The parser hands back commands and string literals and never
      comments, so the wording that used to buy a pass buys nothing.
- [x] Both halves, each reported separately, because each is a real mistake on its own: a lib loaded and
      never called is a guard that cannot fire (the "correct but not wired in" shape this coverage block
      was added for in #897), and a call with no lib is a crash on the first run.
- [x] The lib is looked for in a string literal rather than in the dot-source's own extent, because
      every guarded script loads it through `$guardLib`. Anchoring on the dot-source would have reported
      all twenty guarded scripts as unguarded.
- [x] Declare the two exemptions the old check let through -- `scripts\lint\check-unfolded-entry.ps1`
      (SessionStart, #1270) and `scripts\task\park-cycle.ps1` (Stop, #900) -- each with the hook that
      invokes it, beside the two that were already there. Neither script's code changed: it was right all
      along, and only the bookkeeping was missing.
- [x] Assert the half of the exemption-reality comment that was asserted nowhere. That block already
      claimed an exemption for a script "that has since gained the guard" is a licence nobody is using,
      while the loop only checked the file exists and is registered. `Get-GuardWiringGap` makes it one
      line, so the paragraph is now true rather than aspirational.
- [x] `../scripts/README.md`: the bullet said "exactly two exceptions" and named them, which this branch
      makes wrong at five. Replaced with the reason class (hook-invoked) plus a pointer to the list in
      the suite, rather than a fresh count of four -- the page's own opening says it "deliberately states
      no count", and the test block says the list is "named here and nowhere else", so re-enumerating was
      the staleness both had already warned about.

### TEST

- [x] The suite: **37 of 37 asserts pass**, up from 28. The three new matcher asserts and the third
      exemption-reality assert per entry account for the difference.
- [x] **The negative proof, which is the one that matters.** A scratch copy of the suite with the two new
      exemptions removed fails the coverage assert and names both scripts with the reason:
      `NOT WIRED IN: scripts\task\park-cycle.ps1 (never names the lib outside a comment, and it never
      calls Assert-OwnCopy); scripts\lint\check-unfolded-entry.ps1 (...)`. Under the old text match the
      same copy was green. The scratch copy was removed; it was deliberately not named `*.tests.ps1`, so
      it could not have joined the gate had it been left behind.
- [x] The matcher is held to catching #1321 by three asserts of its own, and it has to be: no real file
      exercises the comment case any more, because all five scripts that would are skipped as exempt
      before the matcher is reached. A regression back into a text match would otherwise leave the suite
      green and silent -- precisely how the defect survived the first time. They run *before* the
      coverage assert, since a broken matcher makes its verdict meaningless in either direction.
- [x] The 20 genuinely guarded entry points still pass, which is the risk the other way: a matcher
      anchored on the wrong thing would have reported the whole repo.
- [x] The full lint + test gate, as CI runs it.

### DEPLOY: `fix/guard-coverage-comment-counts`

The coverage assert in `../scripts/tests/source-repo-guard.tests.ps1` -- the one holding every registered
shared entry point to carrying the source-repo guard -- tested for the guard by matching the lib's **name**
anywhere in the file. A comment naming the lib therefore counted as having the guard, including a comment
explaining why the guard was deliberately left out. It now reads the file's **parsed syntax**: the lib named
in a string literal, and an actual `Assert-OwnCopy` call, each reported separately so a guard that is loaded
but never fired is caught as well. Two registered entry points had been passing that assert on prose alone --
`scripts/lint/check-unfolded-entry.ps1` and `scripts/task/park-cycle.ps1`, both hook-invoked, both correct in
their code -- and their exemptions are now declared with the hook that earns each one. The same helper closes
a second gap in the same block: it already claimed an exemption for a script that has since gained the guard
is a licence nobody is using, and never checked it.

**Score:** 2

Inside this repo the defect cost no breakage -- it cost the argument. The block's own comment says the
exception list is named there "and nowhere else" because "a page can go stale in silence, a failing assert
cannot", and for these two scripts the assert never fired, so nobody had to argue the exemption. The larger
half is that the assert was weaker than it reads for *every* entry point, not only the two that tripped it:
a script that genuinely should carry the guard passed as long as any comment mentioned the lib. Nothing
changes for anyone until the next entry point is registered -- which is when it now gets held to the rule
rather than to its comments. Above cosmetic because the guardrail's coverage was real and unmeasured;
below tier 1 because nothing that shipped was ever wrong.

#### What makes this deploy extra special

`scripts/tests/` is source-only -- no test suite is mirrored into any plugin, so nothing here reaches a
consumer through a release. The two scripts whose exemptions are declared *are* mirrored, but neither
changed: only this repo's bookkeeping about them did.

**Score:** N/A

#### Pull Request

The guard-coverage assert no longer counts a comment as the guard
