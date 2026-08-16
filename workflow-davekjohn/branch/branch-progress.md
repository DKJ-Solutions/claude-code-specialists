## `feat/split-the-lint-gate-suite` progress

### Steps

#### PLAN

- [x] Map the single file: 111 gate invocations, one mutated fixture, where the scenario groups end
- [x] Pick boundaries at check-group edges, so no scenario is reordered and none is rewritten

#### CREATE

- [x] `check-plugin-integrity-fixture.ps1`: the shared fixture builder, assert helpers, `Invoke-Integrity`
- [x] Four suites sliced from the original by line range -- scenario text byte-identical, only the
      scaffolding around them is new
- [x] Delete the single file and repoint every live reference (the lint's own docstring, the shared gate
      lib and its mirror, three sibling suites)
- [x] Record the result: Tycho #18 (the convention for the four), Sylvester #15 (his "cannot be
      parallelised" claim corrected), Nolan #25 (the after-measurement)

#### TEST

- [x] Static check: parse each generated part for variables it reads but never assigns -- found exactly
      one piece of shared state (`$s24Contributing`), which moved into the fixture lib
- [x] All four green, asserts 48 + 42 + 69 + 75 = **234**, the exact count the single file reported
- [x] Lint gate green after the split
- [x] The whole gate re-measured after the change, in the same harness as before it: 142.4 / 145.5 /
      170.3 / 169.9s against 196-235s
- [x] Chase the two red suites in the first post-split run: green alone, clean in three further runs,
      unreproducible under eight concurrent lint runs -- left undiagnosed and said so, with the three
      live-repo asserts taught to print what the gate found

### Where I left off

