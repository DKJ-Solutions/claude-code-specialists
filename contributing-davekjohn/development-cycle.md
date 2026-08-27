## Development cycle: `fix/park-names-what-backs-the-ticks-v1` · 20260827-123735

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

Closes #960: park-cycle stamps what backs the resolved steps into the park commit, and session-status reads it back.

#### The gap, in one sentence

`#900` publishes the branch's plan so a second device can read it, and on a branch whose work is
uncommitted in the other device's working copy it publishes a plan that says the work is done with
nothing behind it. The two states -- ticked-and-committed and ticked-and-uncommitted-elsewhere -- are
indistinguishable from origin, and the more complete the ticks, the more convincing the wrong reading.

#### Where the mechanism goes, and why not the other two places

Dave named three candidates in the issue: the autopark commit body, the step gate or `session-status`,
or nothing. The commit body is the writer, because it is the only place where the fact is **known and
true at the moment the misleading state is created** -- park-cycle runs on the device that holds the
uncommitted work, so it can count what nobody else can see. It is also purely local: no fetch, no
network, no second measurement to keep in step.

`session-status`'s parked-branches block is the **reader**, and it re-measures nothing -- it echoes the
stamped line back, so there is one measurement with one owner. Where the remote-tracking ref has not
been fetched it says so rather than staying blank, which is this script's own convention.

The document itself is deliberately NOT written to. An automatic writer editing the branch's plan
would fight the author's own edits on the same file park-cycle is staging.

#### The bound on the note

Counts only, never filenames. The uncommitted figure describes work nobody asked to publish, and a
park commit that listed those paths would leak the shape of unrelated work into a public branch --
the same reasoning as bound 1 (one document, never `git add -A`), one layer along.

#### And the warning fires on the finished shape only

`Open == 0 -and Resolved > 0 -and committed-besides == 0`. Firing on any resolved step with no commit
behind it would fire on nearly every early park -- a planning step ticked before any code exists is
the normal case -- and a warning that fires on almost every park is a warning nobody reads by the
time it matters. The neutral `Backing:` line carries the numbers in every other case.

### CREATE

- [x] `Get-BranchProgressTally` in `scripts/lib/entry-scaffold-lib.ps1`: the step counts (open, done,
      dropped) off a branch document, sharing one line-preparation helper with
      `Get-BranchProgressFindings` so "what counts as a step" stays one answer
- [x] `scripts/lib/park-lib.ps1`: `Get-GitParkBacking` (measure), `Format-GitParkBacking` +
      `Get-GitParkBackingMarker` (the words, stated once), and `-BodyNote` on `Invoke-GitPark` so the
      generated fact does not have to travel through `-Intent`, which means a human's parking note
- [x] `scripts/task/park-cycle.ps1`: measure before the park and pass the note
- [x] `scripts/task/session-status.ps1`: the parked-branches block reads the stamped note back
- [x] mirror both libs and both scripts via `scripts/sync/build-shared-scripts.ps1`
- [x] `plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md`: the park commit's body, and
      the pickup route that reads it
- [x] the `park` skill: the second pick-up trap, beside the overtaken-plan one it already carried, plus
      the `git log -1 --pretty=%B origin/<branch>` command that answers it
- [x] `.claude/specialists/lenses/05-05-extension.md` (Derek, branch & repo hygiene): picking up a
      parked branch reads the backing line before rebuilding anything

#### Three things this branch found that were not in the plan

- [x] **`session-status` was listing the trunk as a parked branch**, and the assert that should have
      caught it was a false green. It resolved the trunk from `refs/remotes/origin/HEAD` alone -- a ref
      that does not exist in a repo initialised locally and wired to a remote afterwards -- and fell back
      to the literal `main`, so every repo whose trunk is named otherwise saw its own trunk listed. The
      suite's negative assert had been passing on a newline-removal artefact: `Get-FlatOutput` joins
      lines without a space, so `master` and the next section's `Open` ran together and `\b` never
      matched. Repaired both: the trunk now comes from `git ls-remote --symref`, which asks the remote
      rather than a local ref and needs no seam, and the assert reads the printed block instead of the
      flattened report. **Fixed inside the assignment rather than filed** -- it is one resolution in the
      block this branch is already editing, and my new second line per branch is what exposed it.
- [x] **The uncommitted count was measured with git's default untracked mode**, which collapses an
      untracked *directory* to one entry naming the directory. On the first park of a branch, where the
      cycle document's folder is itself new, the one path the measurement must EXCLUDE never appears and
      its parent is counted as unpublished work instead. Caught by this branch's own suite on the
      ordinary happy path: 2 uncommitted files reported where there was 1. `--untracked-files=all`.
- [x] **The reader had to state an absent note**, not skip it. A blank under a branch whose plan reads
      as finished is the #960 ambiguity one layer up: silence looks like "nothing is wrong" where it
      means "nobody wrote it down". So a parked branch whose last commit carries no note says so.

### TEST

- [x] `scripts/tests/entry-scaffold.tests.ps1`: the tally, incl. fence- and comment-awareness and the
      DEPLOY split (a checkbox in the entry's prose is not a step) -- and every fixture measured BOTH
      ways, because the failure worth catching is the tally and the gate disagreeing rather than a wrong
      number. 552 -> 568 asserts.
- [x] `scripts/tests/park-cycle.tests.ps1`: the neutral line, the warning on the finished shape, the
      absence of the warning on a half-done plan, and that the note is body rather than subject so
      `git log --oneline` stays readable. 45 -> 64 asserts.
- [x] `scripts/tests/session-status.tests.ps1`: the readback through the REAL formatter (a hand-typed
      fixture would keep passing after a rewording had already stopped writer and reader from meeting),
      the honest line when the ref was never fetched, the honest line when there is no note, and the
      trunk assert repaired above. 61 -> 70 asserts.
- [x] `scripts/lint/check-plugin-integrity.ps1`: 0 errors. All 53 suites run standalone, all green --
      the stricter direction, since the language rule's warning is about a suite that is green only
      under the shared-console gate.

### DEPLOY: `fix/park-names-what-backs-the-ticks-v1`

Every automatic park commit now says what is behind the plan it publishes. `park-cycle` measures three
figures before it commits -- how many of the document's steps are resolved, how many files are committed on
the branch besides that document, how many are uncommitted in the working copy the park came from -- and
writes them into the commit body as a `Backing:` line. Where the plan reads as **finished** with nothing
behind it, an alarm paragraph says so in as many words and names the wrong move. `session-status` prints the
note back under every parked branch, so `/lock` and `/handover` surface it without a checkout, and says
plainly where there is none.

The state it exists for was measured here on August 27, 2026
([#960](https://github.com/DaveKJohn/claude-code-specialists/issues/960)).
`feat/adopt-act-on-this-skills-v1` sat on origin with three `park:` commits, eight resolved CREATE steps
naming edits to three agent defs, three manuals and two lenses -- and a diff against `main` consisting of
the cycle document alone, 161 insertions, one file. The edits were uncommitted in the other device's working
copy, which no reader of origin can see. `#900` publishes the plan so a second device can read it, and on
that branch it delivered the plan and inverted its purpose: from origin, *ticked and committed* and *ticked
and uncommitted somewhere else* are the same document, and the more complete the ticks, the more convincing
the wrong reading. A session picking it up in good faith either rebuilds eight changes that already exist,
or opens a PR that merges 161 lines the fold then deletes.

Four bounds decide the shape, and each of them was the alternative. **It is a note, never a gate** -- a park
that refused because it disliked the plan would be worse than the misleading document, because then the plan
would not reach the other machine at all. **Counts, never filenames** -- the uncommitted figure describes
work nobody asked to publish, and listing those paths would defeat bound 1 (one document, never
`git add -A`) one layer along. **The alarm fires on the finished shape only**: any resolved step with nothing
committed would fire on nearly every early park, because a planning step ticked before a line of code exists
is the ordinary case, and an alarm that fires on almost every park is one nobody reads by the time it
matters. **And the measurement lives on the machine that holds the invisible work**, taken at the moment it
becomes invisible -- nowhere else can take it, since from origin those files do not exist. That is also why
the reader only echoes the line: a local recount would report 0 for a branch whose commit says 12, and the
wrong number would be the confident one.

The branch also repaired a defect it exposed rather than filing it, because it is one resolution in the block
being edited: `session-status` was **listing the trunk as a parked branch**. It read the trunk from
`refs/remotes/origin/HEAD` alone -- a ref a locally-initialised repo does not have -- and fell back to the
literal `main`, so any repo whose trunk is named otherwise saw its own trunk in the one block that exists to
show work that is *not* on the trunk. The suite's negative assert had been passing on a newline-removal
artefact, with `master` and the next section's `Open` running together into one word so `\b` never matched.
The trunk now comes from `git ls-remote --symref`, which asks the remote rather than a local ref and needs no
seam, in the same call the branch list comes from.

For somebody maintaining this repo the gain is that a parked branch can no longer lie about itself, and the
cost is a handful of lines in a commit body nobody has to read. It is a 3 rather than higher because it
changes no chain and blocks nothing -- but the state it describes has already cost one triage here, and the
next reader of that branch would have paid for it in rebuilt work.

**Score:** 3

#### What makes this deploy extra special

The same mechanism through a plugin update, and for a consumer the exposure is larger rather than equal: the
two-device split this was measured on is the ordinary shape of working from a laptop and a desktop, and
`park-cycle` runs on their Stop hook exactly as it does here. What arrives is `park-cycle.ps1`,
`session-status.ps1` and both libs behind them, so nothing has to be configured -- `Get-GitParkBacking`,
`Format-GitParkBacking` and `Get-GitParkBackingMarker` are available to any other script of theirs that has
to judge whether a plan has work behind it, and `Get-BranchProgressTally` answers "how does this step list
stand" for any caller that until now had only the gate's yes-or-no.

The trunk repair reaches them harder than it reaches this repo, which is the part worth reading twice. This
repo's trunk is `main` and its checkout was cloned, so `refs/remotes/origin/HEAD` exists and the defect never
fired here. A consumer who ran `git init` and added a remote afterwards has no such ref, and one whose trunk
is `master` -- or any name that is not `main` -- has been seeing their own trunk reported as a parked branch
every time they ran `/lock` or `/handover`. That is the single most misleading line the block can print: it
sends a reader looking for work on the one branch where the work has already landed.

The `park` skill's pick-up section gains its second trap beside the one it already carried. The first asks
whether a parked plan has been **overtaken** -- measured August 4, 2026, a plan superseded 1h43m after it was
parked. This one asks whether it was ever **carried out**. The two are independent and both are one command;
a plan can pass either and fail the other, and the skill now says so with the command that answers each.

**Score:** 3

#### Pull Request

The park commit names what is behind the ticks

