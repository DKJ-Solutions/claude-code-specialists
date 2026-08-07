## `feat/the-suites-run-in-parallel` changelog

### Branch title

The test gate runs its suites in parallel

### Branch ID

20260807-223731

### Branch type

feat

### What does the change on this branch bring to main?

`Invoke-TestSuiteGate` — the gate `open-pr.ps1`, `cut-release.ps1` and CI all run — starts its suites
concurrently under a throttle instead of one at a time. Measured on one machine within one session, all 27
suites green every time: **510s one at a time, against 128–263s parallel over six runs, median 159s**. The
range is quoted rather than the best run on purpose — the first parallel measurement taken happened to be
the 128s one, and alone it would have promised a 4× gain the gate delivers only sometimes. **That spread is
the mechanism rather than noise:** a sum averages its own variance out and a maximum does the opposite, so a
gate bound by its slowest suite is inherently less predictable than one bound by the total. Which is also
what makes the other half of
[#512](https://github.com/DaveKJohn/claude-code-specialists/issues/512) matter more than it did before:
`check-plugin-integrity.tests.ps1` alone is ~154s, so it *is* the gate time now. That was measured too —
86 `Invoke-Integrity` calls, each a fresh `powershell` start (~0.18s) plus a full lint over the fixture
(~1.6s) — and deliberately not repaired here: all 86 scenarios mutate one fixture directory in sequence,
so the repair is a redesign of that suite's fixtures, not a change to the gate.

**Safety was established before the scheduler was written, not after it went green.** Two properties had to
hold: no suite writes into the repo tree (every `$RepoRoot` reference is a read, or a `Copy-Item` out of it
into a fixture), and no two suites share a fixture path — the fixed-name ones each own their name, the rest
key on `$PID`. Both were checked across all 27 files, and the check to repeat before adding a suite that
touches either is recorded in Sylvester's lens.

**Parallelism costs the console, which is why each child's output is buffered to its own files and printed
as one block when it exits.** Attribution therefore comes from the `== <suite> ==` header a block opens
with rather than from its position — which was already the honest description of the sequential version,
but was previously true by accident. Blocks now arrive in completion order, so the run closes with a
summary that names the failing suites in a fixed order and reports the elapsed time; without it, in a
27-suite weave the one red header sits two thousand lines above the prompt.

**`ci.yml` stopped keeping its own copy of the loop.** It walked `scripts/tests` with an inline `foreach`
until now, which is how an improvement to the gate can reach both local callers and miss the only one that
actually blocks a merge — the required check. It calls the shared function, and passes
`-MaxParallel ([Environment]::ProcessorCount)` because the default deliberately holds two cores back to
keep a developer's machine usable, and on a four-core runner nobody is sitting at, that reservation would
cost half the box.

**Two `Start-Process` traps were measured while building this and are recorded in Sylvester's portable
manual**, both of the family that repo already collects — a plausible value instead of an error:
`-PassThru` returns a process whose `ExitCode` reads back **empty** because the OS handle was not retained
(the first version therefore judged every suite `FAILED (exit )` while printing its passing output
underneath), and `Start-Process` starts a child in `[Environment]::CurrentDirectory`, which does not follow
`Set-Location` — so omitting `-WorkingDirectory` would have silently handed every suite a different
vantage point than `& powershell -File` did, with `roster-sync.tests.ps1` going red for a reason nobody
would look for in the gate.

`-MaxParallel 1` is the way back to one suite at a time, for the failure this change makes possible: a
suite that only fails with 26 siblings competing for the disk. The new
`scripts/tests/test-suite-gate.tests.ps1` covers what had only wiring-level coverage before — the two
empty-input contracts, atomic per-suite blocks, stderr landing inside its own block, the real exit code
surviving into the verdict, that it genuinely runs in parallel and that the valve genuinely does not, and
the working directory the child is handed.

### Significance

#### Tier 0

Every piece of work here passes this gate, twice if it also runs `cut-release`, and it went from more than
eight minutes to between two and four. That is a different working rhythm rather than a nicer number: a gate this
cheap removes the standing temptation to reach for `-SkipTests`, which is the one thing that would make the
repo's merge-without-a-second-reviewer arrangement unsafe. The two `Start-Process` traps landing in the
manual are worth as much again — the first version of this change judged every suite failed while printing
each one's passing output underneath, and nothing about that looked like a bug in the gate.

**Score:** 4

#### Tier 1

CI runs this same gate on every PR and every push to `main`, so the required check that decides whether
anything merges gets the same treatment. The part that lasts longer than the minutes, though, is that CI
stopped holding a private copy of the loop: this improvement would have reached both local callers and
missed the one gate nobody can bypass, which is the drift shape this project keeps paying for.

**Score:** 3

#### Tier 2

`native-capture-lib.ps1` is mirrored into the plugin, so a consuming repo's own `open-pr` and
`cut-release` get the parallel gate through a plugin update without choosing it or configuring anything —
and the more suites they have accumulated, the more it is worth. They also inherit `-MaxParallel 1` for the
one failure mode it introduces, so the answer to "does this suite only fail under load?" ships together
with the load.

**Score:** 3

### Pull Request
