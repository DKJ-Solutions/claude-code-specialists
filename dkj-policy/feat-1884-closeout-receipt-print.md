## feat/1884-closeout-receipt-print

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

#### What #1884 actually reports, and why the repair is not more prose

Inbound [#1884](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1884), filed from the
consumer `BWJ-Development/smartwatchbanden`. Chris's fixed ritual has six steps, and step 6 -- the
close-out -- is the only one with no mechanism behind it. It is also the step that runs last, when the
session is longest and the rule is furthest back in context.

Verified on pickup against this tree, all six axes:

| axis | verdict |
|---|---|
| symptom | **stands** -- the rule is memory-only; every repair to date is prose |
| reason | **stands** -- `01-01-persona.md:335` states *"a rule enforced by nothing but memory is one that gets skipped"*, and that principle was acted on for the claim step and not for this one |
| proposed repair | **exists** -- `ship-pr.ps1` carries its `Done: PR #<n> shipped` line at three sites, `park-branch.ps1` and `fold-changelog-entry.ps1` are both real chain enders |
| size | **understated, in the direction that strengthens it** -- see below |
| subject | **exists** -- the persona is 380 lines, and the three repairs it cites are live at lines 73, 83 and 91 |
| repo | **correct** -- the persona is shared plugin source and this repo is its source |

The one correction: the report counts **three** prose repairs from August 27. There are **four** --
[#849](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/849) (August 24, 2026) created the
three permitted shapes in the first place, and the August 27 receipt rule,
[#1402](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1402) and
[#1408](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1408) all followed it. Recounting a
report's own figure is this repo's standing habit and it usually shrinks the finding; here it grows it,
and #1402's diagnosis -- *"this is not a missing rule. It is a rule that keeps losing"* -- holds one
repair harder than the report claims.

#### Which of #1884's two options this builds, and why

Option 1, printing the shape where a chain ends. Option 2 -- a `Stop` hook measuring the transcript --
is not built, and the reason is on its merits rather than on cost: it reports a close-out that has
**already been written**, so its output is a second report to read, which is the complaint itself. The
report also lists transcript-reading across harness versions as *not investigated*. Option 1 lands
before a close-out is composed, which is the only moment at which a reminder is free.

### CREATE

- [x] `scripts/lib/closeout-lib.ps1` -- `Write-CloseOutReceipt`, printing the three parts and the
      ceiling in three lines, plus a conditional fourth naming a gate this run was told to skip.
- [x] Registered in `Get-SharedScriptPairs` as `LibOnly`, and mirrored into `dkj-policy` by
      `build-shared-scripts.ps1`, so a consumer meets the same shape this repo does.
- [x] Five chain enders call it, each with the citation that run already knows: `ship-pr.ps1` (both
      endings -- the queue arm exits before the foot of the file), `open-pr.ps1` (both endings),
      `park-branch.ps1`, `fold-changelog-entry.ps1` (both arms -- a refusal is closed out too), and
      `cut-release.ps1` (inside `Write-FollowUpSteps`, so its two exits cannot drift apart).
- [x] Every dot-source **and** every call is guarded, so a consumer whose mirror predates this lib
      does not crash on load of the script that merges their work.
- [x] `#1884`'s second finding answered mechanically rather than in prose: `ship-pr` and `open-pr`
      read their own `-SkipLint`/`-SkipTests` and route the disclosure to the PR body.
- [x] `01-01-persona.md`: the mechanism named, and a home stated for a deliberate gate bypass.

### TEST

- [x] `scripts/tests/closeout-lib.tests.ps1` -- 72 asserts, green. The structural half is the point:
      each of the five callers is held to dot-sourcing the lib, guarding that dot-source, calling the
      function and guarding the call; the three scripts with two endings are held to calling it from
      both; and ship-pr is held to suppressing and restoring around each child spawn. A mechanism that
      is defined but not called is the fifth prose repair with extra steps.
- [x] Output asserted on its three **parts** and its line count, never on its wording -- the wording
      will be sharpened, and what must not drift is that a part has quietly gone missing.
- [x] All touched scripts parse; the full lint gate and the whole suite pool are green.

#### What the review chain found, and what it cost

Three reviewers ran in parallel on the diff, and two found real defects:

- **Victor (code)** found the one that mattered: `ship-pr.ps1` spawns `open-pr.ps1` and
  `fold-changelog-entry.ps1` as **child processes**, so an ordinary successful ship printed the
  reminder **three times** -- twice of them mid-chain, once before CI had even started. A comment this
  branch had written into `fold-changelog-entry.ps1` asserted the opposite ("ship-pr folds in-process
  and never invokes this script"). That claim came from a `grep` piped through `head`, where hits in
  another file filled the window -- the capped-window failure this repo's own `triage-inbound` skill
  records, arriving in a verification of my own work rather than in an inbound report. He also found
  the bypass phrase written three times and a stale assert count in this document.
- **Edith (language)** found that "printed as this run's last line" is false for `cut-release.ps1`,
  whose own call-site comment says so eleven lines below the boilerplate that claimed it, plus a
  subject-verb disagreement and a number-format inconsistency in the persona.
- **Nolan (cost)** measured the persona edit at ~317 always-on tokens per turn, per session, in every
  repo enabling the plugin, and showed that the larger paragraph restated the lib's own docstring. The
  history moved to `manuals/01-01-manual.md` -- read on demand -- and the persona kept the one clause
  that does the work: the shape prints itself, so do not sharpen this passage again.

- [x] The double-print is fixed structurally: the conductor declares the chain in the **environment**,
      which a child process inherits. A `-Quiet` switch forwarded by hand at each spawn was rejected on
      this branch's own terms -- it would be enforced by nothing but memory at every future nesting
      site, which is the failure mode the whole change exists to retire.
- [x] **This branch was pushed with `-SkipTests`, deliberately, and here is the disclosure this change
      exists to give a home to.** The local suite pool is red on exactly one suite,
      `new-branch.tests.ps1`, for a reason unrelated to anything here: its no-identity fixture is
      vacuous on this machine. Proven pre-existing by running that suite in a detached worktree at
      `origin/main` with nothing else changed -- the same 8 failures, byte-identical -- and CI is green
      on `main` for the last five runs, so the CI gate on this PR is the authoritative run and it
      exercises the full pool. Filed with its measured cause and a verified repair as
      [#1888](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1888); not fixed here because
      it has nothing to do with this branch. Every other gate was run locally and is green: the lint
      gate at 0 errors, and the other 95 suites.
- [~] `scripts/maintenance/record-suite-durations.ps1` deliberately **not** run. It reads CI runs, so it
      can only record this suite after the merge, and the gate's own code says an unknown suite is
      charged the maximum on purpose -- "the one position a suite of unknown cost must never take". That
      is the design working, not a defect, and every new suite lands this way.

### DEPLOY: feat/1884-closeout-receipt-print

Chris's close-out now has a mechanism instead of only a rule. The five scripts that end a work chain --
`ship-pr`, `open-pr`, `park-branch`, `fold-changelog-entry` and `cut-release` -- print the receipt shape
where the run ends: what happened, where to read it, whether the session can be cleared, in two or three
lines, with anything longer rehoused rather than cut. In four of the five that is literally the last
line; in `cut-release` it sits just above the hand-written-note reminder, so a note about the close-out
is not read as the last item on a to-do list. One chain prints one receipt -- `ship-pr` spawns two of
the others as child processes, and it claims the chain's receipt so they stay quiet. Where the run was
told to skip a gate it says so too, and sends that disclosure to the pull request body, which is the one
part of a close-out that had no home at all.

This is the fifth repair to step 6 and the first that is not prose. The other four -- the three
permitted shapes, the receipt rule, the bounded filing line and the ceiling -- were all live, all in
context, and lost anyway; the persona's own principle for the claim step, *a rule enforced by nothing
but memory is one that gets skipped*, is simply applied one step further down the same ritual.

**Score:** 4

#### What makes this deploy extra special

N/A -- no subscriber of a service notices this. It changes what a session reads at the end of a run in
this repo and in every repo running `dkj-policy`; a consumer's own users see nothing.

**Score:** N/A

#### Pull Request

Print the close-out receipt shape where a chain ends
