## Development: `fix/git-calls-noninteractive-and-bounded-v1` · 20260901-110752

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

Invoke-NativeCapture is the one choke point every git and gh call in open-pr.ps1 and ship-pr.ps1 goes through. It sets no non-interactive guard and bounds no wait, so a credential helper that opens a prompt nothing can answer hangs the ship forever and the script reports it as still running. Close inbound #1179 at that choke point: a non-interactive environment around every child, and an opt-in bounded wait at the git network calls.

#### What the inbound verification changed about the report

The six checks were run against the tree before anything was routed. Two came back different from
the report, and both changed the work:

- **The subject is at a different address.** The report names `scripts/task/open-pr.ps1` and
  `scripts/task/ship-pr.ps1`; both live in `scripts/release/`, plus a plugin mirror each. Same
  files, so the symptom stands -- but a repair aimed at the named path would have found nothing.
- **The size is bigger than measured.** The report reads as two scripts with unguarded git calls.
  Neither script calls git directly: both go through `Invoke-NativeCapture`
  (`scripts/lib/native-capture-lib.ps1`), which 20 scripts and 111 call sites share. Repairing the
  two call sites the report names would have left every other one exactly as it was, and the guard
  would have been two literals in two files waiting to drift.

The symptom itself was confirmed rather than assumed: `GIT_TERMINAL_PROMPT`, `GCM_INTERACTIVE` and
`credential.interactive` appear nowhere in the tree, and no call anywhere is bounded.

### CREATE

- [x] The non-interactive environment, in `Invoke-NativeCapture` and its Start-Process arm:
      `GIT_TERMINAL_PROMPT=0` + `GCM_INTERACTIVE=never` around every child, saved and restored in the
      same `finally` the EAP dance uses. Both names, because they stop different things -- the first
      is git's own terminal prompt and says nothing about the credential helper git hands off to.
- [x] `-TimeoutSeconds`, opt-in: a bounded wait that kills the process **tree** (the measured blocker
      was the grandchild), reports exit 124 and `TimedOut`, and appends a `[timeout]` diagnosis to
      `Output` so a caller that already prints `Output` reports the stall without changing a line.
- [x] Applied at the three calls that reach the network: the push in `open-pr.ps1`, the fetch in
      `ship-pr.ps1`, and the fold's push in `fold-changelog-entry.ps1`. Each gets a failure message
      naming what state the run is actually in. Deliberately NOT a default: `gh pr checks --watch`
      blocks for as long as CI takes, by design.
- [x] Plugin mirrors regenerated (`scripts/sync/build-shared-scripts.ps1`) -- all four files are
      shared scripts.

### TEST

- [x] `native-capture.tests.ps1`: 19 new asserts over the two guards. Both env names separately
      (either alone leaves the hang in place), restore-to-absent as distinct from restore-to-empty,
      restore after a throw, both arms; and for the bound, that the call RETURNS, the exit code, the
      `TimedOut` flag, the `[timeout]` line, and that an unexpired bound changes nothing.
- [x] The grandchild assert, which is the measured shape: a two-marker fixture proves the grandchild
      launched before it asserts the grandchild died, so it cannot pass for the wrong reason.
- [x] Suite green: 56 pass, 0 fail, 21s.
- [x] Full local gate (lint + all suites) green -- see below.

### DEPLOY: `fix/git-calls-noninteractive-and-bounded-v1`

Closes inbound #1179. A git call made by the workflow scripts can no longer hang on a credential
prompt nothing will answer: every child now runs non-interactively, and the three calls that reach
the network are bounded so any other stall reports itself instead of reading as work in progress.

**Score:** 4

A hang here is not a slow run -- it is a run that never ends and says nothing, and it costs whatever
the gates had already paid for. The reporting machine lost a lint + 13-suite gate that way. Every
consumer of the workflow plugin gets this the moment they update, without configuring anything.

#### What makes this deploy extra special

The repair is at the choke point rather than at the two call sites the report named, so all 111
git and gh calls in the workflow are guarded rather than the two that happened to be measured.

**Score:** 3

#### Pull Request

git calls in the shared workflow scripts fail fast instead of hanging on a credential prompt

