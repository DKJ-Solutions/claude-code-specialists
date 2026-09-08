## fix/1635-fixture-git-judged-siblings

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

#### The finding, verified before it was repaired

Issue [#1635](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1635) named
`scripts/tests/worktree-lane.tests.ps1` and it stands exactly as reported: its `Invoke-Git` is the
better of the two helper shapes in that directory -- it *returns* `@{ Code; Out }` -- and the fixture
builder then piped every one of those verdicts to `Out-Null`.

**Two things in the report needed correcting, and both changed the work.** First, the repair it proposes
reusing was **not on `main`** when this branch opened: #1622's fix sat on the parked branch
`fix/1622-fixture-git-judged`, so `sync-main.tests.ps1` still discarded the exit code here and the file
was left alone to keep the two branches from colliding. That parked branch became PR
[#1640](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1640) and merged while this
branch's own gate was running -- see the last CREATE step for what that changed. Second, the report's
own table is
disclaimed as untrustworthy and is: its right-hand column counts any mention of `$LASTEXITCODE` or
`.Code` in a file, including asserts *about* the script under test. Measured per helper instead of per
file, the sweep is wider than the table's nine rows and the priority order is different.

#### What was measured, and the four shapes it found

Every fixture-building git call under `scripts/tests/`, read by what its helper does with the exit code:

- **Discarded outright, fifteen of them** -- `remote-ahead-lib`, `gate-lib`, `prune-merged`,
  `machine-local-gate`, `backing-gate` (a named helper piping to `Out-Null`); `park-commit`,
  `park-branch`, `park-cycle`, `entry-scaffold`, `new-branch`, `fold-changelog`, `bootstrap-drift`,
  `sync-rules` (the inline `& git ... | Out-Null` idiom); `plugin-versions`, `connector-sessioncheck`
  (a `Git-X` that returns the output and drops the verdict).
- **Returned and then thrown away** -- `worktree-lane`, the report's own instance.
- **Already judged, left alone** -- `publish-to-business` and `unfolded-entry-gate` both *throw* on a
  non-zero exit.
- **Not a subject** -- a git call that is a QUESTION rather than a mutation. Every read
  (`rev-parse`, `log`, `status`, `diff-tree`, `for-each-ref`, `hash-object`, `ls-files`, `ls-remote`)
  and every existence probe whose non-zero exit *is* the answer the case wanted.

#### Why a shared lib rather than the same block fourteen times

The repaired shape is about forty lines of judging, counting, printing and a summary. Pasted into
fourteen suites it is a duplication finding on arrival, and a rule that lives in fourteen places drifts.
So the rule has one source and each suite keeps its own helper signature and its own EAP handling --
which is what made the pass a substitution rather than fourteen redesigns.

### CREATE

- [x] `scripts/lib/fixture-git-lib.ps1` -- the rule in one place: `Assert-FixtureGitOk` (judge one
      call), `Invoke-FixtureGitJudged` (array form), `Invoke-FixtureGitIn` (the `& git -C $dir <rest>`
      idiom), `Get-FixtureGitFailureCount` and `Write-FixtureGitSummary`. Workshop-only -- nothing under
      `scripts/tests/` is mirrored into a plugin, so it is not in the shared-scripts registry.
- [x] `Invoke-FixtureGitIn` takes **no `param()` block**, deliberately. An advanced function binds a
      leading-dash argument to a parameter name, so `branch -D <name>` would resolve `-D` against a
      `-Dir`-style parameter and silently change the command that runs. git's own flags include
      `-C`, `-c`, `-D`, `-R`, `-q`, `-m` and `-b`; a simple function passes every one through verbatim.
- [x] Seventeen suites converted: the fifteen discarding outright, `worktree-lane`, and `sync-main` (see
      below). Each dot-sources the lib, judges its fixture mutations, and fails the run on the count.
- [x] The count does not throw. A suite that dies at the first hiccup reports less than one that runs on
      and names what broke -- so the summary at the foot is what turns the count into an exit code,
      **including on a run where every assert passed**.
- [x] `sync-main.tests.ps1` **is** converted after all, and the reason it changed mid-branch is worth
      keeping: it was deliberately left alone while #1622's repair sat on a parked branch, and PR #1640
      merged while this one's own gate was running. Catching up on `main` therefore pulled an **inline**
      copy of exactly this rule into the branch. Folding it onto the shared source was the alternative to
      filing the contradiction my own change had created -- the duplication is gone instead of tracked,
      and the file keeps `Invoke-Git`'s signature plus every paragraph of #1622's reasoning, with one
      added note saying where the implementation now lives.

### TEST

- [x] `scripts/tests/fixture-git-lib.tests.ps1`, new: 15 asserts over real git commands, a succeeding
      one and a failing one. The counter starts at zero, a working call is not counted, a failing call is
      counted once and accumulates, the summary answers `$true` and does not reset, and a dashed flag
      reaches git verbatim -- asserted on the argument vector the failure line reports, which is the only
      place the resolved arguments are observable from outside. That suite runs no
      `Write-FixtureGitSummary` gate at its own foot, and says why: it fails fixture commands on purpose.
- [x] Every converted suite run individually, all green: `remote-ahead-lib` 43, `sync-rules` 152,
      `park-commit` 28, `park-branch` 31, `park-cycle` 91, `entry-scaffold` 747, `new-branch` 255,
      `backing-gate` 49, `machine-local-gate` 42, `prune-merged` 113, `gate-lib` 123,
      `fold-changelog` 254, `bootstrap-drift` 205, `worktree-lane` 35, `fixture-git-lib` 15, and
      `sync-main` 126 after the fold above.
- [x] **The new judging caught its first two cases on its first run, and they were the conversion's own
      over-reach rather than fixture defects.** `park-cycle` reported 5 failures and `new-branch` 1, every
      assert green -- exactly the shape #1635 predicted. All six were one `Test-RefOnRemote` per suite:
      `rev-parse --verify --quiet` on a ref that is *expected* to be absent, judged by the very next line.
      Both are back to a raw `& git` with the reason written at the call site, because counting a negative
      case as a broken fixture would report every passing negative as a defect.
- [x] Nine converted suites came out with mixed line endings, from a scripted insertion that wrote CRLF
      into LF files. `.gitattributes` would have normalised them on checkin; they were normalised in the
      working copy anyway, so what is committed is what was tested.
- [x] `check-plugin-integrity.ps1`: 0 errors, 228 `.ps1` parsed, `[script-ascii]` green over the two new
      files.
- [x] **CI went red on the first ship, on this branch's own new suite, and the cause was the suite rather
      than the lib.** `fixture-git-lib.tests.ps1` failed shard 4 with 2 of 15 asserts red -- both the ones
      matching the *reported command string* in case 5, while the count asserts beside them stayed green,
      which is what pinned it to the text and not to the behaviour. Case 5 captures `Write-Host` through
      the information stream, so it goes through PowerShell's formatter, and the formatter hard-wraps at
      the running host's buffer width. The reported command carries a temp path, so on the runner the
      wrap landed inside it. That is issue #1512's rule, which this repo already writes in three suites
      and which this one ignored: those asserts now go through an `Assert-Says` that strips **all**
      whitespace from both sides.
- [x] And the repair is verified against a wrap rather than against a green run, because a green run is
      exactly what it had before: held against a sample broken mid-word, the stripped matcher finds the
      phrase (`True`) where the old `-match [regex]::Escape(...)` does not (`False`). Normalizing runs of
      whitespace to one space would not have fixed it either -- the formatter breaks at whatever
      character sits at the column, inside a word as readily as between two.
- [~] No separate pre-run of the full test gate: `open-pr.ps1` runs it and refuses to push on a failing
      suite, so a copy set going ahead of it proves nothing that gate would not have caught.

### DEPLOY: fix/1635-fixture-git-judged-siblings

A test fixture's own git commands are now judged in every suite that builds one. The standing idiom was
`& git -C $dir init -q 2>$null | Out-Null` inside a lowered `$ErrorActionPreference` -- and lowering the
preference is right and stays, because git writes ordinary progress to stderr and under `EAP=Stop` that
is a terminating error before any exit code is read. What was wrong is that the **exit code went with
it**: a git command that failed was indistinguishable from one that worked. That matters more in a
fixture than in production code, where a failed git usually goes on to fail visibly: a fixture that
ignores one produces a repo that is *plausible* -- it exists, it has a HEAD, it just does not hold what
the case assumed -- and every assert below it then measures the wrong thing, attributing the failure to
the script under test. Thirty concurrent lanes over one temp tree make a transient `index.lock` sharing
violation ordinary rather than rare, so the shape to expect is a suite that is red under the gate, green
alone, and silent about why.

`scripts/lib/fixture-git-lib.ps1` now holds that rule once -- judge, print git's own output, count, and
fail the run on the count **even when every assert passed**, because a clean sweep over a repo that was
never built proves less than it appears to. Seventeen suites route through it; each keeps its own helper
signature, so the pass was a substitution rather than fifteen redesigns. Reads and existence probes are
deliberately not subjects, and the two that were converted by mistake are back to a raw `& git` with the
reason at the call site. `sync-main.tests.ps1` -- where #1622 wrote the rule inline, merged from `main`
part-way through this branch -- reads the shared source too, so the forty lines exist once rather than
sixteen times.

**Score:** 3

A red gate now names the broken fixture instead of the script that was fine, which is the difference
between reading a failure and spending a 190s run reproducing one that may not reproduce. Noticed the
moment it fires and invisible until then, so not higher.

#### What makes this deploy extra special

Nothing -- this is the source repo's own test suites, which no consumer runs and no release ships. The
lib is workshop-only by design: nothing under `scripts/tests/` is mirrored into a plugin.

**Score:** N/A

#### Pull Request

fixture git commands are judged in every suite

