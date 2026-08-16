## `feat/split-the-lint-gate-suite` changelog

### Branch title

The lint-gate suite is four suites, so the gate stops being one process

### Branch ID

20260816-105859

### Branch type

feat

### What does the change on this branch bring to main?

`check-plugin-integrity.tests.ps1` is four suites -- `-links`, `-commands`, `-entries`, `-docs` -- over
one shared, non-asserting `check-plugin-integrity-fixture.ps1`. **The local test gate drops from 196-235s
to 142-170s**, measured four times each side in the same harness.

The reason it works is the shape of the gate rather than anything about the tests: it parallelises per
**file**, and that one file WAS the gate's whole wall clock -- equal to it to a tenth of a second, four
runs out of four, with 15 of 16 lanes standing idle for its last 70-86 seconds
([#714](https://github.com/DaveKJohn/claude-code-specialists/issues/714)). Splitting it hands that work
the empty lanes. The four parts now run 121.9 / 106.8 / 75.1 / 54.6s beside each other, and the gate is
bounded by two suites together instead of by one.

**Nothing was dropped to buy the time, and that is checkable rather than claimed:** the same 110 gate
invocations run, in the same order, against the same fixture, and the asserts still sum to **234** --
48 + 42 + 69 + 75, the exact count the single file reported. Narrowing test scope was explicitly refused
in #714 and is not what happened here. The scenario text is byte-identical: the four files were sliced
from the original by line range, so only the scaffolding around them is new.

Three smaller things travel with it, each of which the work turned up rather than assumed:

- **One piece of shared scenario state was found by parsing, not by reading.** `$s24Contributing` -- the
  quiet root document the coverage block needs -- was written 500 lines above its second use. A split
  turns that into a silent `$null` rather than an error, so every generated part was parsed for variables
  it reads but never assigns. Exactly one turned up, and it now lives in the fixture lib.
- **Sylvester's lens carried a claim this falsifies**, and it is corrected in place rather than deleted:
  *"it cannot be parallelised the way the gate was, because all 86 scenarios mutate one fixture directory
  in sequence."* True about scenarios, wrong about the unit -- the gate schedules files.
- **The three live-repo lint asserts now print what the gate found when they fail.** In the first
  post-split pooled run `bootstrap-drift` and `fix-mojibake` went red together on exactly those asserts,
  green alone, clean in the next three runs and unreproducible under eight concurrent lint runs -- and
  *"expected 0, got 1"* was all either of them said. Undiagnosed and reported as such; what changed is
  that the next occurrence will name the finding.

### Significance

#### Tier 0

The gate that runs twice in every release and once before every PR is a quarter shorter, and the suite
that dominated it is no longer a single lane. Nobody has to change how they work to get it.

**Score:** 3

#### Tier 2

N/A -- the suites are this repo's own and travel to no consumer; the shared gate lib's mirror changed
only in its explanatory comment.

**Score:** N/A

### Pull Request

