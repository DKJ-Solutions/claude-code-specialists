## fix/1786-stale-test-docstring

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

#### What #1786 reported, and what verifying it added

The report says `scripts/tests/connector-sessioncheck.tests.ps1`'s header claims branches 1 and 2
drive the hook against **this repo's own root copy** of `plugin-versions.ps1`. Verified in the code
and it stands: `$Hook` is the plugin mirror's hook file, the hook has exactly one engine candidate
(`$PSScriptRoot/../scripts/task/plugin-versions.ps1`), so the engine actually measured is
`plugins/dkj-policy/scripts/task/plugin-versions.ps1`. The `$cwd` candidate the header describes was
removed on review, and the hook's own comment argues at length for having dropped it.

Two things the verification added to the report:

1. **The report named one passage; there are three.** `Invoke-Hook`'s own docstring repeats the
   abandoned resolution word for word ("the hook's engine search reads (Get-Location)"), and
   `Invoke-IsolatedHookNoEngine`'s says "BOTH of the hook's candidates" where there is now one.
   `Invoke-HookWithFakeEngine`'s docstring is already correct and records the change itself, which
   is why the header reading the other way went unnoticed.
2. **The push to `$RepoRoot` is inert, not merely misdescribed.** Every scenario passes
   `-WorkshopPathOverride`, which replaces the `$cwd` candidate list outright, and the version
   branch returns before the consumer scoping reads `(Get-Location)` at all. Saying it "is kept
   because the hook still reads (Get-Location)" would have been a second unverified reason in place
   of the first, so the docstring says it is inert belt-and-braces and says so explicitly.

#### Size: a docstring, and the mechanism left alone

The report's gate claim was checked rather than taken: check 8 of `check-plugin-integrity.ps1`
raises `[shared-script] ... deviates from ...` on a stale mirror, and `open-pr.ps1` runs the lint
before the suites. So the gate cannot be fooled by an unbuilt mirror and the window is the
standalone run only -- which is exactly the run a session makes while editing the engine, so the
ordering is worth naming in the docstring rather than building against.

### CREATE

- [x] Header docstring: name the mirror as the engine branches 1 and 2 measure, and state the
      rebuild-before-standalone ordering with #1786's own measurement (47/0 then 41/6)
- [x] `Invoke-Hook`: replace the abandoned `(Get-Location)` resolution with the mirror, and say the
      push is inert rather than inventing a reason for it
- [x] `Invoke-IsolatedHookNoEngine`: one candidate, not both
- [x] Swept the file for the remaining stale spellings ("root copy", "first candidate", "BOTH")

### TEST

- [x] `connector-sessioncheck.tests.ps1` standalone: **47 pass, 0 fail** -- unchanged, as a
      docstring-only repair must be
- [x] Pure ASCII confirmed (repo convention for `.ps1`, check 27)
- [x] Full lint + suites via `open-pr.ps1`

### DEPLOY: fix/1786-stale-test-docstring

`connector-sessioncheck.tests.ps1`'s header said its first two branches drive the hook against this
repo's own root `scripts/task/plugin-versions.ps1`. They drive the plugin mirror beside the hook --
the `$cwd` candidate that once made the header true was removed on review. The docstrings now name
the mirror, and state the consequence the wrong name hid: after editing the source engine, rebuild
the mirror before running this suite standalone, or it reports on the previous version and says
nothing about having done so.

A test suite's own account of what it measures was wrong, and it cost one session a false all-clear
(47/0 against an unrebuilt mirror, then 41/6 from the same suite once it was rebuilt). Small because
the gate was never exposed to it -- the drift check errors on a stale mirror before the suites run,
so only a standalone run could be fooled. Noticed the moment somebody edits `plugin-versions.ps1`
and reaches for this suite.

**Score:** 2

#### What makes this deploy extra special

A docstring inside this repo's own test suite. Nothing here ships, and no consumer reads it.

**Score:** N/A

#### Pull Request

connector-sessioncheck.tests.ps1's header names the mirror it actually drives

