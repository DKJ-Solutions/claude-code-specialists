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

**The first half of that landed while the positive half was blocked on a measurement nobody had taken**:
whether a `/clear` leaves the backgrounded run alive. The ancestry rules out quitting the harness and says
nothing about `/clear`.

**That measurement is no longer load-bearing, and the branch is finished without it** (Dave, on the issue,
September 5, 2026): *"ik kan in VSC gewoon meerdere terminalen openen met claude"*. A **second terminal**
answers the real question -- how to get on with the next issue -- without asking anything of the process.
Terminal 1 stays alive, so the merge and the fold complete **and** the completion notification lands in a
conversation that still exists; terminal 2 carries the next issue, so nobody waits. That dissolves both open
steps at once: the positive statement stops depending on the `/clear` row, and the vanished-notification
blocker stops needing one of its four options.

**One timing rule comes with it**, and the ship already prints its own go-ahead: step 1 is the only step
that reads the working tree, so this checkout is single-occupancy for that minute (#1145, measured on
PR #1144). `ship-pr: waiting for the CI check(s) on PR #N` is therefore the line that says the tree is
free -- read at exactly the moment the reader is about to act on it.

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
- [x] SAY IT POSITIVELY, and without the measurement. `ship-pr.ps1` prints what the reader MAY do --
      leave this one running, carry on in a SECOND terminal, open it in a lane -- and names this very
      line as the go-ahead, because step 1 is the only step that reads the working tree.
- [x] `ship-pr.ps1`: the comment block records why a second terminal replaces the `/clear` question
      rather than answering it, and the #1145 timing rule that makes this line the right place for it.
- [x] Chris's persona body: *say what they MAY do*, portable -- a second session beside the running one
      frees the person rather than the process, and the running one is where the outcome is delivered.
- [x] `ship-pr` skill page: the second-terminal route in full -- the timing rule quoted as the line to
      wait for, the lane, the tracker claim between two sessions, and what stays unmeasured.
- [x] Rebuild the plugin mirror again after those edits.
- [~] The vanished notification, shapes 1-3 -- dropped: the second terminal solves it rather than
      mitigating it, because terminal 1 is still there when the completion lands. The four options stay
      on the issue for a reader who has no second terminal; none is built here.
- [~] Shape 4 -- revisiting the detached watcher declined in #985 -- dropped here: repo-settings-
      adjacent, and the issue names it as Dave's.
- [~] The `/clear` probe -- dropped: it was set up on another machine, and this session's two attempts
      to re-run it were refused by the harness's auto-mode classifier. Nothing here claims either
      answer, which is what the issue asks for while it is unmeasured.

### TEST

- [x] The symptom and the reason verified against the tree before any edit: the line exists verbatim at
      `ship-pr.ps1:722`, and a tool-run process is a direct child of `claude.exe`
      (`powershell.exe <- claude.exe <- powershell.exe <- Code.exe <- Code.exe <- explorer.exe`).
- [x] No test or doc pins the old printed string, so nothing else had to move.
- [x] `ship-pr.ps1` parses clean after the edit (`[Parser]::ParseFile`, 0 errors).
- [x] `check-plugin-integrity.ps1` green: 0 errors across all 30 checks. The suites are `open-pr`'s own
      gate and run at the push, so they are not a step here.
- [x] The single-occupancy claim re-verified before it was printed as advice: `ship-pr.ps1`'s own step
      list and `open-pr.ps1:161` both state it, and PR #1144 is the measurement behind it. So the
      printed go-ahead names a rule the script already documents rather than a new one.
- [x] `worktree-lane.ps1 -Name` verified to exist as printed, and the lane's detached-at-`origin/<trunk>`
      property (#1069) re-read before it was cited as the reason it does not disturb step 5's fold.
- [x] Re-run after the second round of edits: parse 0 errors, lint 0 errors across all 30 checks.

### DEPLOY: fix/1428-ship-invitation-honest

`ship-pr` told you *"nothing here needs the session"* before it backgrounded the CI wait, and the session
is exactly what it needs. The run is not detached — that was declined on purpose in #985, because a
detached watcher would merge and fold onto the trunk with nobody reading the output — so it is a child
process of the harness and dies with it, with two commits still owed. The invitation now says *"nothing
here needs **you**"*, names what it holds, and — the half that matters more — **says what you may do
instead of only what you may not**: leave this one running and carry on in a second terminal, opened in a
lane. Withholding a clearance and offering nothing in its place cancels backgrounding at the one place the
reader reads it, which is how a line written to free the session came to block the workflow it was for.

The go-ahead is printed rather than remembered: step 1 is the only step that reads the working tree, so
`ship-pr: waiting for the CI check(s) on PR #N` is itself the signal that the checkout is free (#1145,
measured on PR #1144). The `/clear` question is deliberately left unanswered — the process hangs off
`claude.exe` rather than off the conversation, but nobody has measured it, and a second terminal removes
the reason to.

**Score:** 3

#### What makes this deploy extra special

Consumers running `contributing-davekjohn` read that line on every ship, and the orchestrator's own rule
is what their close-outs are written from. Both are corrected here: the parking justification is bounded
to a *parked* branch — where the branch, its plan and the pull request genuinely outlive the session — and
"cleared" is now said precisely and never conditionally, because *"the session can be cleared once the
ship lands"* is shape A with a string attached. The failure being prevented is narrow and real: a quit
between the merge and the fold strands the branch's document on the trunk, which is #1270's defect by a
route #1270 did not consider. And the persona now carries the positive half too, portably: a requester who
backgrounded a wait wants the *next* thing, so the answer is a second session beside the running one rather
than a clearance of it — strictly better, because the one still running is where the outcome gets
delivered. Two sessions share nothing but the tracker, so the claim rule already in that body is what keeps
the second one off the first one's work. It costs ~2.2 KB on the always-on persona path.

**Score:** 3

#### Pull Request

The backgrounded ship's invitation says what it actually holds
