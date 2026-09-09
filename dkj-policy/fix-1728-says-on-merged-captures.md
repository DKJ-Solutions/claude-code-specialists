## fix/1728-says-on-merged-captures

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

#### What was measured before anything was changed

#1728 reports 358 `Assert-Match` sites across 8 suites and calls that "the exposure, not the defect
count". Measured, the exposure is far smaller, and the report's own sentence is what points at why.

A capture can only carry a wrapped phrase when **two** conditions hold together:

1. the capture carries the child's **error stream** -- `2>&1`, a `StandardError.ReadToEnd()`
   concatenated onto stdout, or `Invoke-NativeCapture` without `-DiscardStderr`, which merges err into
   `Output`; and
2. the script under test emits the **asserted phrase** through the formatter -- `throw`, `Write-Error`
   or `Write-Warning` -- rather than `Write-Host`, which does not go through it at all.

| suites | sites | condition 1 | exposed |
|---|---:|---|---:|
| `roster-sync`, `connectors`, `script-contract`, `sync-roster`, `adopt-workflow-folder`, `config-blueprint` | 311 | **no** -- stdout only | **0** |
| `cut-release-drive` | 4 | yes | 0 today, structurally reachable |
| `publish-to-business` | 13 | yes (`2>&1`) | **3** |

The six are immune **by construction rather than by luck**: each captures stdout only -- checked
against `2>&1`, `StandardError` and `Invoke-NativeCapture` alike -- from a script with zero `throw`,
`Write-Error` and `Write-Warning`. Converting them would have been 311 edits with no defect behind any
of them.

Condition 2 is what takes `publish-to-business` from 13 to 3, and the reason is worth knowing:
the script deliberately `Write-Host`s its problem list and folds only the COUNT into the `throw` --
*"PowerShell renders a multi-line error message on one line, and the whole point of this check is that
you can read the list."* So a phrase can be formatter-free even where the failure that produced it was
a `throw`.

The three that really are exposed all read a `throw`: `Get-BusinessMarketplaceRepo`,
`missing the required field 'plugins'` and the unmatched keep-list name. They pass today on the width
of this checkout's console and nothing more.

#### Why there is no tree-wide gate

37 suites here satisfy condition 1. A gate demanding `Test-Says` of all of them would be born with 33
findings, nearly all about `Write-Host` phrases that cannot wrap -- the false-positive rate this repo
already turned down once, in the stale-path check declined at 124 findings. Condition 2 is what
separates them and it cannot be read off a suite: it lives in the script under test, one process away.

### CREATE

- [x] `Test-Says` + `Assert-Says` added to the two suites that satisfy condition 1, in the established
      shape, each carrying a docstring saying why THIS suite needs it and most do not.
- [x] `Assert-DoesNotSay` in `publish-to-business.tests.ps1` for the negative direction, which is the
      one worth having: a positive assert that straddles a break goes red on a correct script, while a
      negative one goes **green for the wrong reason** -- it reports absence and has measured a line
      break. There the whitespace-stripping test is the stricter of the two.
- [x] 18 call sites converted there and 4 in `cut-release-drive.tests.ps1`; the regex escapes and two
      `[regex]::Escape(...)` wrappers went with them, since the comparison is literal now.
- [x] One `Assert-Match` deliberately kept, with the reason written beside it: its pattern is a real
      regex (an interpolated fixture path), and its phrase is `Write-Host`-fed, so it cannot wrap.
- [x] `cut-release-drive`'s `Assert-Says` takes `($Phrase, $Text)`, matching `Assert-Match` in **that
      file** rather than the other suites' `($Text, $Phrase)`. Both parameters are strings, so a
      mismatch between neighbours is a silent swap rather than an error, and the neighbour is what a
      reader copies from. The deviation is stated at the function.
- [x] The classification written into [Tycho's lens](../.claude/specialists/lenses/04-18-extension.md),
      beside the capture rule it completes. Before this the mechanism was recorded seven times -- once
      in each suite already repaired -- and nowhere a person writing an eighth suite would look, which
      is the actual reason the class kept recurring.

### TEST

- [x] `publish-to-business.tests.ps1`: 69 asserts pass.
- [x] `cut-release-drive.tests.ps1`: 45 asserts pass.
- [x] Lint gate and the full suite gate via `open-pr`.

### DEPLOY: fix/1728-says-on-merged-captures

The two test suites whose capture carries the child's error stream now read it with `Test-Says`, which
strips whitespace from both sides and compares literally -- so a phrase the error formatter hard-wrapped
mid-word is still found. 22 asserts converted across `publish-to-business.tests.ps1` and
`cut-release-drive.tests.ps1`, including the negative direction, where the old form went **green for the
wrong reason**: it reported absence and had actually measured a line break.

The other six suites #1728 named are left exactly as they are, and that is the finding rather than a
shortcut. A wrapped phrase needs two conditions together -- a capture that carries the error stream, and
a script that emits the asserted phrase through `throw`/`Write-Error`/`Write-Warning` rather than
`Write-Host`. Those six capture stdout only, from scripts with none of the three, so they are immune by
construction; 311 of the report's 358 sites had no defect behind them. What made the difference
measurable is written into the test engineer's lens beside the capture rule it completes, because the
mechanism had until now been recorded only inside the seven suites already repaired -- where nobody
writing an eighth would find it.

**Score:** 3

#### What makes this deploy extra special

Nothing here ships to a consumer: both files are this repo's own test suites, and the lens is
repo-local. A consumer's own suites are subject to the same mechanism, and the rule that now describes
it lives in a lens rather than in the portable manual -- so this reaches them only if the classification
is later promoted.

**Score:** N/A

#### Pull Request

Read merged child captures with Test-Says where the error formatter can reach them
