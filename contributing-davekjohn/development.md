## Development: `docs/a-wait-longer-than-a-minute-parks-the-branch-v1` · 20260829-101227

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

#### What this branch is

[Issue #1060](https://github.com/DaveKJohn/claude-code-specialists/issues/1060), and the rule Dave stated in
it on August 29, 2026: **as soon as a session has to wait longer than a minute for something, the branch is
parked and the session ends there.** It does not hold the turn, and it does not background the wait and then
hover over the output file.

The issue names four things that were deliberately left undecided. Each is answered below against the tree
rather than from the report, because the report's own reasoning turned out to be wrong in one place.

#### 1. Is the pre-run of the suites dropped? Yes -- and the issue's reason for it is wrong

The issue says a standalone pre-run is slower because it is "54 separate `powershell -NoProfile -File`
launches against one in-process pass". **`Invoke-TestSuiteGate` is not an in-process pass**: it launches
every suite as its own `powershell` child too (`scripts/lib/native-capture-lib.ps1`, `Start-Process
-NoNewWindow`, deliberately not a job). What actually makes it faster is two mechanisms the report does not
name:

- **The pool is parallel** (issue #512, August 7, 2026). The gate costs what its *slowest single file*
  costs instead of the sum: measured at 27 suites, 510s one at a time against 128-263s parallel.
- **A pass is recorded.** `open-pr` writes gate evidence keyed on a fingerprint of the tree
  (`Test-GateEvidence` / `Save-GateEvidence` in `scripts/lib/gate-lib.ps1`), so a second run over an
  unchanged tree is skipped entirely. A standalone run records nothing, so it buys the session no credit
  towards the gate it is about to pay for anyway.

The conclusion survives the correction and gets stronger: a serial pre-run costs the sum, records nothing,
and refuses nothing `open-pr` would have let through. **It is dropped.**

#### 1b. Which is why the standing gates are not TEST steps

The bind behind the pre-run is mechanical, not a habit: `open-pr` **refuses to push while a step above
DEPLOY is open**, so a TEST step reading *"all suites green"* can never be ticked by the run that would
prove it. The only way to tick it is to run the suites by hand first -- which is exactly the wasted run
above. So the repair is at the step, not at the gate: **TEST carries the branch's own proof, never the
repo's standing gates.** They fire unconditionally and refuse on their own; writing one down as a step
duplicates a gate and then forces a hand-run to satisfy the duplicate.

#### 2. A finished branch whose PR is open: background the ship and close out

No new machinery, and none is needed. `ship-pr.ps1` started as a **background** command already merges and
folds without anybody watching -- that is the documented shape in 3.4 since issue #985. What changes is that
it stops being a judgement call: the session starts it and closes out, and **hovering over its log is
forbidden**. Where no ship can be started at all, the branch stays parked, the PR is left green for Dave, and
the fold is a `fold-changelog-entry.ps1` run in the next session. `cycle-autopark` (#900) has already pushed
the document either way.

#### 3. Where the rule lives: Chris's portable persona body

It is session behaviour, every consumer of this workflow pays the same CI leg, and by the source-is-the-
default rule that puts it in the persona rather than a lens. **The measurement stays out of it** -- personas
carry no repo-specific detail -- so the numbers and the instance go in `CONTRIBUTING.md`, where the CI-leg
figures already are.

#### 4. A minute is the shape, not the number

The issue's own table settles this. A 60s `open-pr` gate is *at* the threshold and is work the session must
do itself; an 8-minute CI leg is somebody else's clock at any duration. So the rule keys on **whose clock it
is**, and the minute is what makes you stop and ask.

#### 5. Parking ends on the trunk -- the half the first pass dropped

Dave, on the close-out of this branch's own first pass: the session reported that it could be cleared while
the checkout still stood on the branch. His rule in #1060 already said it in as many words -- the branch is
parked **and we go back to `main`**, then look for something the next clean session can pick up -- and the
first pass implemented only the first clause. "Parked" was read as a statement about `origin`, and the
checkout was left standing on the branch while the close-out said the session could be cleared.

**It is not cosmetic.** Parking protects the work; it does not tidy the checkout, and those are two different
claims. A close-out made from a feature branch says the context can be cleared while `git status` says the
work is mid-flight, and the second one is the one a requester should believe. So the closing act is
`git checkout main`.

**And the tension with the known trap is stated rather than left to be discovered.** Chris's lens records the
inverse failure -- `ship-pr` step 5 leaves you on `main`, which reads as *ready* -- so the two rules have to
be read together: the trunk is where a session **ends**, and the branch check at the start of the next
assignment is what stops it from being where the next one silently begins.

#### What this branch does not do

`worktree-lane` and the two shapes declined under #985 -- a green-and-unmerged reporter, a detached watcher
that merges on green -- are left exactly as they are. The issue asks for them not to be quietly rebuilt.

### CREATE

- [x] Write the rule into Chris's portable persona body as its own short section, keyed on whose clock it is
- [x] `CONTRIBUTING.md` 2.2: the repo's standing gates are not TEST steps, and why the duplicate forces a hand-run
- [x] `CONTRIBUTING.md` 3.4: nothing-at-all is the default rather than a judgement call, hovering is forbidden, and the pre-run measurement with its corrected mechanism
- [x] Both documents: parking ends on the trunk -- `git checkout main` is the closing act, with the tension against the known "a clean trunk reads as ready" trap stated rather than left to be found

### TEST

- [x] Every mechanism the new text cites is read back against the script that implements it -- `Invoke-TestSuiteGate`, `Test-GateEvidence`, the step-list gate's refusal, `cycle-autopark`'s bounds
- [x] The two documents are read end to end for drift the change could introduce: a 3.4 that now contradicts 2.2, or a persona claiming a mechanism only this repo has

### DEPLOY: `docs/a-wait-longer-than-a-minute-parks-the-branch-v1`

A session that has to wait on somebody else's clock now parks the branch and stops, instead of holding the
turn or hovering over a backgrounded log. The rule is keyed on **whose clock it is** rather than on a
duration: a gate the session must run itself is run however long it takes, and a CI leg, a remote check or a
queue is not waited on at any duration. It lands in Chris's portable persona body, so every consumer of this
workflow receives it.

**And parking now ends on the trunk.** Pushing the branch protects the work; it does not tidy the checkout,
and a close-out made from a feature branch tells the requester two different things at once -- the terminal
says the context can be cleared, `git status` says the work is mid-flight. So `git checkout main` is the
closing act, and the tension with the known trap in the other direction -- a clean trunk reads as *ready*,
which is why the branch check exists at the start of every assignment -- is written down beside it rather
than left to be rediscovered.

Two mechanical consequences land with it in
[`CONTRIBUTING.md`](CONTRIBUTING.md). **The repo's standing gates are no longer written as TEST steps**:
`open-pr` refuses to push while a step above DEPLOY is open, so a step reading *"all suites green"* can only
ever be ticked by a hand-run of the very gate `open-pr` is about to run itself. And **backgrounding a ship is
followed by nothing at all** rather than by a judgement call -- a lane where the session has been given more
work, and otherwise a close-out.

The pre-run this repairs was measured in the session that filed
[#1060](https://github.com/DaveKJohn/claude-code-specialists/issues/1060): the suites exceeded the 120s
foreground timeout and had to be backgrounded twice, while `open-pr`'s own gate ran them in 59s and 60s
immediately afterwards. The report's explanation for that gap was wrong -- it named an in-process pass that
does not exist -- and the two mechanisms that do explain it, the parallel pool of #512 and the gate-evidence
record in `scripts/lib/gate-lib.ps1`, are now written down where the claim is made.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches the subscriber of a service here: this is how a maintainer's session spends its own time.

**Score:** N/A

#### Pull Request

A wait on somebody else's clock parks the branch and ends the session
