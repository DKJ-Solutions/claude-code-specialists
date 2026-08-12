## `feat/lint-skip-checks` changelog

### Branch title

The lint gate can skip named checks, so its own test suite stops running all 26 to test one

### Branch ID

20260812-114010

### Branch type

feat

### What does the change on this branch bring to main?

The test gate runs its suites in parallel, so it costs what its **slowest single suite** costs — and
that was `check-plugin-integrity.tests.ps1` at **207.8 s**, nearly three times the next one
(`roster-sync.tests`, 73.5 s). The gate's whole wall clock was one suite.

**Measured before changing anything, and the measurement moved the target twice.** Instrumenting the
suite showed **98% of its time inside 110 child lint runs** — fixture setup and asserts together were
3.4 s — so nothing about the suite's *size* was the lever. Profiling one lint run over the fixture then
showed three checks were half of every run: `agent-def`, `parse` and `branch-template`. Almost no
scenario in the suite is about any of them, so almost every run was paying for all three.

`check-plugin-integrity.ps1` takes `-SkipCheck <names>`, and the suite passes those three by default.
Result: **207.8 s → 159.2 s**, with 16 asserts *added* rather than removed.

**What was NOT done, and why the first plan was dropped.** The obvious repair was batching the 110 runs
into fewer, or giving the lint a `-Only <check>` filter — but `-Only` means wrapping all 26 blocks in a
conditional inside the gate that guards every PR, which is 26 chances to leave a check switched off.
Skipping the three measured hot ones needs three wrapping points for most of the same win. The wider
version stays available if it is ever worth it.

**Three guard rails, because the failure mode this parameter introduces is silence** — a gate that
checked less and still reported `0 errors`:

- **a skipped check prints `[SKIP]` and no coverage line at all.** This gate deliberately makes an
  empty scan visible, so `checked 0` is a finding-shaped statement; a skip that printed it would be
  indistinguishable from a check that found nothing to examine;
- **an unknown name exits 2** — distinct from 1, so bad usage is never read as findings. A misspelled
  `agentdef` would otherwise run the check it meant to skip, and a scenario asserting the *absence* of
  a finding would pass while testing nothing;
- **no production caller may pass it.** A test holds `open-pr.ps1`, `cut-release.ps1` and `ci.yml` to
  running the full set — asserted on the callers, because the parameter cannot know who invoked it.

That vacuous-pass risk is not theoretical: wiring the suite up, one branch-template scenario was missed,
and its assert on the **exit code** still passed — the fixture has other errors — while only its assert
on the **message** failed. Presence asserts fail loudly without `-Full`; absence asserts do not, which
is why the four (now five) scenarios that need the full run are named in a comment above
`Invoke-Integrity` rather than left to be rediscovered.

**Where the remaining time goes, so the next reader does not re-profile it.** Per run it is now ~380 ms
of fixed overhead (process start ~160 ms, dot-sourcing six libs ~260 ms) and ~610 ms spread thinly over
21 checks, none dominant — largest `lifecycle` 133 ms, `shared-script` 116 ms, `entry-heading` 92 ms.
There is no third hot spot to remove. Going further means attacking the run *count* or the fixed
overhead, both materially more invasive than this, and the gate is still bound by this suite.

**One finding left deliberately unbuilt, and one bug worth knowing.** On the *real* repo the hot checks
are different — `mojibake` 2.4 s, `lifecycle` 2.0 s, `config-blueprint` 0.9 s of a ~10 s run — and
`mojibake` is 24% because it **spawns a whole nested PowerShell process** to run
`fix-mojibake.ps1 -Check` from inside a script that is already one. That is every `open-pr`, every CI
run and every cut, and it is a separate change. Separately: this suite **leaks its fixture on a crash** —
five directories from August 6–10 were still in `TEMP` when this was measured.

### Significance

#### Tier 0

The gate every branch waits on twice — once locally in `open-pr`, once in CI — loses a quarter of its
wall clock, and the profile behind it is written down so the next person tuning it starts from numbers
instead of from the line count, which is what prompted this and turned out to predict nothing.

**Score:** 3

Is there a tier above this one?

#### Tier 1

The method is the transferable half: *profile before trimming*. The premise here was that ~18,000 lines
of tests were too many, and the measurement showed that deleting 30 of the 31 suites would have saved
the gate nothing, because it is bounded by a maximum rather than a sum. Two of the three candidate
repairs were dropped on evidence rather than taste.

**Score:** 2

Is there a tier above this one?

#### Tier 2

Nothing here reaches a consumer. `scripts/lint/` is repo-owned and the plugin ships none of it, so
neither the parameter nor the saving exists outside this repo.

**Score:** N/A

### Pull Request
