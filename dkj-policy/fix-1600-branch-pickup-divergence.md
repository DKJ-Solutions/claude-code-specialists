## fix/1600-branch-pickup-divergence

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

Issue [#1600](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1600): two sessions ran
the same pre-PR review on `feat/plugin-version-overview` in full, from one handoff note, and each found
real defects the other missed. The report leaves the mechanism open and names three candidates; Dave
asked for the specialist's call, and it is the first plus the read-only half of the third.

#### What was verified before building, and what it changed

- The system **already detects** this, every turn: `park-cycle.ps1` runs on the `cycle-autopark` Stop
  hook and its push is refused non-fast-forward the moment the other side pushes. `park-lib.ps1:519`
  already composes the right sentence. Measured on a two-clone fixture: git's `! [rejected]` plumbing
  and five `hint:` lines reach the session, the interpretation goes to **stderr** inside a PowerShell
  error banner, and `cycle-autopark.ps1` captured **stdout only**. The closing line hedged --
  *"run park-cycle by hand for the reason (diverged from origin?)"* -- over an answer the run held.
- A pickup-time guard for exactly this **already exists at one door**: `new-branch.ps1:434`, built for
  [#1439](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1439), the same incident class
  three days earlier. #1600 is its recurrence through a door #1439 did not cover -- a resume by plain
  `git checkout`. The park skill's own pickup section prescribed two reads and **never that command**,
  so the documented route omitted the only tool carrying the guard.
- The DAG confirms the window: both lines fork at `f276f8d0` (11:45), the other side's merge lands
  11:51, this side's autopark commits 12:05, discovery at `open-pr` ~12:20.

#### What was NOT built, and why

- **An issue per parked branch, or a claim marker in the handoff note** (the report's options 1-2). Both
  are changes to the way of working rather than defect repairs, and a structural change needs standing
  evidence, not one incident. Named here so the choice is on the record.
- **A per-turn fetch in `park-cycle`.** That reverses a decision the script states by name
  (*DELIBERATELY NO FETCH*) for a hole a failure-path fetch closes at no cost to the ordinary turn.
- **A sixth SessionStart hook.** It fires before a checkout, so it would not have caught the measured
  case at all -- the pickup it covers is a `--continue`/`/clear` on a branch already checked out. Not
  worth a hook and a network call per session start on this evidence.

### CREATE

- [x] `park-cycle.ps1`: the failure arm fetches the one ref and names the other side -- count, author and
      subject -- through the shared `Get-RemoteAheadNote`, instead of the hedged line. New dot-source of
      `remote-ahead-lib.ps1`, the same composer `new-branch` and `open-pr` already use.
- [x] `park-lib.ps1`: `Invoke-GitPark -NoFailureMessage`, so the caller that reports better can suppress
      the banner. `park-branch.ps1` does not pass it and is unaffected.
- [x] `cycle-autopark.ps1`: capture the child's stderr as well (`2>&1` + `ToString()`), so no future line
      of park-cycle's can be lost to the stream it chose.
- [x] `skills/park/SKILL.md`: the pickup section now opens with the resume **command** and why
      `git checkout` is not it, and the park-cycle section shows the new report.
- [x] Mirrors rebuilt via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `park-cycle.tests.ps1` (p): a real two-clone collision under a second identity -- the report names
      who and their subject, says what it means and what to do, and no longer says `(diverged from
      origin?)` or carries a PowerShell error banner. Section (o) proves the arm is reached; it could not
      see what the arm printed, and an amend fixture cannot tell a collision from your own autopark.
- [x] `cycle-autopark.tests.ps1` -- new: the hook had **no** suite at all. Pins its own contract via
      `-ScriptOverride` stubs: both streams captured, a merged ErrorRecord stringified, exit 0 whatever
      the child did, silence when there is no script.
- [x] Lint gate green; all 76 suites green in 399s.

### DEPLOY: fix/1600-branch-pickup-divergence

A branch resumed from a handoff note now learns that another session is already on it -- at the moment
of pickup, and again on every turn after it.

Two sessions had run the same pre-PR review on one parked branch in full, each finding real defects the
other missed, and neither learned of the other until the push at the very end. The signal existed for
half an hour: `cycle-autopark`'s push is refused the moment the other side pushes, every turn. What was
missing was delivery. The refusal now fetches that one ref and **names the other side** -- how far
behind, and the remote tip's author and subject, which is what separates a collision from a
fast-forward of your own autopark -- where it used to say *"run park-cycle by hand for the reason
(diverged from origin?)"* and send the reader for an answer the run already held. The Stop hook carries
the child's stderr into its report, so no line park-cycle writes can be lost to the stream it chose.

And the pickup route that carries the guard is now the one the documentation prescribes: `park`'s
"picking a parked branch back up" opens with `new-branch.ps1 -Name <the parked branch>` -- idempotent,
and the only resume that counts the gap and names the tip -- instead of leaving `git checkout` as the
implied route, which is the door this incident came through three days after
[#1439](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1439) closed the other one.

**Score:** 4

#### What makes this deploy extra special

Every consumer of this workflow runs `cycle-autopark` on every turn, so this changes what their sessions
are told at the moment two of them collide -- and duplicated work is expensive in a way wasted tokens
are not: the measured pair each found defects the other missed, so either winning outright would have
shipped a bug. It arrives on a plugin update with nothing to adopt.

**Score:** 4

#### Pull Request

A resumed branch learns another session is on it, at pickup and every turn

