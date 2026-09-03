## Development: `fix/park-commit-fixture-pins-signing` · 20260903-162735

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

Issue #1323. `New-Fixture` in `scripts/tests/park-commit.tests.ps1` pins the ambient git config it
knows about -- `user.email`, `user.name`, `core.autocrlf` -- and not `commit.gpgsign`. So on a machine
with signing forced on, every commit in the suite needs the signing agent to answer: the fixture's own
`init`, and every `Invoke-GitParkCommit` call the suite makes into that fixture repo. When the agent
does not answer, `git commit` fails and **12 of 28 asserts** go red as `park: committing failed`.

**The failure mode is #1287's own, one suite over.** CI configures no signing, so this is green there
and red on the machine where somebody would act on it -- and because the test gate is repo-wide, it
blocked `open-pr.ps1` on a branch touching neither this suite nor `park-lib.ps1`, reporting the park
continuation clause as the subject. Third instance of the class: #1287 pinned the fixture's commits in
`publish-to-business.tests.ps1`, #1297 the residual made by the script under test there.

#### The cause was proven, not inferred

| run | result |
|---|---|
| as-is, machine's `commit.gpgsign=true` | `16 passed, 12 failed` |
| identical, with `GIT_CONFIG_GLOBAL` pointed at an empty file | `28 passed, 0 failed` |

#### Why the fixture is the right layer, and why one line is the whole repair

#1297 had to weigh whether a production path should keep signing. Here it is not a question:
`Invoke-GitParkCommit` commits the **user's real work on their real branch under their own identity**,
so pinning signing off inside the lib would be wrong. The fixture owns this, exactly as #1287
concluded.

And a repo-local setting covers **both** committers, so this repair has no #1297-style residual: the
fixture's `init` is one, and every `Invoke-GitParkCommit` call is the other -- and it commits *into*
this same fixture repo.

### CREATE

- [x] `scripts/tests/park-commit.tests.ps1`: `git config commit.gpgsign false` in `New-Fixture`,
      beside the `core.autocrlf` pin, with the reasoning above at the line -- including that the lib
      is deliberately left signable.

### TEST

- [x] The suite passes **28/28 with the machine's `commit.gpgsign` still `true`**, which is what makes
      the pass mean something: it is not green because the signer happened to answer.
- [x] Swept the rest of the suite set for the same omission, since the issue left that open: of the
      14 suites that make a commit, every one already pins `commit.gpgsign` -- this was the last
      unpinned instance. `guard-live-theme.tests.ps1` reports zero pins and needs none; its
      `git commit -m ...` strings are **input to the guard under test**, never executed.
- [x] The full suite set is left to `open-pr.ps1`'s gate and to CI, which block on any failure.

### DEPLOY: `fix/park-commit-fixture-pins-signing`

`scripts/tests/park-commit.tests.ps1` no longer depends on the machine's `commit.gpgsign`: its
fixture pins signing off, beside the `user.name`, `user.email` and `core.autocrlf` pins that were
already there. With signing forced on and the agent not answering, the suite went `16 passed, 12
failed` -- naming the park continuation clause, which decides nothing about signing -- and because the
test gate is repo-wide it blocked `open-pr.ps1` on unrelated branches. It now passes 28/28 with
signing still forced on. The lib is deliberately left signable: `Invoke-GitParkCommit` commits the
user's real work under their own identity, so the pin belongs to the fixture, which is where #1287
put it for the sibling suite. A sweep of the other 13 commit-making suites found no further instance.

**Score:** 3

#### What makes this deploy extra special

Third instance of one class, and the first two were each found the same way -- by blocking a gate on
a branch about something else entirely. What makes it worth more than its one line is the sweep that
came with it: every commit-making suite is now pinned, measured rather than assumed, so this class
has no fourth instance left to find.

**Score:** N/A

#### Pull Request

Pin commit.gpgsign off in the park-commit suite fixture
