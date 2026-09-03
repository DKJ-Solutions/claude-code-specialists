## Development: `fix/ship-pr-stale-ci-certificate` · 20260903-132226

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

A green required check certifies the merge of the branch into main AS OF THE MOMENT THE RUN STARTED. pull_request does not re-fire when the base moves and the main ruleset is non-strict, so a check that went green before main advanced still satisfies the gate hours later. Issue #1292. Add a pre-merge staleness check to ship-pr.ps1 keyed on whether main has moved since the green run -- NOT on whether the branch is behind, which over-fires.

### CREATE

- [x] Measured the RIGHT predicate before building anything, on the last 45 merged PRs into `main`
  (`gh pr list` + `gh api .../actions/runs` + `git log --first-parent`, script kept in the session
  scratchpad, not committed): 14/45 (31.1%) had `main` gain a first-parent commit AFTER their
  certifying CI run started -- the true fire rate -- median staleness 16.1 min, max 146.6 min
  (PR #1268 itself). For comparison, #1292's own filed predicate ("is the branch behind `main` at
  merge") fired on 20/45 (44.4%), confirming it is the wider, more expensive question. Of the 14,
  only 2 carried a `scripts/**`/`scripts/tests/**` change in the window -- reported as the
  trunk-red-risk subset, not used to filter the gate itself. 31.1% is well below "fires on nearly
  every PR", so the size warranted building rather than a report recommending the ruleset option.
- [x] Added two pure, testable functions to `scripts/lib/pr-issues-lib.ps1`:
  `Get-CertifyingRunTimestamp` (earliest required check's own `startedAt`, from data already in
  memory) and `Get-StaleCertificateVerdict` (Stale/Count/Commits from a SHA list). Smoke-tested by
  hand (dot-sourced, six cases) before wiring them in.
- [x] Added step 3b to `scripts/release/ship-pr.ps1`, between the CI wait (step 3) and the merge
  (step 4): one `git fetch origin main` plus a first-parent `git log --since=<certifying
  timestamp>`, refusing the merge when `main` moved since the run that certified this PR --
  matching the corrected predicate, not "the branch is behind". Escape valve `-SkipStaleCheck`,
  named for what it turns off, matching `-SkipLint`/`-SkipTests`. Fails closed on the predicate
  (refuses when `main` demonstrably moved) but warns-and-ships on an unreadable timestamp or a
  failed fetch/log -- that read is not the one that has to fail closed; the required-check-list
  read at step 3 already does. Repo-settings option 1 from #1292
  (`strict_required_status_checks_policy: true`) is untouched -- Dave's call, not this branch's.
- [x] Synced the mirror via `scripts/sync/build-shared-scripts.ps1` (the repo's own generator, not
  a hand copy) -- `plugins/workflows/contributing-davekjohn/scripts/{release/ship-pr.ps1,
  lib/pr-issues-lib.ps1}` are byte-identical to the root copies (`diff` confirmed).
- [x] Documented `-SkipStaleCheck` in the `ship-pr` skill page (`.../skills/ship-pr/SKILL.md`) --
  the parameters table, the step list, and a new section explaining the corrected mechanism and
  the measurement -- required by the `[skill-param]` lint check, which caught the gap on first run.
- [x] `.github/workflows/ci.yml` is untouched -- issue #1294 (the fold push displacing the merge
  commit's pending CI run) is a separate filed issue and out of scope here.
- [x] Repaired one incidental regression the new doc comment introduced: a synopsis paragraph for
  step 3b named `Get-MergeBlockVerdict` earlier in the file than the first `'--watch'` call, which
  broke `pr-issues.tests.ps1`'s "the wait still happens FIRST" ordering assert (a text-position
  check, not a behavioural one). Reworded the paragraph to describe the same fact without the
  literal function name; no logic changed.

### TEST

#### For Tycho: what is testable here and what is not

- [ ] `Get-CertifyingRunTimestamp` and `Get-StaleCertificateVerdict` (both in
  `scripts/lib/pr-issues-lib.ps1`) are PURE functions of their input -- no git, no gh, no
  filesystem -- and belong in `scripts/tests/pr-issues.tests.ps1` beside `Get-MergeBlockVerdict`
  and `Get-CheckWaitReport`, which they were modelled on. Worth covering: a single required check,
  multiple required checks (earliest wins), a required name absent from the checks payload, empty
  `ChecksJson`/`RequiredNames`, an unparseable payload, a zero-time (`0001-01-01...`) `startedAt`
  (the `ConvertTo-CheckTimestamp` case #977 measured), no commits (`Stale=$false`), one or more
  commits (`Stale=$true`, `Count`, dedup via `Select-Object -Unique`), and blank/whitespace entries
  in `-NewMainCommits` being dropped.
- [ ] `ship-pr.ps1`'s own step 3b (the `git fetch`/`git log`/refusal wiring) is like every other
  step in this script: it drives live `git`/`gh` against a real remote and is NOT covered by an
  automated suite, by the same known test gap the file's own header states for the rest of the
  orchestration. What IS assertable without a live remote, the way the suite already asserts
  ordering and wording for the #831/#943/#1044/#1219 repairs in this same file: that step 3b's code
  calls `Get-CertifyingRunTimestamp` and `Get-StaleCertificateVerdict`, that it reads
  `$checkFactsJson`/`$requiredFactsJson` rather than re-fetching them, that `-SkipStaleCheck` skips
  it, and that its refusal text names the commit count and the remedy. A text-position assert (the
  wait-order pattern already in this suite) is fragile to comment edits -- this branch's own
  regression above shows exactly that -- so prefer asserting on stable anchors (`-SkipStaleCheck`,
  `Get-StaleCertificateVerdict -NewMainCommits`, the refusal's lead sentence) over line-order.
  Whether that fragility is worth tightening further is Tycho's call, not decided here.
- [ ] Not testable at all without a live remote: the actual behaviour of `git fetch origin main`
  against a real GitHub repo, or a real `gh pr checks --required` payload shaped exactly like the
  measurement's 45 sampled PRs. The measurement itself (31.1% fire rate, 44.4% behind-at-merge,
  16.1/146.6 min staleness) was a one-off `gh`+`git` query kept in the session scratchpad, not a
  script in this repo -- nothing to add a test for.

### DEPLOY: `fix/ship-pr-stale-ci-certificate`

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

ship-pr refuses to merge on a CI certificate main has outrun

