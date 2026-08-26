## Development cycle: `feat/branch-visible-on-origin-v1` · 20260826-175652

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Issue #900: the creation push becomes the default in new-branch, and a Stop hook keeps
development-cycle.md fresh on origin until a PR exists. Machinery exists already (Invoke-GitPark,
BranchFiles scope).

#### Where this came from, and why it was pickable today

Issue [#900](https://github.com/DaveKJohn/claude-code-specialists/issues/900) is Dave's own, in his own
words: he works from more than one device, so a branch nobody else can see is a branch the other device
collides with. It was verified before any of this was written -- the symptom (still true), the reasoning
(`Invoke-GitPark` and the `BranchFiles` scope exist exactly as described), the proposed repair (both
directions it names are real), the subject, and the size (two entry points, one lib, one hook).

**The one thing that HAD expired was its blocker.** The issue closes with *"Sequencing: after #886 --
`new-branch.ps1` has a plugin mirror at `plugins/workflows/workflow-davekjohn/scripts/task/new-branch.ps1`,
and #886 renames that directory."* [#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886)
closed at 09:12 this morning and the mirror already sits under `contributing-davekjohn/`. So the reason to
wait is the reason this was the pickable one.

### CREATE

- [x] `new-branch.ps1`: the push is unconditional, `-NoPush` is the escape valve, and `-Park` is kept as
      an announced no-op -- the script is mirrored into every consumer's plugin cache, where a typed
      `-Park` from a doc or a habit would otherwise fail on a parameter that is gone
- [x] `park-cycle.ps1` added: the automatic half, one document, four bounds -- not on the trunk, not once
      a PR exists, no amend/no force, and never `git add -A`
- [x] `cycle-autopark.ps1` added as a **Stop** hook, plus its entry in `hooks.json`. Deliberately thin:
      every bound and every measurement lives in the script, and the hook passes `-Quiet`
- [x] `Test-GitOriginConfigured` added to `park-lib.ps1` -- see the TEST note, this was found rather than
      designed
- [x] registry row for `park-cycle`, documented in the existing `park` skill rather than a new one: the
      three parking moments are one subject and a reader choosing between them wants one page
- [x] the mirrors regenerated with `scripts/sync/build-shared-scripts.ps1`
- [x] docs: the `park` and `new-branch` skill pages, Derek's lens, and the four places that enumerate this
      repo's hooks -- the root README twice, `SPECIALISTS.md`, `connectors/README.md`, the plugin's own
      README, and the teardown table
- [~] no fetch before reading the remote-tracking ref in `park-cycle`. It would cost a network call on
      every turn, which is the one thing the cheap gate above it exists to avoid -- and a ref gone stale
      because the other device pushed is precisely the case where the push fails loudly, which is the
      right outcome rather than a defect
- [~] no cache of the "does a PR exist" answer, though the `gh` call runs once per turn that touched the
      document. `gate-lib.ps1` already has the evidence machinery it would use, so this is a measurement
      away if it ever bites -- but it has not, and the call only runs when there is something to push
- [~] no change to `park-branch.ps1`. It keeps failing loudly when there is no `origin`, because you
      asked it to park; only the two automatic callers ask the origin question first
- [x] one layer removed on review: `park-cycle` asks `Get-BranchTrunkName` for the trunk rather than
      probing the consumer's `Get-TrunkBranchName` seam a second time itself -- that shared resolver
      already does the probe and the fallback, so the copied two-step was one more place that has to keep
      agreeing with it. `check-branch-entry.ps1` still carries the older shape; that is not a defect
      there, just a layer this script does not need

### TEST

- [x] `scripts/tests/park-cycle.tests.ps1`, 45 asserts: the happy path, idempotence, `-Quiet`'s silence,
      the DEPLOY lock, the fail-safe, the trunk, a reset document, another branch's document, no origin,
      no document, a committed-but-unpushed one, and the trunk seam
- [x] the trunk-seam case asserts **inverted**, which is what makes it prove something: the fixture's
      trunk is `master` and the branch checked out is called `main`, so a script that assumed `main`
      would refuse with "on the trunk" and look well-behaved doing it
- [x] a `gh` shim per fixture, first on PATH, answering the one shape the script parses. Not a
      workaround: a bare repo is not a GitHub remote, so a real `gh pr list` fails against every fixture
      -- and a suite that accepted that would exercise only the fail-safe path and report "no PR" and "gh
      is broken" as the same green
- [x] `new-branch.tests.ps1` extended from 118 to 134: the default push, `-NoPush` **with an origin
      sitting right there**, no origin at all, and `-Park` announcing that it changed nothing
- [x] `worktree-lane.tests.ps1`: its dirty-lane case now arranges its own dirt, and a new assert pins
      that a lane is on origin the moment it opens
- [x] the lint gate: 0 errors, all 28 checks
- [x] the test gate: all 53 suites green in 56s

#### Two things the gates found that a review would not have

**The suite found a defect, not a broken test.** Every `new-branch` fixture deliberately configures no
remote -- that was how "no push by default" was asserted -- so making the push unconditional turned
`git push` into an **exit 1 out of branch creation** in every remote-less repo. *"There is nowhere to
push"* arriving as *"your branch could not be made"*. A repo with no remote is a legitimate repo, so
`Test-GitOriginConfigured` is the answer and the automatic callers ask it first; `park-branch` deliberately
does not.

**And the repo-wide stderr guard caught the second one on its first run.** `park-cycle` resolved its repo
root with a bare `git rev-parse --show-toplevel 2>$null`, copied from the shape beside it. Under
`EAP=Stop` that is terminating before any exit code can be read -- and this script runs outside a git repo
as a matter of course, because a hook fires wherever the session is. It goes through `Invoke-NativeCapture`
now, which is why the libs are dot-sourced before the root is resolved rather than after.

### DEPLOY: `feat/branch-visible-on-origin-v1`

A branch and its development cycle now reach `origin` **without anybody deciding to send them**
([#900](https://github.com/DaveKJohn/claude-code-specialists/issues/900)). Two changes, one at each end of
a branch's life. `new-branch` pushes at creation by default -- that exact block ran behind `-Park` for
nineteen days -- and a new **Stop** hook, `cycle-autopark`, keeps `development-cycle.md` current on the
remote for the rest of the branch by invoking the new `park-cycle.ps1` after every turn. Still no PR at
either end: push is not a PR, and opening one stays a separate, explicit step.

**The measurement is the whole argument, and it is two numbers side by side.** `park` and
`new-branch -Park` produced **six** commits in the entire history. Over the 38 merged branches carrying a
readable creation stamp, the median branch was invisible on `origin` for **22 minutes**, the mean 35, the
worst **365**, nine of them over half an hour. An opt-in backup is a backup nobody takes. The same
measurement had already been read once, in #507, as proof that both parking moments were real -- and both
readings are right: each moment is used, and nobody reaches for either often enough for an opt-in to work.
So no entry point was deleted; what changed is that two of the three stopped asking.

**What another device needs is the document, not the branch name**, which is why one push at creation was
not the whole answer. Dave's own addition to the issue: *"zorg ook dat development-cycle zoveel mogelijk
up-to-date is op origin niet alleen de branch zelf. Daar staat de belangrijkste info over de branch."* The
plan, which phase is running and where the last session stopped all live in that one file. Hence the
split the repo's own rule dictates -- what has to happen without anyone asking is a hook, what somebody
invokes is a script in a skill -- so the creation push went into `new-branch` and the ongoing freshness
into a hook, over a script that also runs by hand.

**The bound that matters most is where it STOPS.** The DEPLOY lock (#884) refuses the merge once this
document has diverged from what the PR published, so a pusher that kept running after `open-pr` would not
be a convenience -- it would block **every merge in the repo**, structurally, and the failure would read as
the lock misbehaving rather than as the hook. So any open PR on the branch makes it a no-op, and its
fail-safe runs the same direction: when `gh` cannot answer, it does not push. Being one turn stale is a
nuisance; an unmergeable branch is a defect. Three narrower bounds beside it: one named pathspec and never
`git add -A`, nothing on the trunk where the fold removes this file, and no amend and no force -- which
the constitution forbids anyway, so this costs a handful of small `park:` commits per branch.

**One stale count is repaired along the way, and it is #886's rather than this branch's.** Four documents
enumerate this repo's hooks and all four had to learn about the new one, which is how a fifth line came to
be read: the root README's platform-reach table called `team-alpha`'s hooks **two**. That was **true when
it was written** on August 15, 2026 -- the core team carried `roster-sessioncheck` *and*
`workflow-sessioncheck` then -- and stopped being true this morning, when #886 retired the second one. So
it is one word, and the reason it is fixed here rather than filed is that this branch is already editing
that table for that exact subject. Every other mention of `workflow-sessioncheck` in the tree was checked
in the same pass: six of them, all already in the past tense.

**Score:** 4

#### What makes this deploy extra special

Both halves ship in shared scripts and one of them is a **hook**, so every consumer receives this through
the next plugin update rather than by choosing it -- and a hook that commits on your behalf is the most
intrusive thing this plugin has ever shipped. Three decisions are there for that reader specifically.

**It is the first hook here that acts rather than reports.** The three beside it are read-only
SessionStart checks that never block; this one writes to git. That is a real widening of the
"repo-neutral exceptions" list in the root README and it is named as such there rather than slipped in. It
is still not a guardrail: it refuses nothing, blocks nothing, and exits 0 on every outcome including the
ones it declines -- a Stop hook that fails is a hook that interrupts the work it was added to protect.

**It is silent unless it does something.** A turn that did not touch the document prints nothing at all,
which is the difference between a hook nobody notices and one everybody turns off. A push does report
itself, because a commit made on somebody's behalf should be visible in the transcript that caused it.

**And a consumer who cannot push is not broken.** No `origin` means there is nowhere to park to and it
says so; a repo mid-adoption with no `repo-config.ps1` or `branch-info.ps1` gets the shared defaults rather
than a failure; and `-NoPush` is there for the branch that genuinely must not be visible yet. The one
thing a consumer may need to know up front is the consequence the issue itself flagged: pushing at
creation produces remote branches for work that is later abandoned, and `deleteBranchOnMerge` reaps only
merged ones. Nothing cleans those up. That is something to watch, not a reason to hold this back.

**Score:** 4

#### Pull Request

the branch and its development cycle reach origin without anybody remembering to push

Plugins: contributing-davekjohn

