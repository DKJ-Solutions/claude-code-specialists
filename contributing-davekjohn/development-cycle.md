# Development cycle: `fix/native-capture-utf8-read-v1` · 20260826-125130

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `##` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `###` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `## PLAN`** -- everything between the H1 and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `###`
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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

## PLAN

### The boundary the report asked for, found before anything was built

Issue [#907](https://github.com/DaveKJohn/claude-code-specialists/issues/907) ends by refusing to guess why
PR #905 passed the DEPLOY lock with em-dashes an hour before #906 failed on them, and says whoever picks it
up should find that boundary first because it decides where the repair belongs. It is not a property of
either PR: it is `[Console]::OutputEncoding` at the moment `gh` is captured. Measured by emitting the exact
bytes from the report through the real helper under three code pages.

### Why option 1 from the report is right in aim and wrong in mechanism

The report's cheapest shape was "give `Invoke-NativeCapture` a UTF-8 read (or set `[Console]::OutputEncoding`
around the call)". The first half is what this branch does. The second half is forbidden in writing:
`.claude/rules/language-layers.md` states that setter is `SetConsoleOutputCP`, console-WIDE, and that the
test gate runs every suite on one shared console -- which is how inbound #821 hid for as long as it did.

## CREATE

- [x] `Invoke-NativeCapture` gains an opt-in `-Utf8` switch: the child is started with its output
      redirected to files and those files are read with an explicit UTF-8 decode, so no console setting
      can reach the answer. Opt-in rather than the default, because the helper has callers in 15 scripts
      and most of them capture progress rather than data.
- [x] `ConvertTo-NativeArgumentToken` added beside it, because `Start-Process` joins its argument list on
      spaces and quotes nothing.
- [x] The four reads that pull PROSE through this decoder pass `-Utf8`: the lock in
      `scripts/release/ship-pr.ps1`, the same lock in `scripts/lint/check-branch-entry.ps1`, and the PR
      bodies in `scripts/release/open-pr.ps1` and `scripts/release/verify-resolved-issues.ps1`.
- [x] Mirrors regenerated with `scripts/sync/build-shared-scripts.ps1` -- five files, not by hand.

## TEST

- [x] New suite `scripts/tests/native-capture.tests.ps1`: 28 asserts, 0 failures.
- [x] The code-page asserts run in a CHILD process with its own console, so the suite cannot do to its
      siblings what #821 documented.
- [x] `scripts/lint/check-plugin-integrity.ps1` reports 0 errors, `[script-ascii]` included.
- [x] `scripts/sync/check-script-contract.ps1` reports 0 errors.
- [x] Every suite in `scripts/tests/` passes.

## DEPLOY: `fix/native-capture-utf8-read-v1`

The DEPLOY lock refused correct work. `ship-pr` read the PR body back through the console decoder while
reading the branch document as explicit UTF-8, so on a non-UTF-8 console the two sides of one comparison
were decoded differently: `gh`'s em-dash `e2 80 94` arrived as `c3 94 c3 87 c3 b6`, and the lock refused a
PR whose body was intact, naming a line that reads as correct — in a gate with no `-Force`.

**The boundary #907 declined to guess is the console code page, and nothing about the PR.** The report was
right that the trigger is narrower than "any em-dash" and right not to guess: PR #905 passed and #906 failed
because `[Console]::OutputEncoding` differed between the runs, not because their entries did. Measured by
putting the report's own bytes through the real helper -- identical on cp65001, mangled on cp850 and cp437.

**This entry deliberately carries em-dashes, where the previous one had to be flattened to ASCII.** That
flattening was option 3 from the report applied by hand, and it said so itself so nobody would copy it as a
house style. Writing this one normally is the proof that the reason for it is gone — and it was held
against the real PR body on a cp850 console before the merge, not only in the suite.

**The repair is the one the language rule already prescribes, and the report's own option 1 named half of
it.** `Invoke-NativeCapture` gains an opt-in `-Utf8` that redirects the child's output to a file and decodes
it as UTF-8 explicitly. The bracketed alternative in that option -- setting `[Console]::OutputEncoding`
around the call -- is forbidden in writing: that setter is console-wide, and the test gate runs every suite
on one console. Option 2 was declined for the reason the report gave against itself, and option 3 is what
the previous entry had to do by hand.

**Four call sites, not one.** The report named `ship-pr`; the subject is every read that pulls prose through
this decoder, and there are four. The CI gate's copy of the same lock is one of them -- it never bit because
CI runs UTF-8, which is exactly the shape of defect that waits for a local run.

**Score:** 3

### What makes this deploy extra special

N/A -- these scripts ship in the workflow plugin, so a consumer does receive the fix. But it repairs a gate
refusing correct work rather than changing anything they do: a consumer on a UTF-8 console never saw it, and
one on cp850 gets a lock that stops lying. Nothing to learn and nothing to adopt.

**Score:** N/A

### Pull Request

the PR-body read no longer depends on the console code page
