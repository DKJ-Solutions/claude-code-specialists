## fix/1664-fixture-temp-path-guid

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

#1664 asked three questions before it asked for edits, and the answers are what shaped this branch.

**Is the `$PID` spelling load-bearing anywhere?** No. A folded scan of `scripts/tests/` finds exactly
one statement that reads a temp leaf back by name — `test-suite-gate.tests.ps1:145` — and it reads the
*gate's* capture directory, which `New-ScratchPath` already composes as `<label>-<pid>-<guid>`, by the
glob `test-suite-gate-<pid>-*`. That glob already tolerates a guid suffix, so the one real reader is
evidence *for* the shape rather than against it. No suite recomposes a parent's fixture name in a child.

**Can the sites be routed through `New-ScratchPath`?** Reachable, but the wrong instrument. 22 of 85
suites dot-source `native-capture-lib.ps1` (1406 lines) and 28 offender files would need a new
dot-source of it; worse, `New-ScratchPath -Directory` creates *without* `-Force` and throws on an
existing item, so routing the sites through it changes every fixture's setup and teardown shape rather
than just its path composition. Declined, and the reasoning is recorded in `scripts/README.md` so the
next reader does not re-open it.

**Is it worth doing?** Yes, by the cheap route: keep `$PID`, append a fresh guid inline — exactly
`New-ScratchPath`'s own `<label>-$PID-<guid>` — and tighten the gate's own rule so the class cannot
come back. The pid stays because it is what makes a leftover attributable to a live run, which is what
`#1636`'s note and the gate's capture glob both rely on.

#### The count differs from the issue's, and both are right

#1664 reported 108 statements across 66 files, measured on `feat/1659-temp-path-unpredictable` at
`922604a7`. Measured here after that branch merged: **100** across 53 files, of which **96** were
rewritten — the remaining 4 (`new-branch` and `shared-scripts`) already build their leaf from `$tag`,
which is itself a fresh guid, and are safe. The 4 in `test-suite-gate.tests.ps1` the scan reports are
its own prose and its `#1326` fold test *data*, not paths a run creates; its one real fixture is
rewritten by hand.

### CREATE

- [x] Rewrite the 96 guid-less composing statements in `scripts/tests/` — `$PID` kept in front, any
      trailing extension kept at the end, via a scripted transform reviewed shape by shape (56 distinct
      shapes clustered first; 1:1 diff, 96 insertions against 96 deletions, no reformatting)
- [x] Rewrite `test-suite-gate.tests.ps1`'s own fixture by hand — the guard is excluded from its own scan
- [x] Tighten the rule in `test-suite-gate.tests.ps1`: the discriminator is a fresh guid, and `$PID`
      alone no longer passes
- [x] Pin the two by-name allowances (`$tag`, `$Guid`) to a real guid assignment, so the convenience
      cannot decay into a fixed value
- [x] Point the `#1326` fold cases at the live pattern rather than a second copy of it, and add the one
      case that separates the new rule from the old (a `$PID`-only path)
- [x] Record the convention in `scripts/README.md` — both halves, and why `New-ScratchPath` is not the
      instrument here
- [x] Correct `native-capture.tests.ps1`'s exclusion comment, which recorded `tests/` as knowingly left
      standing

### TEST

- [x] `test-suite-gate.tests.ps1` green — 85 pass, 0 fail
- [x] Both new asserts proved to BITE, not merely to pass: a guid stripped from a real suite is reported
      as `agent-shared.tests.ps1:21`, and `$tag = 'fixed'` is reported as `shared-scripts.tests.ps1:75`.
      Both restored afterwards and re-verified green
- [x] The full lint gate green — `check-plugin-integrity.ps1`, 0 errors
- [x] All 81 suites green — 427s, 16 lanes
- [x] Reviewed by Victor (code review), Sebastian (security) and Nolan (cost) on the diff
- [~] No new suite added. The rule and its enforcement both live in `test-suite-gate.tests.ps1`, which
      already owns this subject and now carries three new asserts; a separate suite would have to
      re-scan the same tree to say the same thing

### DEPLOY: fix/1664-fixture-temp-path-guid

Every temp fixture path in `scripts/tests/` now carries a fresh guid as well as `$PID`, and the rule in
`test-suite-gate.tests.ps1` requires it — `$PID` alone no longer passes. 96 statements across 53 suites
were rewritten to `<label>-$PID-<guid>`, which is exactly how `New-ScratchPath` composes a path one
layer up: the pid stays in front because it is what attributes a leftover to a run that is still alive,
and the guid is what nobody can name in advance.

This is the half [#1659](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1659) did not
close. `$PID` is neither secret nor large, so a composed leaf was a name a local actor could reach
first — and `New-Item -ItemType Directory -Force` and `Remove-Item -Recurse -Force` both follow a
reparse point, so a symlink or junction pre-planted there redirected the write *and* the teardown.
Measured before the repair: 100 guid-less paths, with 116 recursive deletes standing at one of them
across 50 files. #1659 covered seven sites in the shipping layer and only one of those deleted
recursively, so the delete half of the class was almost entirely here.

Two guards were also hardened rather than merely satisfied. The by-name allowance for `$tag` and
`$Guid` — which four sites legitimately need, where one path per *child invocation* is required and
`$PID` is the same for all of them — is now pinned to a real guid assignment, so it cannot decay into a
fixed value while still passing. And the `#1326` continuation-fold cases now match on the live pattern
instead of a second copy of it: they were still asserting the old alternation, which would have left
the file proving a rule it no longer enforced.

**Score:** 3

#### What makes this deploy extra special

N/A — this reaches no subscriber. It is a hardening of this repo's own test fixtures; nothing in the
plugins a consumer installs changes, and no consumer-facing behaviour moves. The one thing a consumer
could notice is second-order: `scripts/README.md`'s fixture convention is the page a consumer writing
their own suite reads, and it now asks for the guid.

**Score:** N/A

#### Pull Request

Test fixture temp paths carry a guid, so a pre-planted link cannot redirect the write or the recursive delete

