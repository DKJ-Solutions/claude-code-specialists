## `fix/release-runs-the-suites` progress

### Steps

- [x] Extract `open-pr`'s suite loop into `Invoke-TestSuiteGate`, shared rather than copied
- [x] Call it from `cut-release` before the first write, with `-SkipTests` as its own escape valve
- [x] Pin the wiring: both callers use the shared helper, and the gate precedes the first write
- [x] `cut-release`'s own docstring, the `cut-release` skill, and a stray orphaned heading it carried
- [x] Full chain via `ship-pr` alone

### Where I left off

Lint clean, guardrail suite 29 asserts green.

**Two things worth carrying forward.**

The first assert on "runs before the first write" **failed, and the assert was wrong, not the code**: it
searched for `WriteAllText`, which matches the DEFINITION of `Write-Utf8NoBom` near the top of the file --
before the gate, writing nothing. A position assert has to anchor on the thing that happens, not on the
thing that is declared. It now anchors on the first `Write-Utf8NoBom -Path` call.

`cut-release`'s docstring carried a **duplicate `Steps (all on main):` heading** with the SHARED paragraph
under it instead of steps. Pre-existing, not introduced here -- checked against `HEAD` before removing it,
because a cosmetic fix attributed to the wrong change is its own small lie.

Next in the queue: #506 + #505 (`Branch title` IS the PR title), then #509, #507, #508.
