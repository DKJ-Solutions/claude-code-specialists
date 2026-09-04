## fix/1428-ship-invitation-honest

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

Issue #1428, **as corrected on September 5, 2026**. The original filing read Dave's quote backwards: the
close-out did not offer a clearance it could not keep, it **withheld** one he was entitled to. His workflow
is three moves -- background the ship, `/clear`, start the next issue -- so the repair has to say
*positively* that a `/clear` is safe, not merely stop promising anything.

**That is blocked on a measurement nobody has taken**: whether a `/clear` leaves the backgrounded run
alive. The ancestry rules out quitting the harness and says nothing about `/clear`. The probe is set up and
needs one deliberate `/clear` from Dave; the protocol is in the issue.

**What is on this branch is the half that stands regardless** -- the false line, the measured ancestry, and
the bound on the parking rule. The positive half waits for the measurement rather than guessing at it.

### CREATE

- [x] `ship-pr.ps1`: the printed invitation says *"nothing here needs YOU"*, and a second line names the
      two commits still owed (the merge, then the fold).
- [x] `ship-pr.ps1`: the comment block above it records the measured ancestry, why the fold is the half
      that matters, and what is deliberately NOT claimed (that clearing the context is safe — inferred
      from the ancestry, never measured).
- [x] Rebuild the plugin mirror — `scripts/sync/build-shared-scripts.ps1`.
- [x] Chris's persona body: bound the parking justification to a PARKED branch, and say "cleared"
      precisely and never conditionally.
- [x] `ship-pr` skill page: *"stop" is not "quit"*, with the ancestry and the fold named.
- [ ] BLOCKED ON THE MEASUREMENT: say it positively. Once the probe answers, the printed line and
      Chris's close-out rule state that a `/clear` is safe during a ship and that quitting Claude Code
      or closing the terminal is not. Naming only what is unsafe is what the corrected issue rejects.
- [ ] BLOCKED ON DAVE: the vanished notification. Even if the process survives, the completion lands
      in a conversation that no longer exists, so the outcome reaches nobody. Four options are in the
      issue and the choice is his.
- [~] Shape 4 -- revisiting the detached watcher declined in #985 -- dropped here: repo-settings-
      adjacent, and the issue names it as Dave's.

### TEST

- [x] The symptom and the reason verified against the tree before any edit: the line exists verbatim at
      `ship-pr.ps1:722`, and a tool-run process is a direct child of `claude.exe`
      (`powershell.exe <- claude.exe <- powershell.exe <- Code.exe <- Code.exe <- explorer.exe`).
- [x] No test or doc pins the old printed string, so nothing else had to move.
- [x] `ship-pr.ps1` parses clean after the edit (`[Parser]::ParseFile`, 0 errors).
- [x] `check-plugin-integrity.ps1` green: 0 errors across all 30 checks. The suites are `open-pr`'s own
      gate and run at the push, so they are not a step here.

### DEPLOY: fix/1428-ship-invitation-honest

`ship-pr` told you *"nothing here needs the session"* before it backgrounded the CI wait, and the session
is exactly what it needs. The run is not detached — that was declined on purpose in #985, because a
detached watcher would merge and fold onto the trunk with nobody reading the output — so it is a child
process of the harness and dies with it, with two commits still owed. The invitation now says *"nothing
here needs **you**"* and names what it holds, and the comment block carries the measured ancestry beside
the decline it contradicts. It also records what is deliberately not claimed: that clearing the context is
safe while quitting is not follows from the ancestry but was never measured, and a line telling a reader
which of two things they may do has to be right about both.

**Score:** 3

#### What makes this deploy extra special

Consumers running `contributing-davekjohn` read that line on every ship, and the orchestrator's own rule
is what their close-outs are written from. Both are corrected here: the parking justification is bounded
to a *parked* branch — where the branch, its plan and the pull request genuinely outlive the session — and
"cleared" is now said precisely and never conditionally, because *"the session can be cleared once the
ship lands"* is shape A with a string attached. The failure being prevented is narrow and real: a quit
between the merge and the fold strands the branch's document on the trunk, which is #1270's defect by a
route #1270 did not consider. It costs ~1.5 KB on the always-on persona path.

**Score:** 3

#### Pull Request

The backgrounded ship's invitation says what it actually holds
