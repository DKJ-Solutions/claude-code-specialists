## Development: `fix/ship-pr-missing-check-suite-v1` · 20260902-160706

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

Issue #1234, filed by a consumer and verified against the tree before pickup. `ship-pr.ps1` step 3's
pre-watch probe refuses after 180s with *"Check the workflow, or merge manually once it is green."*
That sentence claims this repo's YAML is wrong; the state that produces it most often has healthy
workflows and no `github-actions` check suite for the commit at all.

#### What was checked before any of this was written

- The wording is current on `main`, `scripts/release/ship-pr.ps1:505`, and identical in the mirror.
- `Get-StalledRunNote` genuinely cannot cover it -- it reads a RUN, and here no run and no suite to
  hold one was ever created. `Get-LostWatchNote` sits after the watch, one step further on.
- The remedy names mechanisms that exist: `ci.yml` triggers on bare `pull_request:` and
  `branch-entry.yml` on `pull_request: branches: [main]`, neither narrowing `types:`, so both re-fire
  on `reopened`.
- The report's own cost paragraph was WRONG and its author corrected it on the thread before anyone
  acted on it: `gate-lib.ps1` caches gate evidence on the tree (`GateEvidenceMaxAgeMinutes = 240`), so
  a resume skips both gates. The re-checkout is the true cost. Nothing in this branch is built on the
  inflated number, and the entry below does not repeat it.

### CREATE

- [x] `Get-MissingCheckSuiteNote` in `scripts/lib/pr-issues-lib.ps1` -- a pure function over
      `gh api repos/<owner>/<repo>/commits/<sha>/check-suites`, `''` when a `github-actions` suite
      exists so the old wording still prints for the case it is correct for.
- [x] Wire a guarded, best-effort read into step 3's refusal branch in `scripts/release/ship-pr.ps1`,
      reading the sha locally from `refs/heads/<branch>` on the same argument the step-4 DEPLOY lock
      already makes. The refusal and its `exit 1` are untouched on every path.
- [x] `scripts/sync/build-shared-scripts.ps1` -- mirror both files into the plugin.

### TEST

- [x] 22 asserts added to `scripts/tests/pr-issues.tests.ps1`, beside the three sibling notes: the
      measured payload, the cry-wolf case (an Actions suite that DOES exist), the empty list, a
      single foreign suite, an unreadable `app`, a duplicated slug, seven unreadable payloads, the
      missing PR number, and four call-site asserts pinning that the probe still asks. Suite green:
      396 asserts.
- [x] Run against a REAL payload rather than fixtures only: `gh api .../commits/d54c7547/check-suites`
      returns `netlify, claude, github-actions` and the note correctly says nothing; the same payload
      with the Actions row removed produces the sentence. The field path `check_suites[].app.slug` is
      therefore confirmed against the live API, not just against the report.
- [x] Reviewed in parallel by the code reviewer, the copy editor and the security engineer. Three
      findings acted on: a comment miscounting the sibling diagnostics ("both notes below" -- there
      are three), an ambiguous antecedent in the SYNOPSIS, and two redundant clauses cut from the
      operator sentence. The relayed slug is deliberately neither bounded nor escaped, unlike the free
      text `Get-AuthoredFailureNote` relays, and the comment beside it now says why.
- [x] Lint gate green, 0 errors -- including `[script-ascii]`, which the new docstring had to pass.

### DEPLOY: `fix/ship-pr-missing-check-suite-v1`

When `ship-pr` waits out its full 180 seconds and no check has registered, the refusal now reads the
commit's check-suite list before it words itself. Where GitHub created no Actions suite at all, it
says so -- naming the suites that DO exist -- states that this is not a `paths:` filter, a wrong
trigger or a syntax error, and offers `gh pr close <n> && gh pr reopen <n>` as the cheapest thing to
try, explicitly not as a diagnosis. Where an Actions suite does exist, nothing changes: that is the
one case *"Check the workflow"* was always right for, and it still prints.

The merge decision is untouched, deliberately and for the fourth time. Refusing on a commit no check
has measured is the conservative half of that probe; this adds no state to any decision and cannot let
a merge through. What moves is the diagnosis -- the same repair #943, #1044 and #1219 each made one
step further down the same script, and the fourth time a sentence has been found sending the reader
somewhere no repair exists. Here it had them auditing YAML that was fine.

**Score:** 3

#### What makes this deploy extra special

Every consumer running this workflow ships through the same probe, and a missing check suite is not a
state an operator recognises: the first instinct is to audit the triggers, which is exactly the time
the old sentence charged them for. They now get the fact and the twenty-second remedy in the line that
refuses. The reopen is stated as GitHub's own default `pull_request` types rather than as a claim
about their workflows, which this script does not read -- the same restraint that keeps the probe from
naming a check.

**Score:** 3

#### Pull Request

ship-pr names the missing Actions check suite and the reopen that restores it
