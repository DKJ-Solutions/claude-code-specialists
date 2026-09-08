## feat/1591-consumer-version-verdict

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

The session-start half of plugin-versions (#1599). Two pieces: a -Brief mode on plugin-versions.ps1 that emits marker-prefixed one-liners, and a fallback on connector-sessioncheck.ps1's early-exit path where it currently prints 'no verified workshop checkout found -- check skipped'.

#### Why the predecessor had to land first

#1591 names `plugin-versions.ps1` as "the natural engine for the summary mode once it lands", and it
had not landed: it sat on `feat/plugin-version-overview`, whose own handoff note recorded the pre-PR
review as still owed after that session stopped on usage. Building #1591 without it meant duplicating
the verdict logic into a hook. So the review was re-run (Sebastian's named question answered: no
leak; Victor found a reachable blank verdict; Edith four text findings; Tycho pinned the regression),
and it shipped as PR #1599 before this branch was cut.

### CREATE

- [x] `-Brief` on `scripts/task/plugin-versions.ps1`: one marker line per plugin with something to
  say, plus a `[SUMMARY]` tally. `behind` -> `[ERROR]`; `clone-behind` and `indeterminate` ->
  `[INFO]`, never `[ERROR]` (#1591's own instruction); `match`/`ver-match` -> nothing. Header
  suppressed. Mirror rebuilt via `build-shared-scripts.ps1`.
- [x] Every field on a brief line sanitised -- `Format-SuspectToken` for the Id,
  `Format-SafeProseToken` for the verdict and action (Sebastian, blocking; inbound #309's own value
  class). The bracket substitution is what closes the summary-suppression chain.
- [x] The fallback in `plugins/dkj-policy/hooks/connector-sessioncheck.ps1`, replacing the
  `check skipped` early exit. Four branches, each stating that the register checks did not run.
  Engine resolved as the plugin mirror ONLY -- the `$cwd` candidate was removed on review. Child
  bounded at 30s via `Invoke-NativeCapture`; summary taken as the LAST match.
- [x] `plugins/dkj-policy/skills/plugin-versions/SKILL.md`: the `-Brief` section, its example output,
  and why the two update commands are not interchangeable.

### TEST

- [x] `scripts/tests/plugin-versions.tests.ps1` -- scenarios 14-20 pin the `-Brief` contract:
  the marker split (a regression that promotes `clone-behind` or `indeterminate` to `[ERROR]` fails),
  per-plugin silence on a match asserted by whole-run equality, the summary's counts partitioning the
  rows, header suppression, and the default view unchanged. 69 -> 101 asserts.
- [x] `scripts/tests/connector-sessioncheck.tests.ps1` (new) -- all four branches pinned line by line,
  including that `[INFO]` never reaches a clean run and that every branch carries the register-checks
  phrase. 25 asserts.
- [x] Two pre-existing assertions in `scripts/tests/connectors.tests.ps1` isolated: this change had
  made them read the machine's real install record, so they had stopped being deterministic.
- [x] Cost measured before shipping rather than after (Nolan): 1.1-1.8s per firing, spawn-dominated,
  re-paid on every compaction. Filed as #1605; the matcher is deliberately NOT narrowed, because that
  would reintroduce the silence the wide matcher exists to prevent.
- [x] `check-plugin-integrity.ps1` 0 errors; the full 76-suite gate green.

### DEPLOY: feat/1591-consumer-version-verdict

A consumer with no source checkout beside it now gets a real answer at session start instead of
`no verified workshop checkout found -- check skipped`. That machine is the ordinary case, not an
edge case: the register checks genuinely cannot run there, because `check-connectors.ps1` is
source-only and is not plugin-carried -- so the hook said nothing at all about versions, and a
session could load a plugin release behind the one on the machine with no signal of it. It now runs
the plugin-carried `plugin-versions.ps1` in a new `-Brief` mode, which reports per enabled plugin
whether the version THIS checkout installed is the one the local marketplace clone holds, and prints
the command that closes the gap.

Only an install that is BEHIND its clone is reported as a finding. A stale clone is deliberately not
one -- it is a cache this checkout does not own, and shouting about it teaches the reader to skim the
marker that matters -- and `[INFO]` lines are kept out of a clean run entirely, because a plugin from
another marketplace reports "cannot determine" forever and would become permanent session-start
noise. Every branch says the register checks did not run, so nobody reads a version answer as an
all-clear for five checks that never happened.

**Score:** 4

#### What makes this deploy extra special

Every consumer of this workflow receives it in the next release, and it closes the blind spot the
`plugin-versions` skill could only answer when someone thought to ask: a session that has quietly
loaded a plugin release behind the machine's own now says so at the start, unprompted, on the
machines where nothing was checking. The signal arrives where the cost of not having it is highest --
a consumer acting on stale agent defs, skills or hooks without knowing it.

**Score:** 4

#### Pull Request

A real version verdict on a plain consumer, instead of a session start that says nothing

