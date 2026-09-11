## fix/1833-suite-durations-refresh

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Narrow half of #1833 only: refresh the committed CI durations. The general proposal (a staleness detector) stays on the issue as a decision.

#### Which runs the refresh may read

`adopt-workflow-folder.tests.ps1` went from 20 to 25 `Invoke-Adopt` spawns on `fix/1829-crlf-section-drift`,
so only a run whose tree carries that fixture measures the suite as it now stands. Three of the four runs
around the merge do not qualify, for three different reasons:

- `34583740147` (push, `c9832553`) is the **fold** commit's run, and #1300 skips the suites step on a
  `fold:` commit -- it checks out and completes, printing no table at all.
- `34583531838` / `34583625816` are `fix/1830` and `fix/1831`, neither of which contains the merge
  (`git merge-base --is-ancestor` says so), so their `adopt-workflow-folder` row is still the 20-spawn one.

That leaves the branch run `34583187104` (`f238279d`) and the **merge** commit's push run `34583730524`
(`e993bdb0`) -- two draws, which is what the script's docstring asks for.

### CREATE

- [x] Re-record `scripts/tests/suite-durations.json` from those two runs
- [x] Name the fold-commit blind spot where the next caller meets it: `record-suite-durations.ps1`'s
      "printed no per-suite duration table" throw

### TEST

- [x] `test-suite-gate.tests.ps1` -- the suite that consumes this file -- green on the new one: 150 pass, 0 fail
- [x] Every `*.tests.ps1` on disk has a row: 91 files, 91 rows, and the script printed no
      "no rows for N suite(s)" warning

### DEPLOY: fix/1833-suite-durations-refresh

`scripts/tests/suite-durations.json` is re-recorded from two CI runs that carry the suite set as it now
stands, and the refresh turned out to be larger than the row #1833 was filed about. That row --
`adopt-workflow-folder.tests.ps1`, understated after `fix/1829-crlf-section-drift` took it from 20 to 25
scaffold spawns -- moves from 32.6s to 40.6s. The bigger find is the count: the file held **84** rows
against **91** suites on disk, so seven suites had no row at all and `Invoke-TestSuiteGate` was charging
each of them the largest recorded value when it packed the four shards. That is the safe direction by
design -- a new suite starts early and can never be the one left last -- but seven suites priced at 290.2s
apiece is a packing the measured pool does not support.

`record-suite-durations.ps1` also now names the one run a caller reaches for first and cannot use. A ship
pushes to the trunk twice and both pushes get a CI run; the **fold** commit's is the newer of the two, so
it sits at the top of `gh run list`, and #1300 skips the suites step on it outright. Its four suite jobs
check out, stop, and complete green, so nothing about the run says it measured nothing -- the script's
`printed no per-suite duration table` throw asked "is it a CI run that ran the suites job?" and the honest
answer was yes. It now says which commit kind to avoid and which to take instead.

What is deliberately **not** here is #1833's second half. The issue asks whether something should *report*
this staleness -- option 2, a detector comparing `recordedFrom` against the current suite set -- and calls
it a decision rather than a repair. It stays on the issue.

**Score:** 3

#### What makes this deploy extra special

N/A -- neither changed file is plugin payload. `suite-durations.json` and `record-suite-durations.ps1`
both live under this repo's own `scripts/`, are mirrored into no plugin, and so reach no consumer.

**Score:** N/A

#### Pull Request

Re-record suite-durations.json from CI runs that carry the new CRLF fixture

