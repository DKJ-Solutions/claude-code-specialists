## Development: `fix/native-capture-grandchild-handle-race-v1` · 20260902-201606

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

- [x] Confirm the mechanism from #1252 against the tree: `Invoke-NativeCaptureUtf8`'s timeout path
      kills the process tree, then waits on the direct child only, then reads `out.txt` with
      `[System.IO.File]::ReadAllText` -- which opens `FileShare.Read` and throws when a killed
      grandchild still holds the inherited stdout handle. Verified at
      `scripts/lib/native-capture-lib.ps1:370,372`.
- [x] Pick the repair. Took the issue author's lean -- repair 1 (shared read): smallest change,
      never throws, and a possibly-truncated tail is the honest answer for a killed tree.

### CREATE

- [x] Add `Read-NativeCaptureFileText` to `scripts/lib/native-capture-lib.ps1` -- opens the capture
      file via `FileStream` with `FileShare.ReadWrite`, decodes with the caller's encoding.
- [x] Route both capture reads in `Invoke-NativeCaptureUtf8` through it, and note at the bounded-wait
      comment why the read tolerates a lingering handle rather than waiting longer.
- [x] Mirror to the plugin copies: `scripts/sync/build-shared-scripts.ps1` (team-alpha workflow +
      team-shopify).

### TEST

- [x] New assert block in `scripts/tests/native-capture.tests.ps1`: hold a real writer handle open
      with `FileShare.Read`, assert the plain `ReadAllText` throws (the bug) and
      `Read-NativeCaptureFileText` returns the flushed bytes. `native-capture.tests.ps1`: 60 pass, 0 fail.
- [x] Lint gate green (`check-plugin-integrity.ps1`, 0 errors -- incl. check 27 script-ascii),
      shared-scripts drift check green, `shared-scripts.tests.ps1` green.

### DEPLOY: `fix/native-capture-grandchild-handle-race-v1`

`Invoke-NativeCaptureUtf8` read its capture files with `[System.IO.File]::ReadAllText`, which opens
`FileShare.Read`. On the timeout path the whole process tree is force-killed but the wait afterwards
is on the direct child only, so a grandchild that inherited the redirected stdout handle can still
hold `out.txt` when the read runs -- and `ReadAllText` then throws "being used by another process"
instead of returning the partial output. The window is wall-clock, so it was invisible locally and
lost the race on the slower CI runner, turning an unrelated branch's `lint-en-tests` red with a suite
name that had no relationship to its diff. The reads now go through a new `Read-NativeCaptureFileText`
that opens `FileShare.ReadWrite`: it coexists with the lingering handle and returns whatever was
flushed, which for a killed tree is the honest answer. A regression assert in
`native-capture.tests.ps1` holds a writer handle open for real and checks both halves.

**Score:** 3

#### What makes this deploy extra special

The fix ships to consumers through the shared `native-capture-lib.ps1` mirror. A consumer whose
`ship-pr` makes a bounded `git push`/`git fetch` that stalls and is force-killed on a slow machine
would otherwise get an unrelated `IOException` in place of the timeout diagnosis the bound exists to
give them.

**Score:** 2

#### Pull Request

native-capture's bounded read tolerates a killed grandchild still holding out.txt
