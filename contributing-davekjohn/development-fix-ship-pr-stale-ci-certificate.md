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
  **Superseded by the re-anchor below: the warn-and-ship posture on an unresolved read was reversed
  once a required check is named -- see `#### Re-anchor after Marlowe's red-team...` under this same
  heading for what actually ships now.**
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

#### Re-anchor after Marlowe's red-team + Chris's verification (issue #1292, same branch, after Tycho's 46 asserts landed on `f8b156d0`)

- [x] **The bias was backwards, not just imprecise.** `Get-CertifyingRunTimestamp` anchored on the
  earliest required check's own `startedAt`, reasoned as "conservative because queueing only pushes
  it LATER than the true ref-fix moment". That direction under-refuses: a LATER anchor makes
  `git log --since=<anchor>` MISS commits landed in the gap, so a genuinely stale certificate reads
  as SOUND -- the one failure this whole gate exists to prevent. Two reasons the gap is far larger
  than "sub-minute" here, neither visible to the original 45-PR sample (which measured staleness
  *after* anchoring on `startedAt`): `windows-latest` provisioning routinely costs over a minute, and
  "re-run failed jobs" (ordinary practice here) re-runs the SAME commit while `startedAt` jumps
  forward by however long the operator waited -- seconds to hours.
- [x] **Verified rather than taken on faith**, per the assignment: found a genuine `run_attempt > 1`
  in this repo (`gh api .../actions/runs?event=pull_request&per_page=100&page=2..5`), then compared
  `/actions/runs/<id>` against `/actions/runs/<id>/attempts/1` and `/attempts/2` directly. Run
  `33652133970`: the RUN object's `created_at` stayed `2026-09-02T15:59:52Z` across the re-run
  (matching attempt 1 exactly) while `run_started_at` moved to `2026-09-02T21:15:50Z` -- over five
  hours later. `/attempts/2` on its own reports ITS OWN `created_at` of `2026-09-02T21:15:51Z`,
  matching its own late start -- the value that would have reintroduced the identical bias. So the
  repair reads the RUN object (or the runs list, which returns the same shape), never a per-attempt
  one. This holds; nothing needed walking back.
- [x] **Replaced `Get-CertifyingRunTimestamp`** with two pure functions in
  `scripts/lib/pr-issues-lib.ps1`: `Get-RequiredCheckRunIds` (extracts the distinct Actions run id(s)
  behind named checks from the already-fetched `$checkFactsJson`'s `link` field) and
  `Get-CertifyingRunCreatedAt` (earliest of already-fetched `created_at` values, zero-time still
  guarded). `ship-pr.ps1` step 3b now: finds the run id(s) from data in memory (no new call), asks
  `gh api repos/<repo>/actions/runs/<id> --jq '.created_at'` per unique run id (the one new network
  call), then reduces to the earliest.
- [x] **Softened the two overclaims the red-team flagged**: a `pull_request` run exists at all only
  for a MERGEABLE PR (GitHub creates none for a merge conflict -- harmless, an unmergeable PR cannot
  ship anyway), and "GitHub fixes THE merge ref" is this repo's own practical experience with a
  single-job workflow, not a documented contract (`actions/checkout#27` records two jobs of one event
  resolving different merge commits) -- reworded to reason from "a run's `created_at` cannot postdate
  its own ref-fix moment" rather than from a guarantee GitHub does not make.
- [x] **Reconsidered the unreadable-anchor posture, deliberately, per the assignment's own
  instruction not to just keep it.** Chose a SPLIT rather than one answer for the whole step: with NO
  required check named at all, WARN and skip (this predicate has nothing to protect on a repo with no
  ruleset -- refusing there would permanently block `ship-pr` on every such consumer, and
  `Get-MergeBlockVerdict` already cannot tell "no ruleset" from "unreadable" either). Once a required
  check IS named, every subsequent read -- the run id, its `created_at`, the `git fetch`, the
  `git log` -- now FAILS CLOSED with `-SkipStaleCheck` as the valve, the opposite of the retired
  build's warn-and-ship: at that point there is a specific certificate to verify, and not verifying
  it must never read as sound.
- [x] Re-synced the mirror (`scripts/sync/build-shared-scripts.ps1`, `diff`-confirmed identical) and
  re-ran `pr-issues.tests.ps1` + the lint gate + the full 61-suite gate once each -- see the TEST
  section below for the numbers Tycho's tests needed to match the re-anchor.

#### Review round (Victor, Edith, Sebastian on the re-anchored diff) -- six repairs, one blocking

- [x] **BLOCKING (Sebastian): credential leak on a failing `git fetch origin main`.** No
  `-DiscardStderr` on that call, and its `Output` (stderr merged in) was echoed verbatim on failure --
  a failing fetch echoes the remote URL, a secret on an HTTPS clone with an embedded credential. Same
  lesson and same guard as `new-branch.ps1`'s own base-freshness fetch (its comment names it
  explicitly). Added `-DiscardStderr`, dropped the raw-output echo; the refusal message already said
  everything actionable. Sebastian found a pre-existing sibling at the fold-step fetch and filed it
  separately as **#1313** rather than folding it in here -- left alone, not this branch's.
- [x] **`git log` missing `-DiscardStderr` (Victor and Sebastian, independently).** Its output feeds
  `$newMainCommits` -> `Get-StaleCertificateVerdict`, the same PARSED-output reasoning the `gh api`
  call three lines up already states for itself. Added the flag.
- [x] **Hardened the refusal regardless of the above (Victor).** He reproduced a non-SHA line reaching
  `Output` turning `$_.Substring(0, 8)` into a raw `.NET` exception ("length must refer to a location
  within the string") right before the refusal that was supposed to print -- fails safe (nothing
  merges) but with a stack trace instead of the message. Guarded with a length check: a short entry is
  shown whole rather than dropped, so the count and the list still agree.
- [x] **`SKILL.md` step-3b summary said `started` (Victor).** The exact wrong-direction anchor word
  this branch's re-anchor replaced, three paragraphs above the detailed section that already said
  `created` correctly. One word, fixed.
- [x] **`SKILL.md`'s `-Force` row cross-reference broke on insertion (Edith).** "Deliberately separate
  from the two above" pointed at `-SkipTests`/`-SkipStaleCheck` once my row landed between
  `-SkipTests` and `-Force` -- and "those skip a tool" is false of `-SkipStaleCheck`. Named
  `-SkipLint`/`-SkipTests` explicitly instead of positionally, per Edith's stated preference (the next
  insertion breaks a positional reference again).
- [x] **This CREATE section's own stale claim (Edith).** The bullet above describing step 3b's first
  build still stated its now-superseded warn-and-ship posture as current fact. Left the bullet as the
  true record of that commit (matching the convention already set in TEST) and added a one-line
  forward pointer to the `#### Re-anchor` subsection above, which is what actually ships now.
- [x] **Not acted on, deliberately.** Edith's 10+ flagged `github.com/DaveKJohn/...` links: verified by
  Chris as 200s (GitHub redirects the old org path) against 1,586 identical links tree-wide -- withdrawn,
  not touched. Victor's note on `$staleCheckNames.Count -eq 0` warning rather than refusing (the same
  ambiguity `Get-MergeBlockVerdict` itself cannot resolve): judged deliberate by both Victor and Chris:
  refusing there would permanently block `ship-pr` on every ruleset-less consumer, which this payload
  reaches. Checked that the tradeoff is already explicit in the comment above that branch (it names the
  ambiguity and the cost of refusing) rather than left to be inferred -- it was; no change made.
- [x] Re-synced the mirror again (`diff`-confirmed identical) and re-ran the lint gate + the full
  61-suite gate once each after these six repairs -- numbers in TEST below.

### TEST

#### For Tycho: what is testable here and what is not

**The three bullets immediately below are Tycho's own, from `f8b156d0`, and describe
`Get-CertifyingRunTimestamp` -- the function the re-anchor above replaced. Left as written, as the
true record of that commit, rather than rewritten to match the current code; the follow-up bullet
after them says what changed and to what it now corresponds.**

- [x] `Get-CertifyingRunTimestamp` and `Get-StaleCertificateVerdict` (both in
  `scripts/lib/pr-issues-lib.ps1`) covered in `scripts/tests/pr-issues.tests.ps1`, in their own
  sections beside `Get-MergeBlockVerdict` and `Get-CheckWaitReport` (which they were modelled on).
  46 new asserts. For `Get-CertifyingRunTimestamp`: a single required check, no required names,
  `RequiredNames`/`ChecksJson` omitted, every unreadable-JSON shape (empty/whitespace/`not json`/
  `null`/`[]`/`{}`), a required name absent from the payload, two required checks with different
  `startedAt` (the earlier one wins, not the payload order), a non-required check with an EARLIER
  timestamp being ignored, the zero-time `0001-01-01...` shape being SKIPPED rather than winning as
  the earliest (both with one other real required check and with every required check zeroed, which
  must answer `$null` rather than the epoch), and a nameless record. For
  `Get-StaleCertificateVerdict`: empty array, the default with no argument at all, an explicit
  `$null`, one commit, several commits (order preserved), duplicate SHAs de-duplicated via
  `Select-Object -Unique`, and null/empty/whitespace entries mixed in with real SHAs (filtered, do
  not inflate `Count`) and alone (`Stale=$false`, `Count=0`). Read past the summary given here into
  the actual function body before writing these, per the assignment -- both match what is now
  covered.
- [x] `ship-pr.ps1`'s own step 3b (the `git fetch`/`git log`/refusal wiring) confirmed as the known,
  stated test gap it is -- like every other live git/gh step in this script, not covered by an
  automated suite, and not papered over as one. What IS assertable without a live remote is covered
  in its own new section: that step 3b calls `Get-CertifyingRunTimestamp` with
  `$checkFactsJson`/`$staleCheckNames` and `Get-StaleCertificateVerdict` with `$newMainCommits`
  (proving it reuses the facts step 3 already fetched rather than asking `gh` again -- pinned by the
  one occurrence of `$requiredFactsJson | ConvertFrom-Json` unique to this block), that
  `-SkipStaleCheck` gates the whole block (`if ($SkipStaleCheck) {`) and says so when taken, that the
  refusal names the commit count and the PR, leads with a greppable `stale-CI certificate` string,
  gives the `git merge origin/main` remedy, documents the escape valve beside it, and is a hard
  `exit 1` rather than a warning. Every one of these is a literal-code-fragment anchor (a call with
  its real argument names, an exact printed sentence), not a text-position/line-order assert --
  Sylvester's own caution taken literally, since his change broke exactly that kind of assert
  elsewhere in this same file by mentioning a function name earlier in a new doc comment.
- [x] Not testable at all without a live remote, confirmed rather than reopened: the actual
  behaviour of `git fetch origin main` against a real GitHub repo, or a real `gh pr checks
  --required` payload shaped exactly like the measurement's 45 sampled PRs. The measurement itself
  (31.1% fire rate, 44.4% behind-at-merge, 16.1/146.6 min staleness) was a one-off `gh`+`git` query
  kept in the session scratchpad, not a script in this repo -- nothing to add a test for. This is a
  named, stated gap, not a silent one.

#### Tests updated for the re-anchor (same file, after Tycho's commit)

- [x] Replaced the `Get-CertifyingRunTimestamp` section (above) with two sections matching the new
  functions: `Get-RequiredCheckRunIds` (run id extraction from a check's `link`: single/multiple
  named checks, two checks sharing one run deduplicated to one id, a link naming no Actions run
  skipped, non-named checks ignored even with a resolvable run, every unreadable-JSON shape, a
  nameless record) and `Get-CertifyingRunCreatedAt` (single value, earliest-of-two, the zero-time
  shape still skipped -- carried over from Tycho's own case verbatim in spirit, since a zero anchor
  voiding every certificate is the one wrong answer neither version may produce -- every-value-zero,
  blank/whitespace/null, omitted, empty array, and an unparseable value both alone and beside a real
  one). `Get-StaleCertificateVerdict`'s own section is untouched -- that function did not move.
- [x] Updated the step 3b wiring section: the two call-signature anchors now name
  `Get-RequiredCheckRunIds`/`Get-CertifyingRunCreatedAt` instead of the retired function, added an
  anchor for the one new `gh api .../actions/runs/<id> --jq '.created_at'` call, and added anchors for
  BOTH halves of the reconsidered fail-closed split: the `if ($staleCheckNames.Count -eq 0)` warn
  branch (nothing known to protect), and each of the four new FAILS-CLOSED refusal paths (no run
  found, the `created_at` read failing, every fetched value unparseable, `git fetch`/`git log`
  failing) -- the last two checked as one contiguous literal fragment spanning the refusal text and
  `-SkipStaleCheck` on purpose, since those two are single-line messages with no wrap point to
  reflow; the other two stop at existence, because their `-SkipStaleCheck` mention sits across a
  line-wrap in a here-string and pinning that wrap would fail on a future reflow for no semantic
  reason -- exactly Sylvester's own caution about position-based fragility, applied to a case a
  literal-fragment anchor can still walk into if the literal spans a wrap point.
- [x] One assert of my own needed the same 5.1 fix this file's OWN header warns about: a single-run
  case indexed `(Get-RequiredCheckRunIds ...)[0]` without wrapping the call in `@(...)` first, so
  PowerShell returned the bare string "111" instead of a one-element array and `[0]` indexed its
  first CHARACTER ("1") rather than its first element. Not a defect in the library function -- caught
  by running the suite, not review, and fixed at the call site.
- [x] 606 asserts total in `pr-issues.tests.ps1` after the re-anchor (up from 585 before it), 0 failed.

Ran `scripts/tests/pr-issues.tests.ps1` standalone: 585 asserts, all green (0 pre-existing failures).
Then the full gate exactly as CI/`open-pr.ps1`/`cut-release.ps1` run it -- `check-plugin-integrity.ps1`
(0 errors) followed by `Invoke-TestSuiteGate` over all 61 `scripts/tests/*.tests.ps1` suites, parallel:
61/61 passed in 471s, 0 failures, nothing already red before this branch's changes. (A first, ad hoc
attempt at the full run -- a hand-rolled serial loop with `$ErrorActionPreference = 'Stop'` -- reported
one suite failing on a `git` progress line written to stderr; that was a bug in that throwaway script,
not in the suite, and re-running through the repo's own `Invoke-TestSuiteGate` gave the clean result
above.) No production code touched -- test file only, so no mirror sync was needed (`scripts/tests/**`
is not among the mirrored paths in `plugins/workflows/contributing-davekjohn/scripts/`, confirmed by
listing that tree before editing).

**Re-run after the re-anchor above, once each as asked (not the three duplicate runs the first pass
produced):** mirror re-synced (`build-shared-scripts.ps1`, `diff`-confirmed identical on
`ship-pr.ps1` and `pr-issues-lib.ps1`) -- `scripts/tests/pr-issues.tests.ps1` alone: 606 asserts, 0
failed. `check-plugin-integrity.ps1`: 0 errors (run twice -- once before the `SKILL.md` rewrite for
the corrected mechanism, once after, since that edit landed after the first pass; both clean).
`Invoke-TestSuiteGate` over all 61 suites, parallel, exactly as CI runs it: 61/61 passed in 360s, 0
failures, nothing already red.

**Re-run again after the Victor/Edith/Sebastian review round's six repairs (credential-leak fix,
`-DiscardStderr` on `git log`, the `Substring` length guard, the two `SKILL.md` wording fixes, the
CREATE forward-pointer):** re-synced (`diff`-confirmed identical), `pr-issues.tests.ps1` alone: 606
asserts, 0 failed (the assertions target refusal TEXT, not the exact `Invoke-NativeCapture` argument
list, so adding `-DiscardStderr` and the length guard needed no test changes). `check-plugin-
integrity.ps1`: 0 errors. `Invoke-TestSuiteGate` over all 61 suites, once as asked: 61/61 passed in
398s, 0 failures.

### DEPLOY: `fix/ship-pr-stale-ci-certificate`

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

ship-pr refuses to merge on a CI certificate main has outrun

