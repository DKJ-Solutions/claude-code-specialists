## `docs/gate-wall-clock-is-one-suite` changelog

### Branch title

The test gate's wall clock is one suite, and the assert count in the record was one suite's too

### Branch ID

20260816-102602

### Branch type

docs

### What does the change on this branch bring to main?

Issue [#714](https://github.com/DaveKJohn/claude-code-specialists/issues/714) reported the local test
gate at 322.5s, "about +40%", with the growth "diffuse, not one offender". Picking it up began with a
recount, and the recount inverted the diagnosis: re-measured four times in the gate's own pool
(`MaxParallel 16`, 18 cores, 40 suites green), the gate runs at **196–213s** — inside the 205–232s
baseline it was said to have left — and in every single run the **total is one suite to a tenth of a
second**. `check-plugin-integrity.tests.ps1` starts first and finishes last; the other 39 suites are
done at 126.9s, after which one process runs alone for 70–86s with 15 of 16 lanes empty.

Nolan #25's lens (`.claude/specialists/lenses/06-25-extension.md`) records the measurement: the four
runs, the 160.2s standalone figure that shows ~40s of the suite's in-pool time is sibling contention,
the `MaxParallel 8` result (194.3s) declared **inside the noise** rather than sold as a saving, and the
one repair with a measured ceiling — splitting that suite would bound the gate at 153.2s, about -25%,
and would do nothing for CI. Proposed, not built.

Two counting corrections travel with it. #714's "234 asserts" is exactly what that one suite prints for
itself; across all 40 suites the figure is **4,206**, and the wall-clock table's "210 asserts" carried
the same error and no longer states a number it never had. And Chris #01's lens
(`.claude/specialists/lenses/01-01-extension.md`) gains the fourth instance of its fifth intake pattern — the finding is real and its size is wrong — with
the half that is new: **a timing is a count too**, and #714's stopwatch reading was taken while the
machine was running the team-wide review that filed it.

### Significance

#### Tier 0

Corrects a figure the team measures against and records why this particular number cannot be read
without its machine state — the next person to time the gate would otherwise chase a 40% regression
that four runs say is not there.

**Score:** 3

#### Tier 2

N/A — the lenses are this repo's own; no consumer receives them, and the gate they describe is
unchanged by this branch.

**Score:** N/A

### Pull Request

