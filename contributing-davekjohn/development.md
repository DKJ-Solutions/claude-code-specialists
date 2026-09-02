## Development: `feat/asana-board-stage-sections-v1` · 20260902-120042

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

Read #1222 and #1217. Dave settled three course-defining points: section 4 = PR merged and issue not yet closed; rename the live board AND wire the workflow; resolve a section by the leading number in its name. Next: the stage model in WORKFLOW-portable.md, the section-move half of asana-mirror.ps1, report-issue step 2b, adopt-bwj-asana, tests, then the board rename.

#### What Dave settled before any of this was written

Three course-defining points, answered in the session rather than guessed at:

1. **Stage 4 is `PR merged, issue not yet closed`.** The alternative readings collapsed 4 into 5,
   because merging closes the issue in the same second. This one gives every section real occupancy
   and makes his own gate sentence -- *"pas als issue closed is mag het naar de volgende stap"* --
   the exit condition of 4.
2. **Rename the live board AND wire the workflow**, not one or the other.
3. **Resolve a section by the leading number in its name**, not by six configured GIDs.

And one more, mid-branch: **`Development BWJ` is retired -- only `Workload Overview` is used.** That
collapses the *"which board, and what happens to the others"* edge inbound #1217 was corrected on by
hand, so this branch writes a one-board rule rather than a two-board one.

### CREATE

- [x] `asana-mirror.ps1`: five pure helpers -- `Get-StageFromSectionName`, `Test-StageIsWritable`,
      `Select-StageMembership`, `Get-StageFloorForIssue`, `New-AsanaSectionMoveRequest`
- [x] `asana-mirror.ps1`: `Get-ProjectStageSections` (cached per run) and `Sync-AsanaTaskStage`
      (eight guards, forward-only)
- [x] `asana-mirror.ps1`: `Get-IssueClosure` generalised to `Get-IssueLinkState` -- one GraphQL query
      now answers for an open issue too, carrying `state` and `merged` per linked pull request
- [x] `asana-mirror.ps1`: sweep (d), `Invoke-StageSweep`, plus the stage move on both events
- [x] `asana-mirror.yml`: the header comment names the second kind of write
- [x] `WORKFLOW-portable.md`: step 6, the stage model; step 7 renumbered with two new person-steps;
      three new entries under "why it is shaped this way"
- [x] `README.md` (plugin): the rule paragraph, and `Get-AsanaProjectGid` now has one right answer
- [x] `report-issue`: the card is created in the `2.` section, and an imported ticket is moved there
- [x] `adopt-bwj-asana`: step 5 reports whether the board's sections are numbered, and renames nothing
- [x] Rename sections 1-4 on `Workload Overview` (5 was left alone -- see TEST)
- [~] A `-NoStageMoves` escape valve -- dropped. An un-numbered board already moves nothing, so the
      safe default exists in the mechanism and a flag would only duplicate it.

### TEST

- [x] 43 new asserts in `scripts/tests/bwj-codex.tests.ps1`; suite green at 128
- [x] The script parses, is pure ASCII, and dot-sources without running its main flow
- [x] Every helper exercised by hand against the real board's shapes before the asserts were written
- [x] `check-plugin-integrity.ps1`: 0 errors over all 31 checks
- [~] The section-5 rename -- **not done, deliberately.** It came back as `5. Waiting`, a name that
      appeared after this branch's first read of the board, so it is Dave's own. The words after the
      number are the team's by design and the code reads only the number, so leaving it is the rule
      working rather than a gap. Reported to Dave, since #1222 calls that stage "Testfase".
- [~] An end-to-end run of sweep (d) against the live board -- not run here. It needs `ASANA_PAT` in
      a store repo's CI, and this repo is not a consumer of `bwj-codex`. It runs on the next daily
      schedule in `smartwatchbanden`.

### DEPLOY: `feat/asana-board-stage-sections-v1`

The `bwj-codex` mirror learns the half of the board a colleague actually reads: **which column a card
is in**. The board's six sections are now the ticket cycle -- from *a colleague put this on your name*
through *tracked on GitHub*, *in development*, *merged*, *ready to test*, to *tested and good* -- and
the card follows its GitHub issue's own state without anybody dragging it.

A section is recognised by the **number its name starts with**, so the words after it belong to the
team and can be rewritten any day; a board whose sections are not numbered is never written to at all,
which is what keeps this off every other board in the workspace. The two ends stay the requester's:
`Test-StageIsWritable` permits stages 2 to 5 and nothing else, and a card already in `Completed` is not
moved -- the section-move twin of the standing guarantee that nothing here ever ticks a task off. Every
move is forward, derived as a **floor** rather than a position, so the nightly sweep can never undo the
one hop only a session can see; an `issue reopened` event is the single backward move in the script.

For three of the four writable stages that sweep is not a backstop but the mechanism, because an issue
is filed, a branch opens and a pull request merges without `issues: closed` ever firing.

**Score:** 3

#### What makes this deploy extra special

For the two BWJ store repos this plugin serves, the board stops being a static list. The gap inbound
#1217 measured -- an issue filed here while the board still said `New`, so the colleague waiting on it
read their request as untouched and chased it in the one place with no answer -- is closed at the
mechanism rather than with a written reminder.

**Two setup steps are required before any of it happens, and both fail silently if skipped.** The
board's sections have to carry a leading number, and `Get-AsanaProjectGid` has to name that board --
which turns a question this page used to leave open (*one shared project or one per store?*) into a
single right answer, because the stages live on the board's sections and `Prio-Score` does not cross
workspaces. **Both** store repos currently point at the same provisional "Test" project in a different
workspace from the board -- `smartwatchbanden#470` already reports it and now carries the second
consequence; `xoxowildhearts#194` is its own.

**Score:** 4

#### Pull Request

the Asana board's six sections become the cycle's stages

