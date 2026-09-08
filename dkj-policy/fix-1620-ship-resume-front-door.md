## fix/1620-ship-resume-front-door

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

#### What #1620 is, and the reason verified before anything was written

Step 2b hands the primary checkout back to the trunk the moment the PR exists (issue #1073), and the
front-door check at `scripts/release/ship-pr.ps1:393` refuses a re-run with `You are on main; ship-pr
runs from a branch.` Both are in the tree as reported. So for the whole CI wait -- the longest step in
the run -- the checkout stands on `main` while the branch's merge and fold are still owed, and a
process that does not survive that wait prints **nothing**: no refusal, no remedy, no next line. The
sentence the operator needs is in the script, in a comment at the dropped-watch retry block that
nobody reads at that moment.

#### Which of the three candidate shapes, and why the other two are declined

**Shape 2 -- recognise the state at the front door.** It is the only one that reaches the measured
state: the process was killed by the host, which takes the scrollback with it, so a session resuming
has nothing but the refusal in front of it. It is also the half of the finding that is a defect rather
than a gap -- *the refusal names the wrong problem* -- and a refusal that diagnoses is what #1588,
#1234 and #1044 each turned their own wrong-problem message into.

**Shape 1 -- a fifth line in the step-3 preamble -- is declined.** It is on screen only while the
scrollback survives, which is exactly what the measured failure mode destroys, and it would pay one
more always-printed line on every ship for the case where the operator interrupts deliberately and
still has the terminal. The preamble is at five lines already and #1428 measured what happens when the
reader stops reading it.

**Shape 3 -- document it and change nothing -- is declined**, but half of it is kept: the skill page
gains the paragraph either way, because the front door can only diagnose where `gh` answers.

### CREATE

- [x] `pr-issues-lib.ps1`: `Get-InterruptedShipCandidates` -- the pure parse of a `gh pr list --state
      open --json number,headRefName` payload against the checkout's own `refs/heads`, newest PR first
- [x] `pr-issues-lib.ps1`: `Get-InterruptedShipResumeNote` -- the wording, `''` when there is no
      candidate, so a diagnostic is never the reason a refusal cannot be printed
- [x] `ship-pr.ps1`: the `You are on main` front door reads both, best-effort, and names the branch
      and the checkout command instead of refusing on the general rule alone
- [x] the printed `git checkout` takes its ref through `Get-PasteableRef` (#1594) like the sites that
      already do -- a head ref name here is chosen by whoever opened the PR
- [x] `scripts/sync/build-shared-scripts.ps1`, so the plugin mirror matches the source
- [x] the `ship-pr` skill page: the resume paragraph under its #1073 section

### TEST

- [x] `pr-issues.tests.ps1`: the candidate parse (no open PR, a head ref that is not in this checkout,
      one, several and their order, the trunk excluded, an absent field, unparseable JSON, the cap) and
      the note (`''` on an empty list, the checkout command, the refused-name arm)

### DEPLOY: fix/1620-ship-resume-front-door

A `ship-pr` run whose process does not survive the CI wait can be resumed from the checkout it was
interrupted in. Step 2b puts that checkout back on the trunk as soon as the PR exists (#1073), so the
re-run used to meet `You are on main; ship-pr runs from a branch` -- a refusal about the wrong problem,
in a state where the killed process has usually taken the scrollback with it. The front door now asks
whether an open PR exists whose head branch is in this checkout, and where it finds one it names the
PR, the branch and the `git checkout` that resumes the ship, instead of refusing on the general rule.
It stays best-effort: where `gh` cannot answer, the refusal is exactly the line it has always been.

**Score:** 3

#### What makes this deploy extra special

Every consumer of this workflow ships with the same script and the same step 2b, so the same
interrupted ship is recoverable there without reading the source repo's issues -- and a consumer is
where it is most expensive, because their operator has no `ship-pr.ps1` in front of them to read the
comment the diagnosis used to live in.

**Score:** 3

#### Pull Request

ship-pr names the interrupted ship's branch at the front door instead of refusing on 'You are on main'
