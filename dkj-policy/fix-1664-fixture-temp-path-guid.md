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

**Can the sites be routed through `New-ScratchPath`?** Reachable, but the wrong instrument. Only 22 of
the 85 suites dot-source `native-capture-lib.ps1` (1406 lines), so **37 of the 53** files that had to
change would need a new dot-source of it; worse, `New-ScratchPath -Directory` creates *without* `-Force`
and throws on an existing item, so routing the sites through it changes every fixture's setup and
teardown shape rather than just its path composition. Declined, and the reasoning is recorded in
`scripts/README.md` so the next reader does not re-open it.

#### Three figures were wrong when first written, and none was caught by a gate

Worth recording together, because all three are the same mistake — trusting a working note instead of
re-running the measurement — and the third was caught by a reviewer rather than by me.

1. The **recursive-delete** count was taken *including* this guard's own file while the guid-less count
   beside it excluded it: two adjacent numbers under two different rules, which is the drift a reader
   cannot see. Corrected to **114 across 49**, both excluding the guard.
2. The **dot-source** figure was counted from the suites that merely *name* the lib rather than those
   that dot-source it, understating it as 28. Corrected to **37 of 53**, which makes the argument for
   declining stronger rather than weaker.
3. The **22** in the paragraph above survived that pass unverified, and Edith measured **18** — a real
   disagreement rather than a slip on either side. Both are right about different things: 18 suites name
   `native-capture-lib.ps1` on their own dot-source line, and 4 more reach it through a variable holding
   its path (`. $LibPath`, `. $NativeCaptureSrc`), so 22 dot-source it and a literal grep for the
   filename sees 18. The caution is now in `scripts/README.md` beside the figure, because the next
   person to check it will reach for the same grep.

**Is it worth doing?** Yes, by the cheap route: keep `$PID`, append a fresh guid inline — exactly
`New-ScratchPath`'s own `<label>-$PID-<guid>` — and tighten the gate's own rule so the class cannot
come back. The pid stays because it is what makes a leftover attributable to a live run, which is what
`#1636`'s note and the gate's capture glob both rely on.

#### The count differs from the issue's, and both are right

#1664 reported 108 statements across 66 files, measured on `feat/1659-temp-path-unpredictable` at
`922604a7`. Measured here after that branch merged: **100** across 53 files, and they resolve as

| | |
|---|---|
| rewritten by the scripted transform | **96** |
| already safe — they build their leaf from `$tag`, itself a fresh guid (`new-branch`, `shared-scripts`) | **4** |
| **total the scan reports** | **100** |

`test-suite-gate.tests.ps1` is excluded from that scan and contributes to none of those rows. It holds
four `GetTempPath()`/`Join-Path` pairs of its own — a *separate* four, in its prose and its `#1326` fold
test **data**, not paths any run creates — plus one real fixture, which is rewritten by hand.

### CREATE

- [x] Rewrite the 96 guid-less composing statements in `scripts/tests/` — `$PID` kept in front, any
      trailing extension kept at the end, via a scripted transform reviewed shape by shape (56 distinct
      shapes clustered first; 1:1 diff, 96 insertions against 96 deletions, no reformatting)
- [x] Rewrite `test-suite-gate.tests.ps1`'s own fixture by hand — the guard is excluded from its own scan
- [x] Tighten the rule in `test-suite-gate.tests.ps1`: the discriminator is a fresh guid, and `$PID`
      alone no longer passes
- [x] Pin the two by-name allowances (`$tag`, `$Guid`) to a real guid assignment, so the convenience
      cannot decay into a fixed value
- [x] **Re-do that pin on the AST after Sebastian broke the first version three ways** — a parameter
      default, an assignment inside a one-line block, and one after a semicolon all defeated a
      start-of-line regex, while the outer rule went on calling the resulting path safe. Also bounded the
      *width*, since `Substring(0, 1)` names a guid and yields four bits
- [x] Point the `#1326` fold cases at the live pattern rather than a second copy of it, and add the one
      case that separates the new rule from the old (a `$PID`-only path)
- [x] Collapse the duplicate file walk Nolan measured (0.64s), and **gate the AST parse on the fold that
      is already paid for** — parsing all 84 suites costs 5.5s, which would have made the fix eight times
      worse than the defect; only 3 files name either variable, and parsing those costs 1.5s
- [x] Record the convention in `scripts/README.md` — both halves, and why `New-ScratchPath` is not the
      instrument here
- [x] Correct `native-capture.tests.ps1`'s exclusion comment, which recorded `tests/` as knowingly left
      standing

### TEST

- [x] `test-suite-gate.tests.ps1` green — 94 pass, 0 fail (85 before this branch; +9 asserts)
- [x] Every new assert proved to BITE, not merely to pass. A guid stripped from a real suite is reported
      as `agent-shared.tests.ps1:21`; `$tag = 'fixed'` as `shared-scripts.tests.ps1:75`; and a planted
      parameter default (`[string]$tag = 'sneaky'`) as `shared-scripts.tests.ps1:74` — that last one run
      against a **real suite**, so it exercises the name-probe gate the synthetic probe files bypass. All
      restored afterwards and re-verified green
- [x] **The AST helper's own first version found nothing and looked green.** `UnqualifiedPath` returns an
      empty string on Windows PowerShell 5.1 (measured, 5.1.26100.9278), so all six evasion cases
      reported 0. Caught only because those cases assert a positive count; the failure mode is written
      into the function's docstring
- [x] The full lint gate green — `check-plugin-integrity.ps1`, 0 errors
- [x] All suites green locally — three full-gate runs on this branch (483s, 729s, 782s, 16 lanes)
- [x] **CI caught a 97th site the local runs could not see, and it was the new rule working.** The first
      PR run failed `test-suite-gate.tests.ps1` on `session-cache-lib.tests.ps1:29` — a guid-less fixture
      path in a file that did not exist on this branch. `main` had gained 24 commits meanwhile, one of
      them #1672's session cache, and CI tests the **merge**. So the rule flagged a path this branch had
      never met, which is exactly what it is for. Merged `origin/main` in (clean), rewrote that site, and
      re-ran. Worth recording because a green local gate is not evidence about the merge, and the
      staleness race is what `ship-pr` guards for the other direction
- [x] Reviewed by Victor (code), Sebastian (security), Edith (copy) and Nolan (cost). Every finding
      acted on in this branch: Sebastian's two guard evasions, Nolan's duplicate walk, Edith's three
      prose findings and her disputed dot-source count. Victor found no correctness defect
- [~] No new suite added. The rule and its enforcement both live in `test-suite-gate.tests.ps1`, which
      already owns this subject and now carries nine new asserts; a separate suite would have to
      re-scan the same tree to say the same thing
- [~] The litter consequence needed no repair, and the issue I filed about it was **wrong about why**.
      A guid path can never be reclaimed by a later run's pre-delete, and that pre-delete was already
      reclaiming essentially nothing — so this branch does not make the near-term rate worse. But I filed
      [#1668](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1668) claiming
      `fold-changelog.tests.ps1`'s `New-Tree` never tears down, and it does: it registers every tree the
      moment it builds one and sweeps that register twice, and has since the file was created. I counted
      `Remove-Item` occurrences instead of reading the register — the symptom was real, the reason was
      invented. Another session measured it properly and closed #1668 as completed: both suites leak
      **zero** when run to completion, the leftovers are all registered *after* a suite's last completed
      sweep (the signature of an aborted run), and of my 413 figure **546** entries were
      deliberately-retained `sync-pr-body-*` files and **162** an unrelated tool's logs. The measurement
      now lives in `scripts/README.md`, merged into this branch from `main` and left as they wrote it

### DEPLOY: fix/1664-fixture-temp-path-guid

Every temp fixture path in `scripts/tests/` now carries a fresh guid as well as `$PID`, and the rule in
`test-suite-gate.tests.ps1` requires it — `$PID` alone no longer passes. 96 statements across 53 suites
were rewritten to `<label>-$PID-<guid>` (98 with the two that arrived from `main` mid-branch), which is
exactly how `New-ScratchPath` composes a path one layer up: the pid stays in front because it is what
attributes a leftover to a run that is still alive, and the guid is what nobody can name in advance.

Both of those two are the same shape, and worth naming because it is the one this branch cannot close
by itself: a suite written on `main` while the rule lived only here arrives green by its own lights and
guid-less by ours. The second, `fanout-lib.tests.ps1`, composed `fanout-lib-test-$PID` and stood at it
with both `New-Item -ItemType Directory -Force` and `Remove-Item -Recurse -Force` — the write half and
the teardown half of exactly the failure above. The gate is what caught each of them on the merge, which
is the argument for the gate rather than against the branch: once this lands, `main` carries the rule and
the next such suite is refused where it is written instead of here.

This is the half [#1659](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1659) did not
close. `$PID` is neither secret nor large, so a composed leaf was a name a local actor could reach
first — and `New-Item -ItemType Directory -Force` and `Remove-Item -Recurse -Force` both follow a
reparse point, so a symlink or junction pre-planted there redirected the write *and* the teardown.
Measured before the repair, this guard excluded from both counts: 100 guid-less paths, with 114
recursive deletes standing at one of them across 49 files. #1659 covered seven sites in the shipping
layer and only one of those deleted recursively, so the delete half of the class was almost entirely
here.

Two guards were also hardened rather than merely satisfied. The by-name allowance for `$tag` and
`$Guid` — which four sites legitimately need, where one path per *child invocation* is required and
`$PID` is the same for all of them — is now pinned to a fresh guid **of usable width**, read from the
parsed syntax rather than the line text. That second half is the review's doing: a start-of-line regex
was the first shape, and a parameter default, an assignment inside a one-line block and one after a
semicolon all walked past it while the outer rule went on calling the resulting path safe. And the
`#1326` continuation-fold cases now match on the live pattern instead of a second copy of it: they were
still asserting the old alternation, which would have left the file proving a rule it no longer enforced.

The guard costs about 1.5s. Parsing all 84 suites would cost 5.5s, so the parse is gated on the fold the
scan already performs — only three files name either variable, and a file naming neither cannot hold an
assignment to one.

**Score:** 3

#### What makes this deploy extra special

N/A — this reaches no subscriber. It is a hardening of this repo's own test fixtures; nothing in the
plugins a consumer installs changes, and no consumer-facing behaviour moves. The one thing a consumer
could notice is second-order: `scripts/README.md`'s fixture convention is the page a consumer writing
their own suite reads, and it now asks for the guid.

**Score:** N/A

#### Pull Request

Test fixture temp paths carry a guid, so a pre-planted link cannot redirect the write or the recursive delete

