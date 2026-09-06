## feat/1506-ship-pr-enqueue

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

With a merge queue active on main-ci-gate, ship-pr's merge step reaches the queue: gh pr merge enqueues and exits 0 without merging. Make that the intended path rather than a refusal, hand the fold to fold-on-merge.yml, and pin the behaviour in tests.

#### The blocker was real, and it was answered by a decision rather than by code

#1506 was filed blocked on #1505 -- "the fold must have a session-independent home before this
lands". #1505 has since closed, but on documentation only: `fold-on-merge.yml` is code-complete and
still cannot push. Measured in run `34024187136` (2026-09-06 09:16), the push carrying the #1504
merge -- the fold SUCCEEDS and the push is rejected, naming both of main-ci-gate's blocking rules.

The remedy that file recorded turns out not to exist. Adding the GitHub Actions app (integration_id
15368, confirmed against `gh api apps/github-actions`) to the ruleset's bypass list answers `422 --
Actor GitHub Actions integration must be part of the ruleset source or owner organization`; an
Integration bypass actor must be an app installed on the org, and `gh api
orgs/DKJ-Solutions/installations` lists only `claude`. Bypass is by ACTOR, and both bypassing actors
are people -- so the pusher has to be a person's token. Dave's decision, 2026-09-06: a fine-grained
PAT held as `FOLD_PUSH_TOKEN`, minted by him, since a credential is never created by the thing that
consumes it. #1507 landed that wiring from a second session while this branch waited on CI, so what
remains here is the ship-pr half plus the test #1507 did not ship.

### CREATE

- [x] `Get-MergeQueueVerdict` in `scripts/lib/pr-issues-lib.ps1` -- reads a `merge_queue` rule off the
      trunk-rules payload step 0b already fetches, so the answer costs no extra `gh` call. Returns
      Readable and Active separately: an unreadable payload is NOT "no queue", and collapsing the two
      would send a run down the direct-merge path on a trunk that has one.
- [x] `Get-DirectPushBlockingRules` keeps NOT listing `merge_queue`, and now says why. It does block a
      direct push -- both refusals appear in the measured GH013 text -- but a caller reads the queue
      verdict first and never reaches the fold-push question, so listing it there would add a branch no
      caller can reach.
- [x] `ship-pr.ps1` step 0b: the #1278 fold-push refusal is skipped under a queue. Ungated it would
      refuse EVERY ship, since a `merge_queue` rule blocks direct pushes by definition -- on a push
      this run was never going to make.
- [x] `ship-pr.ps1` step 4: the enqueue is now an arm of its own that ends the run at `exit 0`. All
      three readback outcomes collapse into it -- OPEN, MERGED and UNREADABLE -- because not folding is
      recoverable (`check-unfolded-entry.ps1` reports it) and folding a PR that has not landed is not.
- [x] The #1325 refusal is narrowed, not retired: it still fires on a non-MERGED state with no queue
      read on the trunk, and now names the command that tells the reader which case they are in.
- [x] `gh`'s `! The merge strategy for main is set by the merge queue` needed NO code change, and that
      was verified rather than assumed: `Invoke-NativeCapture` judges `$LASTEXITCODE` and merges stderr
      into the printed output (#96/#107), so the notice is shown and the exit code decides. Recorded in
      the step-4 header and pinned below.
- [~] The workflow wiring was BUILT HERE AND THEN DROPPED, because #1507 landed the same repair from a
      second session while this branch was in its CI wait -- same secret name, better shape. It reduces
      `permissions:` to `contents: read` (the default token is no longer the pusher), keeps the
      job-scoped `GITHUB_TOKEN` on the fold step's `gh pr list` so only the PUSH carries the standing
      token, and pins the checkout to a commit SHA because that step handles a 366-day credential.
      This branch takes main's file wholesale rather than re-litigating a change that has landed.
- [x] What #1507 did NOT ship is a test, and that is what stayed. Six asserts in
      `merge-queue-prereq.tests.ps1` on the properties that fail silently: the checkout token IS the
      push credential, it is SHA-pinned, the read path deliberately does not get the PAT, `contents:
      read` is a consequence and not an oversight, and the header still says why the Actions app cannot
      be a bypass actor -- so nobody spends the 422 round trip again.
- [x] And the correction where the impossible remedy had already spread. `CLAUDE.md` and Sylvester's
      lens both stated the Actions-app bypass as a PENDING condition; both now carry the verbatim 422
      and describe what actually pushes. The lens paragraph is layered rather than rewritten -- it was
      right that a bypass is per-ruleset, and what it left open is the half that turned out impossible.

### TEST

- [x] `merge-queue-prereq.tests.ps1`: 14 asserts -> 32. The four new #1506 asserts on the enqueue arm
      are anchored AFTER the merge call, because `$queueActive` is read twice by design and a match from
      the top of the file finds the step-0b arm and pins the wrong block.
- [x] `pr-issues.tests.ps1`: 12 new asserts on `Get-MergeQueueVerdict`, fed the live payload transcribed
      from `rules/branches/main` on the day the queue went live -- plus the pair that stops a later
      simplification from collapsing Readable into Active, and one pinning the deliberate omission in
      `Get-DirectPushBlockingRules`.
- [x] That suite's own header described a decision that has since been reversed ("THE ANSWER IS NO,
      September 3") and now records both halves. Its two guards have stopped being insurance against a
      switch nobody had flipped and are load-bearing on every merge.
- [x] Full local gate green: `check-plugin-integrity.ps1` 0 errors, every suite in `scripts/tests/`.
- [x] Plugin mirrors rebuilt via `build-shared-scripts.ps1` -- consumers get this by plugin update, and
      a repo-settings change never reaches them at all.

### DEPLOY: feat/1506-ship-pr-enqueue

`ship-pr.ps1` no longer treats a merge queue as a failure. On a trunk behind one it opens the PR, waits
for CI, ENQUEUES, and ends successfully at step 4 -- the queue merges the PR against its real base and
`fold-on-merge.yml` folds off that push. On a trunk without one nothing changes: the same merge, the
same fold, and the same #1325 refusal for a state that has no explanation.

**Score:** 4

#### What makes this deploy extra special

The change is small; what took the work was refusing to build on the reason the tree already carried.
`fold-on-merge.yml` stated as settled fact that adding the GitHub Actions app to the ruleset would make
it live. Applying that produced a 422, and the route does not exist -- so the record now carries the
refusal text rather than the plan. A repair built on the unverified half would have satisfied the issue
and been wrong, with a citation.

And the second half of that lesson arrived by collision: #1507 landed the same repair from another
session while this branch sat in its CI wait, which is what a merge queue with two shipping sessions
looks like. The resolution is the same rule pointed at my own work -- take what landed, drop what
duplicates it, and keep only the part nobody built, which here was the test.

**Score:** 2

#### Pull Request

ship-pr enqueues via the merge queue instead of direct-merging
