## Development: `fix/park-push-failure-follows-git-v1` · 20260830-141714

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

Issue #1143. Invoke-GitPark's push-failure line asserts a misconfigured remote; since #900 the common case is a non-fast-forward. Make the summary follow $pushRes.Output, and repair the docstring at line 84 that quotes the old wording.

#### Verified before it was repaired

All six inbound checks pass against the tree. The symptom stands (`park-lib.ps1:442`); the reason stands
(#900 made the push a default -- `new-branch.ps1:700` and the `cycle-autopark` Stop hook); the proposed
repair names a mechanism that exists (`Invoke-NativeCapture` merges stderr at `native-capture-lib.ps1:116`,
so git's `[rejected]` line really is in `$pushRes.Output`); subject, size and repo are all as reported.

One thing the report did **not** name, found by reading the file: the docstring at line 84 quotes the old
sentence **verbatim**, so the repair leaves it stale. Same file, so it is inside this branch rather than a
finding of its own.

### CREATE

- [x] Add `Get-GitPushFailureMessage` to `scripts/lib/park-lib.ps1` -- three arms, chosen from what git
      said: a rejection, an unreachable remote, and a fallback that names no cause at all.
- [x] Point the failure branch at line 442 at it, flattening `$pushRes.Output` with `Out-String` first
      (`-match` against an array returns the matching elements, not a boolean).
- [x] Repair the two now-stale sentences in `Test-GitOriginConfigured`'s docstring -- the verbatim quote
      and the "Invoke-GitPark is deliberately NOT changed" line above it.
- [x] Regenerate the plugin mirror (`scripts/sync/build-shared-scripts.ps1`).

### TEST

- [x] New section (d3) in `scripts/tests/park-branch.tests.ps1`: a fixture that diverges with
      `git commit --amend` (the same rejection, none of the destructive shape of a reset), asserting the
      run still exits 1, that the summary names the real cause, and that it no longer sends the reader to
      check the remote -- plus the three message arms asserted on the function directly.
- [x] Proven to fail against the pre-fix lib: both end-to-end asserts go red and the arm asserts cannot
      resolve the function. A regression test that passes both ways is worth nothing.
- [x] Full local gate: `check-plugin-integrity.ps1` + every suite.

### DEPLOY: `fix/park-push-failure-follows-git-v1`

`Invoke-GitPark` now **reports what git said about a failed push instead of asserting one cause**. The
single sentence it used to write -- `park: git push failed (is 'origin' configured and reachable?)` -- was
the right question while `park-branch.ps1` was the only caller: you had *asked* for a park, so the
interesting failure was that there was nowhere to push to. #900 changed the caller and not the message.
`new-branch.ps1` pushes on every branch creation and `cycle-autopark` pushes on every Stop, so the common
failure is now a **non-fast-forward against a branch already on origin** -- and the summary sat underneath
git's own `! [rejected] ... (non-fast-forward)` asserting something else. Nothing landed wrong: the push
really did fail and the run really did exit non-zero. Only the line a reader trusts over the raw text --
which is what a summary is for -- pointed at `git remote -v`.

`Get-GitPushFailureMessage` now picks from three arms: the rejection (*origin already has commits this
branch does not; pull or rebase first*), a remote that is named but unusable (*origin could not be
reached*), and, where neither shape matches, *git's own output is above* -- naming no cause on purpose,
because the run does not know one and a guess reads as a finding. It is a function rather than an inline
`if` so a test can assert the arms from their text instead of staging three different remote failures,
the same reason `Get-GitParkScopes` is one.

**Score:** 2

#### What makes this deploy extra special

`park-lib.ps1` is mirrored into every consumer's plugin cache, and this message is one of the few things
this workflow says when something goes wrong on the remote. A consumer meeting the old line has no context
for `origin` being fine: they have a branch that will not park and a sentence telling them to go and check
their remote configuration. They now get the sentence that matches what happened.

**Score:** 3

#### Pull Request

park's push failure reports what git said instead of naming one cause

