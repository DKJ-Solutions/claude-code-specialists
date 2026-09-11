## fix/1838-runid-repo-root-shape

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

Both parameters of `record-suite-durations.ps1` are positional, so under `powershell -NoProfile -File`
a space-separated `-RunId` list binds its second id to `-RepoRoot`, which then fails as a missing path
-- an error that names neither `-RunId` nor the comma form the script actually expects (#1838). Fix at
the point of the mistake: document the comma form and refuse the run-id-shaped `-RepoRoot` by name.

### CREATE

- [x] Add a `.PARAMETER RunId` note stating the comma-separated form for `-File` callers.
- [x] Guard `-RepoRoot` against a run-id shape (`^\d{6,}$`) and throw naming the comma form with the
      caller's own values.

### TEST

- [x] Reproduced the issue's exact repro (`-RunId 34583187104 34583740147 -DryRun`) -- now throws
      naming `-RunId` and the comma form, instead of a bare "Cannot find path" from `Resolve-Path`.
- [x] Verified the comma form (`-RunId "34583187104,34583740147" -DryRun`) is unaffected by the new
      guard and proceeds into the script's existing logic.
- [x] Parsed the file with `[System.Management.Automation.Language.Parser]::ParseFile` -- no syntax
      errors.
- [~] No dedicated Pester suite added -- no maintenance script in `scripts/maintenance/` carries one
      today, and this is a docstring + a guard clause on an already-manual tool.

### DEPLOY: fix/1838-runid-repo-root-shape

`record-suite-durations.ps1` now refuses a run-id-shaped `-RepoRoot` by name instead of failing deep
inside `Resolve-Path` with no mention of `-RunId`, and its docstring states the comma-separated form
the script actually expects for several run ids under `-File`.

**Score:** 1 -- a docstring clarification and an error-message fix on a script only a session invokes
by hand; it prevents a failure that costs a minute of re-diagnosis, nothing more.

#### What makes this deploy extra special

N/A -- an internal maintenance-script fix, not visible to a subscriber of any service this repo ships.

**Score:** N/A

#### Pull Request

record-suite-durations.ps1: space-separated -RunId binds second id to -RepoRoot

