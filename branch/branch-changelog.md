## `fix/test-fixtures-survive-a-concurrent-run` changelog

### Branch title

Every suite's temp fixture is per-process, so two concurrent runs cannot break each other

### Branch ID

20260811-172305

### Branch type

fix

### What does the change on this branch bring to main?

Fourteen temp fixture paths across eleven test suites used a **fixed** name in the system temp directory, so
two runs of the same suite at once built their fixture in the same place and tore down each other's tree
mid-assert. The visible result is a red gate naming a subject that is perfectly fine -- the most expensive
kind of false failure, because the obvious next move is to go and read the subject.

**Found by being bitten, not by inspection.** Running the full suite in the background while `open-pr.ps1`
ran its own test gate produced a failing `connectors.tests.ps1`, a suite that passes on its own. Reproduced
before anything was changed rather than reasoned about: two concurrent runs gave **159 pass / 2 fail** each,
against 161/0 alone. After the fix the same two runs give **161 / 0** twice, and `teardown.tests.ps1` --
which had three fixed paths -- gives 208/0 twice.

**This asserts a convention the suites had already chosen.** Measured before touching anything: **38** of
the temp paths already carried `$PID` or a fresh GUID and **14** did not. So the repair is those 14 catching
up, which is also why none of them gained an explanatory comment -- the 38 that were already right carry
none either, and commenting half of them would make the correct form read as the odd case.

Two things the first, crude scan got wrong and a closer look corrected, because both would have been noise:

- `new-branch.tests.ps1` and `shared-scripts.tests.ps1` build their capture files from a **fresh GUID**, not
  from a bare label. Collision-safe already, and deliberately GUID rather than `$PID`: they create one file
  per child invocation, where `$PID` would be identical for all of them.
- `bootstrap-drift.tests.ps1:318` keyed only on a per-case `$Label`, which looks discriminating and is not:
  it varies *within* a run and repeats *across* them. It was in the real subject list.

**The guard lives in `test-suite-gate.tests.ps1`**, which is the suite that owns this question: since
[#512](https://github.com/DaveKJohn/claude-code-specialists/issues/512) the gate is a throttled **parallel**
scheduler, and that is what makes overlapping runs ordinary rather than exotic -- a gate run beside a
developer running one suite by hand is enough. It scans every path built on `GetTempPath()` and names the
offending `file:line`, and its subject is the *discriminator* rather than the spelling, so `$PID`, a GUID and
a label built on top of either all pass while a bare literal does not.

**Verified in both directions**, because an assert that passes by being unable to see anything is the trap
this very suite's docstring warns about: it reports how many files and how many paths it actually read (33
and 51), and a literal reintroduced into one file turns it red naming `connectors.tests.ps1:21`.

There is deliberately no collision *within* one gate run -- each fixture name is unique per suite -- so
nothing here changes how the gate behaves today. What it removes is a false failure that costs its reader a
detour into innocent code, which is what it cost the run that found it.

### Significance

#### Tier 0

A false red on the gate is the worst kind here, because the branch is blocked and the named subject is
innocent -- and the gate is the last thing between a branch and a PR. It cost exactly that detour on August
11, 2026. Fourteen paths, one guard that names the file and line, and the rule written where a new suite's
author meets it before the gate tells them.

**Score:** 3

#### Tier 1

Nobody outside this repo's own developers can observe it: the suites are this repo's, the gate is this
repo's, and no shared script or plugin content changed. A colleague on this project gains nothing they could
notice.

**Score:** N/A

#### Tier 2

No consumer runs these suites. `scripts/tests/` is not mirrored into the plugin, so nothing here reaches
anybody's install.

**Score:** N/A

### Pull Request
