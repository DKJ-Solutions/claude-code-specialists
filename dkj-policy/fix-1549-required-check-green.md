## fix/1549-required-check-green

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

The green watch exit breaks past the required-check facts it has already read, so a fast non-required
check finishing first is read as CI green.

#### What the report got right, and the one thing it did not know

Inbound [#1549](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1549) inferred its own
cause honestly -- *"not read in the source; the repair is yours"* -- and the inference holds. What the
reporter could not see from outside is that **the facts were already in hand at the point of the
verdict**: step 3's watch loop reads `gh pr checks --required --json name,bucket,state` into
`$requiredFactsJson` *before* it decides, and `Get-MergeBlockVerdict` already computed which required
checks had not concluded. The green path simply broke past both --
`if ($checks.ExitCode -eq 0) { break }` -- because that pending list only ever reached the caller as
prose inside `Reason`, with no field to read.

So the repair is smaller than the report expected and lands in two places rather than one: the verdict
**returns** what it already knew, and the green path **asks**.

The report's own evidence proves the required list was readable in the measured run, which is what
makes this the right repair rather than a guess: the wait report printed
`'.github/dependabot.yml' finished last and governed the merge (1s, NOT required)`, and that
`NOT required` label is rendered only from a readable, non-empty required-check payload.

### CREATE

- [x] `Get-MergeBlockVerdict` returns `UnfinishedRequired` -- the list it already computed, now on all
      four return shapes so a caller need not know which branch produced its verdict.
- [x] ship-pr's step 3 green path consults it: a pending required check re-enters the wait instead of
      declaring CI green, bounded by the existing `$watchAttempt` counter, refusing on exhaustion.
- [x] Fail-open on an unreadable required list, deliberately -- the verdict returns an empty
      `UnfinishedRequired` there, so an unreadable payload can still never turn a GREEN run red and a
      repo with no ruleset at all never enters the wait.
- [x] The step's own header comment and the file's step-3 description corrected: the claim
      *"reads the exit code"* was no longer true of the green path.
- [x] Plugin mirrors regenerated via `scripts/sync/build-shared-scripts.ps1` (both files are shared).

#### What was deliberately NOT built

- [~] A required context that has registered **nowhere yet** is not covered, and this is stated rather
      than quietly attempted. `gh pr checks --required` cannot distinguish it from *"this ruleset
      requires nothing"* -- the exact ambiguity this script already documents at two other seams -- so
      covering it would mean reading the ruleset itself, a new API surface with no measurement behind
      it. The measured instance is not that case: `Shopify theme check` was registered and **pending**.
- [~] A required check that FAILED while the watch still exited 0 is left alone: unreachable in
      practice (a check absent from the watch's set cannot have failed, and one in it makes `--watch`
      exit non-zero), and covering it would mean weakening the invariant that an unreadable payload
      cannot turn a green run red.

### TEST

- [x] `scripts/tests/pr-issues.tests.ps1` extended -- the PR #529 shape, the fail-open asserts across
      five unreadable payloads, the all-green case (without which the green path would spin forever on
      the ordinary ship), pending vs unknown, the mixed list, and the field's presence on every return
      shape.
- [x] Call-site pins added, the same guard the #1044 / #1219 pins use: reverting the one green-path
      line would otherwise leave every assert in the suite green while ship-pr merged past a pending
      required check again.
- [x] `scripts/tests/pr-issues.tests.ps1` -- OK, all 673 asserts pass.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors.

### DEPLOY: fix/1549-required-check-green

`ship-pr` no longer calls CI green off a check the ruleset does not require. `gh pr checks --watch`
only ever watches what was registered when it started, so a required workflow that has not yet created
its check run is **absent** from that set rather than pending in it -- and a fast advisory check
passing first exited the watch 0 with the required one still to come. The run then said `CI green` and
walked into `the base branch policy prohibits the merge`.

The green exit is now held against `gh pr checks --required` before it is believed, and a required
check that has not concluded sends the run **back to the wait** rather than to the merge. Nothing has
failed in that state, so waiting is the answer rather than a refusal; the wait itself is untouched in
the sense [#831](https://github.com/DKJ-Solutions/claude-code-specialists/issues/831) settled it, and
what changed is only that a non-required check can no longer end the wait on the required one's behalf.

Measured in a consumer on September 7, 2026 (`dkj-policy` 4.31.0,
[BWJ-Development/smartwatchbanden#529](https://github.com/BWJ-Development/smartwatchbanden/pull/529)):
`.github/dependabot.yml` passed in 1s, ship-pr declared green after 5s, and required
`Shopify theme check` (2m1s) and `branch-entry` (31s) were both still pending -- a plain
`gh pr merge --merge` succeeded on the first try once they finished. On any repo whose required check
outlasts a fast advisory one, that fired on **every** ship.

The failure direction is what makes this worth a release rather than a tidy-up. The refusal itself was
loud and safe; *where* it left the work was not -- past the local gates, past the PR, with the merge
and the fold still owed to a process that then exits, so the session holding the context is the one
that dies and a later session finds an open PR with a green tick and no visible reason it never landed.

**Score:** 4

#### What makes this deploy extra special

The facts were already being printed. The wait report annotated the governing check `NOT required` in
the same run that then merged on it -- so the distinction was read, rendered, and shown to the operator
one line below a verdict that ignored it. The two readings that label supports are opposite, and the
script had been picking the wrong one: *"the check that governed the merge was not a required one"* is a
reason to keep waiting, not a certificate. The repair is therefore mostly a field on a return value; the
computation, the query and the verdict are all untouched.

**Score:** 3

#### Pull Request

ship-pr consults the required-check verdict on the GREEN path too, so a pending required check is waited for instead of merged past
