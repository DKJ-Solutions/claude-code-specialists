## fix/1736-says-classification-swept

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

#### What #1736 asked for, and what the measurement changed

The issue nominated **8** suites as satisfying both of #1728's conditions with no `Test-Says`, and left
**13** unresolved. It was explicit that the counts were candidate exposure and that the work was to read
each assert -- so the classification, not the conversion, is the deliverable.

Reading them changed the answer in both directions:

- **Four of the eight read no formatter-emitted phrase at all.** `gate-lib` starts no child process (its
  `2>&1` is on the fixture's own `git` calls); `fanout-lib`, `find-specialist-mentions` and
  `measure-always-on` assert only `Write-Host` / `Write-Output` text. Condition 2 holds in the *script*
  and fails at every *assert*, which is the distinction the issue itself drew.
- **A fifth was already repaired.** `verify-pushed-merges.tests.ps1` carries `Assert-Says` (14 uses) and
  no `Assert-Match` at all -- the row is stale, and #1530's own repair note sits in that docstring.
- **All thirteen unknowns resolve to zero.** Their scripts emit one or two formatter lines each, almost
  all on a `repo-config.ps1` load failure that no suite asserts; `check-plugin-integrity.ps1` and
  `check-git-identity.ps1` emit through the formatter not at all.
- **One suite the issue listed as UNKNOWN is the only genuinely exposed one:** `round-tally.tests.ps1`.

- [x] Read all 21 nominated suites against the tree rather than against the table
- [x] Resolve condition 2 per **assert**, tracing each phrase to its emitting call in the script
- [x] Measure the three flattener variants instead of ranking them by reasoning

### CREATE

#### The measurement that decided the shape of the repair

The tree holds three ways of flattening a captured child, and their docstrings disagree about which is
safe. Measured by padding a `Write-Error` until its break swept every column of a 120-wide render --
120 wrap positions x 4 phrases, 480 checks per variant:

| variant | in use by | failed |
|---|---|---:|
| collapse the break to a space | `find-specialist-mentions` | 68 / 480 |
| join the records with a newline | `round-tally` | 51 / 480 |
| join with nothing between them | `park-branch`, `worktree-lane`, `prune-merged`, `park-cycle`, ... | **0 / 480** |

The formatter breaks **inside a word** (`dirty working tre e`), so collapsing to a space cannot repair
the break it exists for. Joining with `''` reconstructs it exactly.

**So three of the four suites touched here were NOT letting anything through**, and this is a hardening
rather than a bug fix. Their immunity is incidental: joining with `''` survives a break that landed on a
space only because PowerShell keeps that space at the end of the line it wrapped -- a property of the
renderer that nothing here controls or tests. `Test-Says` needs neither property.

`round-tally` is the exception and the one real defect: it joins with a newline, `-match` is single-line
by default, and it had already met this in #1242 -- answered then by rejoining the lines at **one** call
site by hand, leaving two `Write-Warning` asserts beside it untouched. That hand-rolled form only ever
worked because the phrase it guarded was a single token.

- [x] `round-tally.tests.ps1` -- add the reader; convert the two `Write-Warning` sites and retire the
      bespoke per-site rejoin at case 6
- [x] `park-branch.tests.ps1` -- add the reader; convert the two refusal sites and the one negative
- [x] `worktree-lane.tests.ps1` -- add the reader; convert the five `Write-Error` sites
- [x] `prune-merged.tests.ps1` -- add the reader; convert the nine positive and two negative sites
- [x] Leave every `Write-Host` assert on `-match`, deliberately -- a whitespace-blind reader asserts
      strictly less, and destroys the line-structure asserts (`(?m)^\| v10 \| ...`)
- [x] Correct the three docstrings that described the wrong variant or the wrong exposure list

#### The negative direction gets its own helper

`Assert-DoesNotSay` sits beside `Assert-Says` in the two suites that need it rather than being spelled
`-not (Test-Says ...)` at the call site. A bare `-notmatch` on a formatter-rendered phrase reports
absence and may have measured a line break, so it goes **green for the wrong reason** and no run ever
shows it -- the shape has to be as easy to reach for as the positive one.

### TEST

- [x] All four suites green: round-tally 33, park-branch 31, worktree-lane 35, prune-merged 113
- [x] The conversion proven non-vacuous by measurement rather than by a green run -- a green run is
      exactly what a hardening produces, which is why the variant table above exists
- [x] Full lint + test gate before the PR

### DEPLOY: fix/1736-says-classification-swept

The `Test-Says` classification is now measured across every suite that captures a child's error stream,
and the reader is applied where an assert actually reads a formatter-emitted phrase. Four suites gained
it; the four #1736 nominated that read only `Write-Host` were measured and deliberately left alone, as
were all thirteen it left unresolved.

The classification is the durable half. It is recorded in Tycho's lens as two conditions that fail
independently, with the correction that matters: condition 2 is a property of the **assert**, not of the
script under test -- a script carrying twenty `Write-Error` calls says nothing about a suite whose
asserts all read its report. That distinction is what took the queue from 8 candidates to 1 real defect,
and it is what stops the next sweep from converting `Write-Host` asserts into weaker ones.

The three flatteners in the tree are now ranked by measurement rather than by argument, so the next
suite to be written can copy the one that measured 0 instead of the one whose docstring sounded most
confident.

**Score:** 3

#### What makes this deploy extra special

N/A -- test-suite internals. No consumer of this marketplace runs these suites or sees their output;
the scripts under test are unchanged.

**Score:** N/A

#### Pull Request

The whitespace-stripping reader reaches the four suites whose asserts read a formatter-emitted phrase
