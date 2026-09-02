## Development: `fix/ship-pr-lost-watch-retry-v1` · 20260902-142513

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

Add Get-LostWatchNote to pr-issues-lib (no failing check + something still pending = the connection died, not a verdict), loop the --watch call in ship-pr step 3 on that read, and pin both with asserts in pr-issues.tests.ps1.

### CREATE

- [x] `Get-LostWatchNote` in `scripts/lib/pr-issues-lib.ps1` -- one sentence when a non-zero
      `--watch` exit is the connection dropping (nothing failed, something is still running), and `''`
      on every other read, unreadable payloads included
- [x] `scripts/release/ship-pr.ps1` step 3 -- loop the `--watch` call on that read (bounded), and give
      the refusal its own third wording beside "CI did not pass" and "CI never RAN"
- [x] mirror the lib into the plugin: `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] asserts in `scripts/tests/pr-issues.tests.ps1` -- the new function in both directions, and that
      ship-pr actually calls it (the call-site assert the #1044 block already carries)
- [~] a full-suite run of my own -- DROPPED: open-pr's gate runs the lint check and every suite at
      the push, so a copy set going ahead of it proves nothing that gate would not have caught and
      charges the same measurement twice. The targeted suite above was run; the rest is the gate's.

### DEPLOY: `fix/ship-pr-lost-watch-retry-v1`

`ship-pr` no longer reports a dropped connection as a code failure, and re-enters the wait instead of
handing the branch back. `gh pr checks --watch` is one long-lived GraphQL call; when it dies mid-wait
on a transient socket error its exit code is indistinguishable from a failing check, so the operator
read *"CI did not pass for PR #1218 (exit 1) ... Fix CI and re-run, or merge manually once green"*
about a run that was still progressing and went green on its own minutes later. Step 3 now reads the
check payload instead of trusting that exit code alone: where nothing has reported a failure and a
check is still running, the watch is re-entered (up to three attempts, one poll interval apart), and
if the attempts run out the refusal says **CI is still RUNNING** rather than that it failed. The
merge decision does not move -- this is the third cause of a distinction the script already drew
twice, after a red required check (#943) and a run that never started (#1044), and like both of those
it changes only the sentence and never the verdict.

**Score:** 3

#### What makes this deploy extra special

A consumer running the workflow's `ship-pr.ps1` gets both halves. The retry is the part they feel:
step 1 is the only step that reads the working tree and step 2b has already sent the checkout back to
the trunk, so before this a dropped socket cost them a re-checkout of the branch plus a full local
gate run -- lint and every suite -- against a commit CI was already testing. Now it costs one more gh
call. And on the run that does have to stop, the sentence no longer sends them into their own code
for a state no branch can repair.

**Score:** 3

#### Pull Request

ship-pr tells a dropped CI watch from a red check, and re-enters the wait
