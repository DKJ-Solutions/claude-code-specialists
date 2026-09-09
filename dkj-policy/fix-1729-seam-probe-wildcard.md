## fix/1729-seam-probe-wildcard

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

#### What was measured before anything was written

`Get-Command <name> -ErrorAction SilentlyContinue` is the frame that faulted in #1723, but the fault
has one sighting and never reproduced -- so the branch rests on two things that reproduce on any
machine instead. Windows PowerShell 5.1.26100.9444, 19 `PATH` entries, 2000 probes per cell:

| | `Get-Command` | `GetCommands(name,'Function',$false)` |
|---|---|---|
| seam **defined** (hit) | 0.135 ms | 0.038 ms |
| seam **absent** (miss) | **32.523 ms** | 0.084 ms |

The miss is the case that matters and it is the common one: an optional seam is absent by default,
and `Get-Command` answers a miss by scanning all 19 `PATH` directories for an executable of that
name, with nothing caching the negative. `sync-main.ps1` runs 10 such probes in a row and
`build-release-notes-page.ps1` 8 -- a third of a second of directory scanning per run in a repo that
has answered none of them, which is every fresh consumer.

Second, the name is parsed as a **pattern**: with `Get-Weird[x]` defined, `Get-Command 'Get-Weird[x]'`
returns nothing, reading the brackets as a character class. No seam here is named like that, so this
fixes no live bug -- it is the cheap, reproducible evidence that the replaced idiom really does go
through the wildcard machinery #1723 faulted inside.

Two alternatives were measured and rejected rather than reasoned about:
`$ExecutionContext.InvokeCommand.GetCommand($n,'Function')` throws on a miss and costs 78.5 s per
20000 probes against 0.5 s; `Test-Path Function:\<n>` is correct and 2.5x slower, going out through
the provider stack to reach the same table.

#### The count in #1729 is low, and the correction is part of this branch

The issue counted 68 probes. That is the **bare-name** spelling only; the same idiom also appears as
`Get-Command -Name <n> -ErrorAction SilentlyContinue` and with the name in a variable. The true
surface on `main` is **102**. 93 of them are converted here; the 9 that remain each carry a stated
reason -- 4 are external-command probes (`gh`, `git`), where `Get-Command` is not the expensive way
to ask but the only one that answers about `PATH`.

### CREATE

- [x] `scripts/lib/command-probe-lib.ps1` -- `Test-FunctionDefined`, one definition, registered in
      `Get-SharedScriptPairs` with three mirrors (`dkj-policy`, `dkj-team-shopify`, `dkj-team-alpha`)
      because `entry-scaffold-lib`, `native-capture-lib`, `seam-lib` and `check-roster-sync` all
      travel to consumers and all call it.
- [x] 93 call sites converted, all three spellings. The 4 external probes are left
      alone, and the one site reading `.ScriptBlock.File` off the `CommandInfo` keeps `Get-Command`
      with the reason written beside it -- a boolean cannot carry that answer.
- [x] Loader ordering audited per file rather than assumed: 4 files called the helper *before* any
      lib defining it was dot-sourced, and 11 more had no loader at all. All 15 fixed at an
      AST-computed insertion point, since `param()` must stay the first statement.
- [x] `Get-SeamValue` itself stopped being an inline probe -- `seam-lib.ps1` is the function this
      repo tells callers to use instead of `Get-Command`, so it was the one that most had to.
- [x] Plugin mirrors regenerated (28 updated) and the `shared-scripts:mirror` table given its row.

### TEST

- [x] New suite `scripts/tests/command-probe-lib.tests.ps1`, 16 asserts: every scope a caller can be
      in, the deliberate narrowing (a cmdlet and an alias are not functions), the literal-name
      proof, degenerate input, and a tree-wide **AST** gate so the idiom cannot come back. The gate
      reads the parse tree and not the text, because the old idiom is quoted as history in two
      docstrings that must not be rewritten.
- [x] The gate caught two conversion defects during the branch, which is the argument for having it:
      a `$null -ne (Test-FunctionDefined ...)` left behind by a mechanical rewrite -- always true,
      so the assert would have passed forever -- and a fixture `Copy-Item` whose destination filename
      had silently not been swapped, which would have overwritten `native-capture-lib.ps1`.
- [x] `fixture-lib-deps.tests.ps1` green: it reported all 20 fixture gaps the new lib dependency
      created, and all 20 are closed.
- [x] `check-plugin-integrity.ps1` green (0 errors).
- [x] Full suite gate run.

### DEPLOY: fix/1729-seam-probe-wildcard

The optional-seam probe stops going through PowerShell's command searcher. `Test-FunctionDefined`
(`scripts/lib/command-probe-lib.ps1`) reads the function table directly, and 93 of the 102 call sites
that used `Get-Command <name> -ErrorAction SilentlyContinue` now call it instead. #1729 counted 68 of
those, having counted one of the three spellings; the other 9 keep `Get-Command` with a reason each.

The reason is the **miss**, which is what an optional seam normally is: `Get-Command` answers one by
scanning every `PATH` directory for an executable of that name, measured at **32.5 ms** against
**0.084 ms** for the replacement, with nothing caching the negative. `sync-main.ps1` makes 10 such
probes in a row and `build-release-notes-page.ps1` 8, so a consumer that has configured no seams was
paying roughly a third of a second per run to be told "no" -- a cost that fell hardest on the repos
that had answered the least. The same call is also the frame that faulted in #1723, and it parses the
name it is given as a wildcard pattern rather than as a literal; neither of those is what the change
rests on, and both are recorded with the evidence in the lib's own docstring.

Probes for an EXTERNAL command (`gh`, `git`) deliberately keep `Get-Command` -- it is the only call
that answers about `PATH` -- and a tree-wide AST gate in the new suite holds the line, with each
exception named and reasoned rather than listed.

**Score:** 3

#### What makes this deploy extra special

A consumer gets this through the plugin mirrors, and the saving lands hardest on them: the miss path
is the default state of a repo that has answered no optional seams, which is every fresh adoption.
Nothing they run changes shape -- same output, same exit codes, same seams -- so there is nothing to
migrate and nothing to re-read.

**Score:** 2

#### Pull Request

Probe the function table directly, off the command searcher's wildcard path
