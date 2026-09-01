## Development: `fix/sync-main-checks-poll-bounded-v1` · 20260901-131758

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

Inbound [#1187](https://github.com/DaveKJohn/claude-code-specialists/issues/1187): the `gh pr checks`
polling loop in `sync-main.ps1` is the last network call outside `Invoke-NativeCapture`, left there by
[#1184](https://github.com/DaveKJohn/claude-code-specialists/issues/1184) on a reason that does not hold.

#### What the six checks read against the tree

Verified before routing, not after. **Symptom stands**: the poll sits inside a hand-rolled
`$ErrorActionPreference` bracket with no per-call bound. **Reason stands, and it is the interesting
half**: `while ((Get-Date) -lt $deadline)` re-reads the deadline only at the top of the loop, so
`-ChecksTimeoutMinutes` bounds the number of *iterations* over wall clock and not any single call --
one `gh pr checks` that never returns never reaches the condition again. **The report's correction of
#1184 is right**: the lib's docstring warns about `gh pr checks --watch` (`ship-pr.ps1`), which blocks
for as long as CI takes by design, not about a poll that answers in seconds. **Size stands** -- nine
calls, nine bounds, and the two asserts pinning the exclusion are at `scripts/tests/sync-main.tests.ps1`.
**Subject and repo** both correct.

One note on the reading, because it nearly produced a wrong answer: the first pass measured five calls
and no pinning asserts, and concluded the report had mis-measured its own size. It had not -- #1188's
background ship merged and folded while the files were being read, so the checkout was two commits
behind its own session. Re-read against the current trunk, the report is accurate on all six.

### CREATE

- [x] Route the poll through `Invoke-NativeCapture -FilePath 'gh' -DiscardStderr -TimeoutSeconds
      $NativeCaptureNetworkTimeoutSeconds`, replacing the hand-rolled EAP bracket
- [x] Judge a timeout as *"this poll did not answer"* -- warn, empty the states, keep looping to the
      deadline -- and discard `Output` on that path rather than parsing it
- [x] Leave the exit code unjudged, deliberately, so a red check is still read off its states
- [x] Rewrite the banner's exclusion paragraph into the record of why the exclusion did not survive
- [x] Regenerate the `team-shopify` mirror (`build-shared-scripts.ps1`)

### TEST

- [x] Turn the two asserts that pinned the exclusion into the two that pin the routing
- [x] Add the behavioural pins a count cannot see: `TimedOut` is judged, `$poll.ExitCode` is not
- [x] Count nine -> ten calls / ten bounds; add `checks` to the bare-verb ban and the by-name loop
- [x] Add the `-DiscardStderr` assert for the poll, beside the two existing `--json` reads
- [x] Re-pin the hand-rolled-bracket count one -> zero
- [x] `scripts/tests/sync-main.tests.ps1` green -- 107 asserts

### DEPLOY: `fix/sync-main-checks-poll-bounded-v1`

`sync-main.ps1`'s `gh pr checks` polling loop -- the last network call in that script outside
`Invoke-NativeCapture` -- now runs through it with the shared 120-second bound, so a poll that hangs is
killed and reported instead of stopping the run dead. **The loop was bounded and the call was not, and
those are different bounds:** `-ChecksTimeoutMinutes` is re-read only at the top of the `while`, so it
limits how many times the script asks, not how long any one ask may take. A single `gh pr checks` that
never returned never reached that condition again, and a run that had already opened the sync PR sat
there for as long as the process lived. That is the same class inbound
[#1179](https://github.com/DaveKJohn/claude-code-specialists/issues/1179) and
[#1181](https://github.com/DaveKJohn/claude-code-specialists/issues/1181) closed, arriving through the
one call that looked as though it had been handled.

**A timeout is not a verdict**, and preserving that is most of the change. The run warns, treats the
poll as unanswered and keeps polling until the deadline, because a slow answer is not a red check. Two
things would each have turned a stall into a wrong answer and neither is visible in a call count: the
bounded arm *appends* two `[timeout]` lines to its output, which parsed as check states match nothing
and read as CI failure; and `gh pr checks` exits 8 while checks are pending and 1 when one has failed,
so gating the parse on a zero exit would have thrown away a real red and sat out the whole timeout
before reporting "not green" for a PR that was already broken. The exit code is therefore deliberately
not judged here, exactly as before -- this loop has always read the states.

**This reverses the last sentence of the entry above it**, which recorded the poll as deliberately
untouched. Both reasons #1184 gave for that turned out not to hold: "it is bounded already" was true of
the loop and not of the call, and "a bound per call is the mistake the lib warns about by name" pointed
at `gh pr checks --watch` in `ship-pr.ps1`, which blocks for as long as CI takes by design. What was
true is that the hand-rolled `$ErrorActionPreference` bracket was load-bearing -- it had to swallow the
stderr a pending run writes while still reading states off stdout -- and `-DiscardStderr` does that
half, measured rather than assumed. With the poll routed, the lib's own docstring claim that *every*
git and gh call in the workflow scripts comes through this one function is true in this tree, and the
script now carries no hand-rolled EAP bracket at all.

**Score:** 3

#### What makes this deploy extra special

N/A -- a consumer running `sync-main.ps1` is the reader, and this repo's subscriber never sees it. The
change is invisible until the day a `gh` poll stalls, and on that day it is the difference between a
15-minute silence and a named failure.

**Score:** N/A

#### Pull Request

sync-main.ps1's CI poll is bounded per call, not only across the loop
