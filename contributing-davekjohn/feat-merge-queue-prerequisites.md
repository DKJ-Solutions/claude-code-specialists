## feat/merge-queue-prerequisites

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

Issue #1325: land the two prerequisites a GitHub merge queue needs before Dave can switch it on. The
queue enable itself stays a repo-settings change and therefore Dave's -- nothing here enables,
reverts or configures anything on GitHub.

#### Why there are two prerequisites and not one

#1325 records one: `.github/workflows/ci.yml` triggers on `pull_request` and `push: [main]` only, and
a required workflow with no `merge_group` trigger never reports for a queue entry -- GitHub's own
warning is that the merge then fails outright, a total merge outage on the trunk.

The second was found while checking the first, and is verified from `gh pr merge --help` on this
machine rather than inferred: *"When targeting a branch that requires a merge queue ... If required
checks have passed, the pull request will be added to the merge queue."* Added, and gh **exits 0**
having enqueued. `ship-pr.ps1` step 4 treats that exit code as proof of a merge and step 5 folds the
changelog entry onto the trunk a few lines later -- so on the first ship after a queue is switched on,
the entry would land on `main` ahead of the merge it describes, with nothing in the run saying so.

Both are the same shape: **inert today, catastrophic on the day the queue is enabled, silent in
between.** That is why both are pinned by a suite rather than by a comment.

### CREATE

- [x] `.github/workflows/ci.yml`: add the `merge_group` trigger, with the reasoning that makes an
      inert line survive a later sweep. The header comment, the concurrency-key comment (the
      `|| github.sha` arm already gives each queue entry its own group -- the key itself needed no
      change) and the `Test suites` condition comment (`merge_group` is not `push`, so the #1300
      fold-commit shortcut does not reach a queue entry, and must not) are all updated, so no
      statement on the page goes stale.
- [x] `scripts/release/ship-pr.ps1`: read the PR's state with `gh pr view --json state` between the
      merge and the fold, and refuse to fold when it is positively read as something other than
      `MERGED`. An unreadable state is deliberately **not** a refusal -- the same shape as the DEPLOY
      lock a few lines up, because turning a network blip into a refusal between the merge and the
      fold would manufacture the trapped-entry state (#1270) the fold exists to prevent. Three
      attempts, seconds apart, to absorb a lagging read -- not to wait a queue out, which is a
      separate decision the refusal hands back rather than guessing a timeout for.
- [x] Mirror the same change into
      `plugins/workflows/contributing-davekjohn/scripts/release/ship-pr.ps1`: it is plugin payload,
      and consumers reach this guard by plugin update, never by a repo-settings change.
- [x] `.claude/specialists/lenses/05-15-extension.md`: rewrite the merge-queue paragraph so it records
      the prerequisites as landed rather than as tracked elsewhere, and states the generalisable half.

### TEST

- [x] New suite `scripts/tests/merge-queue-prereq.tests.ps1` (14 asserts), pinning both halves in one
      place because they are one prerequisite: the trigger matched as a **key of the `on:` block** and
      not as the substring every comment on that page also contains; the readback matched by **what it
      reads** and by its refusal rather than by a variable name; and its **position** asserted between
      the `gh pr merge` call and step 5, since a read placed after the fold would satisfy a substring
      assert and prevent nothing. Plus the "an unreadable state is not a refusal" property, so a later
      tighten-the-gate sweep cannot invert it, and the plugin mirror.
- [x] Negative-tested rather than assumed: deleting the `merge_group` key fails the trigger assert;
      swapping the state read for a different `--json` field fails the readback and ordering asserts.
      Restored, all 14 green.
- [x] Full local gate: `check-plugin-integrity.ps1` plus every suite in `scripts/tests/`, via
      `open-pr.ps1`.

### DEPLOY: feat/merge-queue-prerequisites

Both prerequisites a GitHub merge queue needs are now in the tree, so the queue can be switched on
without breaking the trunk on its first merge -- the switch itself stays a repo-settings change and
therefore Dave's ([#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325)).

`.github/workflows/ci.yml` now triggers on `merge_group`. A required workflow without that trigger
never runs for a queue entry, so `lint-en-tests` never reports, and GitHub's own warning is that the
merge then fails -- a total merge outage on the trunk rather than a degradation. The trigger is inert
until a queue exists, which is precisely why it lands first and on its own: nothing about the repo
today would notice it missing. The suites run in full for a queue entry, because the fold-commit
shortcut from [#1300](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1300) is gated
on the `push` event and does not reach one -- and must not, since a queue entry is the projected merge
being certified before it lands. The concurrency key needed no change: the `|| github.sha` arm that
[#1294](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1294) built for trunk pushes
already gives each queue entry its own group.

`scripts/release/ship-pr.ps1` no longer takes `gh pr merge`'s exit code as proof that the PR merged.
`gh pr merge --help` states it outright: against a queue-protected branch the PR is *added to the
queue*, and gh exits 0 having enqueued it. Step 5 folds the changelog entry onto the trunk on the
strength of that exit code, so the first ship after a queue was enabled would have written a fold
commit for a PR that had not landed -- the entry on `main` ahead of its own merge. The state is now
read with `gh pr view --json state` between the two steps, and a state positively read as anything
other than `MERGED` refuses, with the queue named as the likeliest cause. **This half is also right
with no queue anywhere**: "merged" had been an inference from an exit code, on the one script that
writes to the trunk. A state that cannot be read is deliberately not a refusal -- the same shape as
the DEPLOY lock a few lines above it -- because turning a network blip into a refusal between the
merge and the fold would manufacture the trapped-entry state
([#1270](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1270)) the fold exists to
prevent. The change is mirrored into the plugin copy, since consumers reach it by plugin update and a
repo-settings change never reaches them at all.

Both are pinned by the new `scripts/tests/merge-queue-prereq.tests.ps1`, because both are inert today,
catastrophic on the day the queue is switched on, and silent in between -- nothing in the repo's
present behaviour would notice either being removed.

**Score:** 3

A clear improvement, noticed the moment somebody touches this part: the ship path gains a real
merged-state check today, and the queue decision on #1325 stops being blocked on work nobody had
scoped. Not a 4 -- with no queue enabled, an ordinary ship looks exactly as it looked yesterday.

#### What makes this deploy extra special

The generalisable half, and the reason it is written down rather than merely done: **a settings switch
that is somebody else's to flip does not make the code it will break somebody else's problem.** The
merge-queue decision sat on #1325 for a day as "Dave's", and both defects that would have fired on the
first merge after that flip were in the tree the whole time -- reachable, verifiable from `--help` on
this machine, and fixable without touching a single setting. Waiting on the decision-maker was correct
for the switch and wrong for everything else.

The second prerequisite is the more interesting one, because it was not on the issue at all. It was
found by asking what the *tooling* would do under the new arrangement rather than only what *GitHub*
would do -- and the answer came from `gh pr merge --help`, one command away, on a path this repo runs
several times a day.

**Score:** N/A

#### Pull Request

Merge-queue prerequisites: the merge_group trigger in CI, and a merged-readback before the fold
