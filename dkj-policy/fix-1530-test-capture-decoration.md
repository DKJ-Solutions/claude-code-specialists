## fix/1530-test-capture-decoration

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

Capture child output via redirect files instead of 2>&1, so a NativeCommandError block can no longer be inserted into the middle of an asserted phrase

#### What the report got right, and what it got wrong

#1530 reported the symptom exactly -- `FAILS: 1 failed, 47 passed` on a tree byte-identical to
`origin/main`, while CI on `main` was green. Both halves of its proposed reason are false, and were
checked before anything was repaired:

- *"the sha it names (`bbbb...`) is not one of the two commits `-Compare` returns"* -- `$ShaMid` **is**
  `'b' * 40`, so the fixture already names the commit the reporter thought was missing. Nothing about
  `$r12` needed changing.
- The implied conclusion that the fixture is wrong -- it is not. The script under test does exactly
  what it is specified to do, and emits the asserted sentence. The **capture** damages it afterwards.

### CREATE

- [x] `verify-pushed-merges.tests.ps1`: capture via `Invoke-NativeCapture -Utf8` (redirect files)
      instead of `& powershell ... 2>&1 | Out-String`
- [x] Correct the `Assert-Says` docstring, which claimed whitespace-stripping is immune to this class
      -- it is immune to a wrap, and cannot be immune to insertion
- [x] Add the capture guard: assert `NativeCommandError` is **absent**, which holds at every width and
      path length where a phrase-only assert does not
- [x] `verify-resolved-issues.tests.ps1`: same capture, same guard, and correct its
      "THE FIX IS AT THE COMPARISON" paragraph -- this is the suite the broken capture was copied from
- [x] Record the lesson in [Tycho #18's lens](../.claude/specialists/lenses/04-18-extension.md); it
      had lived only as a comment inside the one file repaired in August, which is why it recurred

### TEST

- [x] Both suites green on this checkout: 49 and 37 asserts
- [x] **Symptom reproduced**, by checkout path alone: a detached worktree at `C:\p` (script path 45
      characters) runs the *unmodified* suite and prints `FAILS: 1 failed, 47 passed` -- the reporter's
      line, on the same commit and the same machine as the green run
- [x] **Fix proven at the same path**: the repaired suite at that same 45-character worktree prints
      `OK: all 49 asserts passed`
- [x] Failing window measured at width 120: a script path of 29 to 51 characters. This repo's own path
      is 108, which is why it was green here and green on CI
- [x] Full lint + test gate

### DEPLOY: fix/1530-test-capture-decoration

`verify-pushed-merges.tests.ps1` failed one assert on a tree byte-identical to `origin/main` while CI on
`main` was green, and `open-pr.ps1` has no per-suite valve -- so on the affected checkout every branch
was pushed with the whole test gate off, or not at all. The suite is repaired, and the cause was neither
the fixture nor the script under test.

Both suites captured their child with `& powershell ... 2>&1 | Out-String`. Under `2>&1` the parent
re-renders the child's **first** stderr line as its own `NativeCommandError` and stamps the record
decoration -- `At <path>:<line>`, the source echo, `CategoryInfo`, `FullyQualifiedErrorId` -- *into* that
line at the cut. `Assert-Says` strips all whitespace, which repairs a **wrap**; it cannot repair
**insertion**, and the docstring claiming otherwise is corrected here. The parent renders
`<powershell.exe> : <full script path> : <message>` and cuts the whole of it at the console width, so the
verdict is decided by the checkout's path length and the terminal width -- neither of which is a property
of the code. Measured: green at this repo's 108-character script path, red at 45, same commit and same
machine; the failing window at width 120 is 29 to 51 characters.

Both suites now capture through `Invoke-NativeCapture -Utf8`, which starts the child with `Start-Process`
and redirected streams, so the parent's formatter never touches the child's stderr. Each gained one assert
that `NativeCommandError` is **absent** from the captured text: it can only appear there if a parent
rendered the stderr as an error record, so its absence pins **which capture ran** at every width and path
length -- where the phrase-only assert that was already there fails only where the cut happens to land
inside its phrase, which is how this stayed green on CI.

`verify-resolved-issues.tests.ps1` is changed without a failing assert to point at, deliberately: it is
where the broken capture was copied from, and "it passes here today" is a fact about one checkout rather
than a property of the file. The same reasoning put the lesson in Tycho's lens -- it existed only as a
comment inside `shared-scripts.tests.ps1`, repaired in August 2026, and the suite written after that
repair still copied the old capture from its sibling.

**Score:** 4

#### What makes this deploy extra special

N/A. Both files are this repo's own test suites; neither is mirrored into a plugin, and no shipped script
changes. A consumer sees nothing.

**Score:** N/A

#### Pull Request

Test capture: a parent's error-record decoration splits asserted phrases

