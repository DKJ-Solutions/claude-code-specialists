## Development: `feat/asana-github-status-sync-v1` · 20260902-141114

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

Dave, September 2, 2026: stages 3/4/5 are always linked to the GitHub Project statuses Todo / In Progress / Done, GitHub is the source. Board already reconciled by hand; next: make the mechanism read the Status field.

#### The three rules this branch implements

Dave stated them in four messages, and all four are in the mechanism:

1. Stages 3/4/5 are always linked to the GitHub Project statuses Todo / In Progress / Done.
2. GitHub is the source; the Asana board follows.
3. Stages 6 and 7 count as done too -- a card dragged to 6 is never synced back to 5.
4. A card reaches 6 only once the submitter has been given feedback, and where there is no
   submitter stage 6 is skipped entirely.

### CREATE

- [x] `Get-DefaultGithubStatusMap` + the `Get-GithubStatusMap` seam, validated and resolved the
      same way `Get-AsanaStageMap` is -- status names as keys, stage keys as values
- [x] `Get-StageFloorForIssue` reads the project status instead of the issue's pull requests;
      the `not_planned` guard survives, because `Item closed` sets Done whatever the reason
- [x] `Get-IssueLinkState` reads the status in the same round trip, and retries once without it
      so a missing project token costs the staging and not the close update
- [x] `Test-StageIsTerminal` -- stages 6 and 7, checked BEFORE `-AllowBackward` so a reopen
      cannot take a card back off the submitter
- [x] the feedback promotion: `Get-SubmitterFromNotes` + `Get-SubmitterHandoff` +
      `Resolve-TargetStage`, gated on a submitter existing AND having been told
- [x] `GH_PROJECT_TOKEN` in `asana-mirror.yml`, both steps

### TEST

- [x] 188 asserts green in `scripts/tests/bwj-codex.tests.ps1`, including all four rules and a
      board whose columns are renamed and renumbered, so neither map can become decoration
- [x] `check-plugin-integrity.ps1`: 0 errors
- [x] every suite, as CI runs them
- [x] the live BWJ board reconciled to the new rule by hand: the six cards whose issue is closed
      moved 6 -> 5, the twelve Todo cards already correct, the completed one left in 7
- [~] a live CI run of the sweep -- dropped: it needs `GH_PROJECT_TOKEN` on the store repos,
      which is Dave's to create, and the mechanism is proven by the suite plus the hand pass

### DEPLOY: `feat/asana-github-status-sync-v1`

The Asana board's three middle columns now follow the GitHub Project's `Status` field instead of
being re-derived from the issue and its pull requests -- `Todo`/`In Progress`/`Done` are *filed*,
*being built*, *closed*. GitHub already wrote that field through its own project workflows, so
deriving it a second time made two writers of one fact; reading it makes the two boards agree
rather than race. The stage past those is no longer a column at all: a card reaches *ready to
test* once the submitter has actually been told, and where a ticket has no submitter that stage is
skipped. Both of the last two sections are now terminal -- a card there is never taken back, not
even by a reopen.

Needs one thing per store repo: a `GH_PROJECT_TOKEN` secret. `GITHUB_TOKEN` cannot read an
organization's Projects v2 at all, so without it the close update still goes out and only the
staging goes quiet, naming the missing token in the log.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's audience is its own developers and the BWJ colleagues who read the Asana board,
and the board's behaviour is not a subscriber-facing service.

**Score:** N/A

#### Pull Request

the GitHub Project Status drives the Asana stages Filed, InDevelopment and InReview

