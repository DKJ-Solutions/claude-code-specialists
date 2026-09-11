## fix/1867-git-author-identity-probe

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### What was reported, and what verified

Inbound [#1867](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1867), filed from a
consumer that measured the machine state. On a checkout with no usable git author identity nothing in
this workflow says so: session start is silent, `new-branch` runs, and the first commit dies at
exit 128 -- after HEAD has moved. All six pickup checks were run against this repo's current `main`
rather than against the 5.0.0 mirror the reporter read, and the symptom still stands here.

The reasoning was verified rather than taken on trust, in a scratch checkout on this machine:

- `git var GIT_AUTHOR_IDENT` exits 0 with the ident on a healthy checkout and 128 on one with
  nothing in system, global or local config -- the same state, and the same message, that
  `git commit` refuses in.
- `user.name` set with `user.email` unset: git still refuses, while the old check had a name to
  compare and stayed silent. The report's first disagreement, reproduced.
- `user.name` unset with `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` in the environment: git commits fine,
  so there was nothing to warn about. The second, reproduced.

#### One detail of the report is corrected

The report says the failure leaves "a branch on `origin` with nothing committed behind it". It does
not reach `origin`: `Invoke-GitPark` stages, commits, and returns `Ok = $false` before its push when
the commit fails, so `new-branch` exits 1 with nothing pushed. What it actually leaves is a **local**
branch with HEAD moved onto it and an uncommitted branch document -- expensive for the same reason
and in the same way, but a smaller blast radius than reported. The repair is unchanged by it; the
correction is recorded because the issue will be closed against this branch.

### CREATE

- [x] `Test-GitCanCommit` in `scripts/lib/git-identity-lib.ps1` -- the shared probe, `git var
      GIT_AUTHOR_IDENT`, no network. An unmeasurable answer returns `$true`: this function's job is to
      refuse a state it has *proven* broken, and a refusal built on a failed measurement wedges a run
      for the wrong reason.
- [x] `scripts/lint/check-git-identity.ps1` -- probes ahead of all three `[SKIP]`s and reports a
      distinct `[WARNING]`, advisory at exit 0. Ahead of the `gh`-absent skip too: `gh` absent is the
      ordinary state of a consumer that never uses the tracker, while no author identity breaks every
      commit in the cycle.
- [x] `plugins/dkj-policy/hooks/git-identity-sessioncheck.ps1` -- a `[WARNING]` arm ahead of the
      `[ERROR]` one, so the state reaches the session instead of falling into the silent branch
      #1830 routed it to. #1830 was right for two of the three skips and wrong for the third; this
      splits that third one out rather than reverting it.
- [x] `scripts/task/new-branch.ps1` -- refuses beside the trunk refusal, before the checkout, the
      fetch and the scaffold. Guarded dot-source plus `Test-FunctionDefined`, so a plugin payload
      predating the lib degrades to the old behaviour rather than failing to load.
- [x] Mirrors rebuilt with `scripts/sync/build-shared-scripts.ps1`.
- [x] Review round, on the committed diff: code review, copy edit and security review in parallel.
      Security found nothing. Two findings were acted on:
  - The probe was **reordered above the two identity reads**, where it had sat below them. Its own
    comment claimed it was "asked first" -- true only against the three `[SKIP]`s further down, while
    `Get-ActiveGhAccount` shells out to `gh auth status` before it. On the broken machine that made
    the firing branch the most expensive path through the file, at every session start, discarding
    both values it had just paid for. Above them it is the cheapest.
  - **Content drift the change itself created**, in four places that describe this behaviour and were
    not touched by the first commit: `git-identity-lib.ps1`'s synopsis (two functions, "two local
    process launches"), `check-git-identity.ps1`'s own `NO NETWORK` paragraph (the same count),
    `plugins/dkj-policy/scripts/README.md`'s two rows, and the two `shared-scripts-lib.ps1` registry
    comments. All four now say three processes and name the third question.

### TEST

- [x] `git-identity-gate.tests.ps1` -- seven new asserts: the `[WARNING]` and its exit 0, that it
      names the probe, that it prints **both** config keys, that it outranks a simultaneous split
      identity, and that a checkout which *can* commit falls through to the comparison unchanged.
      Four more on the hook's new arm.
- [x] The suite's own machine-independence held: `Invoke-Check` now passes `-CanCommitOverride`,
      defaulting to `YES`. Without it the new probe would have read the real machine and made every
      pre-existing case go red on a runner with no git identity -- for reasons unrelated to the code.
- [x] `new-branch.tests.ps1` -- fixture `(y)` strips the identity in all three places git reads, with
      a sanity assert that git itself refuses there first, so the case cannot pass vacuously. Then:
      exit 1, the wording, both config keys, and the three "nothing was touched" reads that fixture
      `(s)` established for the stale-base refusal. Fixture `(y2)` pins the other direction.
- [x] `New-Fixture` now copies `git-identity-lib.ps1` -- the dot-source is guarded, so without the
      file the refusal degrades to silence and `(y)` would have passed saying nothing.
- [x] Green: `git-identity-gate` 39/39, `new-branch` 265/265, `check-plugin-integrity` 0 errors.

#### Test gaps, named rather than papered over

Two, both deliberate:

- Nothing asserts the real `git var` call inside `Test-GitCanCommit` at the unit level -- the check
  suite stubs it by design, and the `new-branch` fixture `(y)` exercises it end to end instead. That
  fixture is the coverage; a unit case would need a second git installation to be worth more.
- Nothing asserts that the probe runs **before** the two identity reads. That ordering is a cost
  property, not a behavioural one -- every verdict is identical either way -- so the only test for it
  would read the source for line order, which pins formatting rather than behaviour and breaks on any
  honest refactor. The reasoning is in the block's own comment, where the next person to move it will
  be standing.

### DEPLOY: fix/1867-git-author-identity-probe

A machine with no usable git author identity is now reported at session start and refused by
`new-branch` before a branch is cut, instead of failing at exit 128 once HEAD has already moved.
`git var GIT_AUTHOR_IDENT` replaces `user.name` as the reading, because `user.name` disagrees with
git in both directions: set-but-no-email still refuses, and unset-but-auto-guessable commits fine.
The three silent `[SKIP]`s keep their silence; only the one that was never "nothing to compare" is
split out of them.

**Score:** 3

#### What makes this deploy extra special

N/A -- developer tooling in a workflow plugin. It reports a git configuration state to whoever is
running the cycle; no subscriber of any service reaches it.

Worth recording for the next reader of this tree, though: it repairs a gap a previous fix
deliberately left. [#1830](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1830) removed a
false claim of agreement by routing every `[SKIP]` to silence -- correct for two of the three, and for
the third it replaced a wrong statement with no statement, on the one machine state where silence
costs a branch. The lesson is in the split rather than in a revert: three conditions sharing an exit
code are not thereby the same finding.

**Score:** N/A

#### Pull Request

Report a checkout that cannot commit at all, before a branch is cut
