## Development: `fix/sync-main-gh-calls-bounded-v1` · 20260901-122256

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

Route the four gh network calls in `scripts/task/sync-main.ps1` through `Invoke-NativeCapture` with the
shared bound, closing issue [#1184](https://github.com/DaveKJohn/claude-code-specialists/issues/1184) --
the half [#1181](https://github.com/DaveKJohn/claude-code-specialists/issues/1181) scoped out on purpose
and filed rather than widened into. The `gh pr checks` polling loop is deliberately left alone.

#### What the verification changed about the report

The report framed this as a question rather than an obvious yes, and put the evidence on both sides.
Measured against the tree on pickup, three of its facts moved:

- **The line numbers.** It named 519/875/885/919; the calls are at **582/952/962/996**. Same four calls,
  and both copies are byte-identical, so the mirror needed no separate reading.
- **The reason is stronger than "cuts both ways", and it is an inconsistency rather than a judgement.**
  `scripts/lib/native-capture-lib.ps1:31` states flatly that *"Every git and gh call the workflow scripts
  make comes through this one function"*, and its docstring gives the reason -- gh shells out to git in
  places. That sentence was **false** in this tree. #1179's measurement that gh was unaffected is still
  correct and is not the deciding fact: a load-bearing claim a reader cannot trust is worse than the gap
  it describes, and `gh pr create` sits directly after the push where a stall leaves the branch on origin
  with no PR.
- **The size is wrong** (`triage-inbound` pattern 5). It said *"Each already carries its own hand-rolled
  `$ErrorActionPreference` bracket"*. Measured, **one of the four** did -- `gh pr list`. `pr create`,
  `pr view` and `pr merge` carried none. So the stated payoff of "removes four copies of the EAP dance"
  is one copy, and the change earns its place on the bound rather than on the tidying.

#### And a defect the report did not name, which is the biggest one here

`gh pr view` had **no exit-code check at all** -- its output went straight into `.Trim()`. On a failed
read `$pr` became the empty string, and the checks loop below then polled with no PR number: no states,
sleep 15s, for the whole of `-ChecksTimeoutMinutes`, before printing `gh pr merge  --squash` for the
operator to run. The PR was open and green the entire time. That is the same shape #1181 named on the
trunk pull -- *the one failure nobody would go looking for* -- and routing the call through the lib is
what forces the check.

### CREATE

- [x] `gh pr list` (the merged test in the standing-predecessor guard) through the lib, `-DiscardStderr`
      because the output is data the guard compares branch names against, plus the shared bound. Its
      hand-rolled EAP bracket removed -- the lib owns that half.
- [x] `gh pr create` through the lib with the bound, stderr merged and echoed because gh writes the PR
      URL there. Its `TimedOut` branch says the branch **is** on origin and to check for the PR before
      opening a second one.
- [x] `gh pr view` through the lib with `-DiscardStderr` and the bound, **and an exit-code check** that
      exits rather than polling with an empty PR number.
- [x] `gh pr merge` through the lib with the bound. Its timeout line says to **look** rather than retry,
      since gh may have merged and then failed to report.
- [~] Switching `--body` to `--body-file` on the merging path: considered, because a bound implies the
      `Start-Process` arm and therefore this lib's own argument quoter rather than PowerShell's, and the
      body is multi-line markdown. **Dropped because it is not needed** -- measured through a round-trip
      argument echo, the body arrives as one argument with its blank lines, embedded double quotes and a
      trailing backslash intact. The note now sits at the call site so nobody re-opens the question.
- [x] The stale `@labelArgs` comment rewritten: the call is an `-Arguments` list now, so the splat form it
      described no longer exists. The measured PS 5.1 trap it recorded is kept, since `@(...) + @()`
      avoids the same empty-string argument the splat did. Same shape as `open-pr.ps1`'s create.
- [x] The banner updated: git **and** gh, nine calls not five, why gh is in scope despite #1179's
      measurement, and why the checks loop is excluded.
- [x] Mirror rebuilt via `scripts/sync/build-shared-scripts.ps1` -- `plugins/teams/team-shopify` is
      byte-identical again.

#### What is deliberately NOT in this branch

The `gh pr checks` polling loop keeps its bare call and its hand-rolled EAP bracket. The report asked for
that, and its stated reason is wrong -- the lib warns by name about `gh pr checks --watch`, and this is a
**polling** loop whose every call returns in seconds, so a per-call bound would not be that mistake. The
exclusion still stands on a different reason: the bracket must **swallow** the stderr a pending run
writes while still reading states, which `-DiscardStderr` does not do, and the loop is already bounded
across itself by `-ChecksTimeoutMinutes`. There is a real gap underneath -- a single hung poll never
re-reaches the `while` condition and so defeats that timeout -- and it is its own judgement with its own
trade-offs, filed rather than ridden along, exactly as #1181 filed this half.

### TEST

- [x] `scripts/tests/sync-main.tests.ps1`: **104 asserts, all green**, real process exit 0. Was 91.
- [x] The count assert repointed 5 -> 9, calls and bounds both, keeping the invariant that every
      `Invoke-NativeCapture` in this script carries the shared bound.
- [x] Thirteen asserts added: no bare `& gh pr list|create|view|merge`; each of the four named
      individually, because the count is blind to *which* nine they are; `-DiscardStderr` present on the
      two `--json` reads and absent on the two writes; the `gh pr view` exit-code check, both halves;
      the hand-rolled EAP bracket count pinned at exactly one; and two asserts that the checks loop is
      **still bare and that the banner says so**, so a later reader "finishing the job" has to do it
      deliberately.
- [x] Full lint + test gate via `open-pr.ps1`.

### DEPLOY: `fix/sync-main-gh-calls-bounded-v1`

`sync-main.ps1`'s four `gh` network calls -- `pr list`, `pr create`, `pr view`, `pr merge` -- now run
through `Invoke-NativeCapture` with the shared 120-second bound, so each one gets the non-interactive
environment (`GIT_TERMINAL_PROMPT=0`, `GCM_INTERACTIVE=never`) and a stall is killed and reported as
exit 124 instead of sitting there looking like a run still in progress. That makes the lib's own claim --
every git *and* gh call comes through this one function -- true in this script for the first time. The
`gh pr checks` polling loop is deliberately untouched.

The repair also closed a defect the report did not name: `gh pr view` had no exit-code check, so an
unreadable PR number became an empty string and the checks loop then polled with no PR for the whole
timeout before handing the operator a `gh pr merge` line with no number in it.

**Score:** 3

A consumer running `sync-main.ps1` is the reader here, and the change is invisible until the day a `gh`
call stalls -- at which point it is the difference between a 120-second error naming the call and a run
that never returns. The `gh pr view` half is a real failure that could already happen: the PR opens, the
script waits out the full `-ChecksTimeoutMinutes`, and the instruction it prints is unusable.

#### What makes this deploy extra special

That the report was wrong in three places and still worth acting on. Its symptom stood, its line numbers
had moved, its size was overstated by four to one, its stated reason was weaker than the real one, and
its one explicit exclusion was correct for the wrong reason. Repairing to the report would have produced
a change that satisfies it and misses the actual defect -- the unjudged `gh pr view` -- which nothing in
the report mentions.

**Score:** 2

Method rather than payload: it is `triage-inbound`'s recount discipline applied to a report this repo
filed against itself an hour earlier, and it went wrong in three of six dimensions even then.

#### Pull Request

sync-main.ps1's four gh network calls go through Invoke-NativeCapture
