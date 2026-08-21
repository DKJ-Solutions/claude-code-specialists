## `fix/git-paths-decode-independently-of-the-console` deployment

### What does the change on this branch deploy to main?

The Shopify pre-task sync reads a path off git's **wire format** instead of off whatever console code page
the run inherited, so a theme file with a non-ASCII character in its **name** is judged the same way on
every machine. Filed as
[#821](https://github.com/DaveKJohn/claude-code-specialists/issues/821) -- and the interesting part is
that the issue's own conclusion was inverted.

**What #821 reported.** `sync-main.tests.ps1`'s `quotepath` assert fails when the suite is run on its own
and passes when the test gate runs it, on the same commit, on the same machine, minutes apart. It
deliberately proposed no fix, on the grounds that the mechanism was not established -- correct discipline,
and the reason this repair starts with a measurement rather than a patch. It also concluded *"Not
correctness, and not the gate"*, and that half is wrong.

**The axis, measured.** Not the platform, not the launch mechanics, not concurrency for its own sake --
the **console output code page**:

| how it ran | code page | result |
|---|---|---|
| standalone, this machine's shell | cp850 | **FAIL** |
| standalone, code page forced to UTF-8 | cp65001 | PASS |
| the gate's own `Start-Process` from a cp850 parent | cp850 | **FAIL** |
| started 1.2s after `session-status.tests.ps1` | cp850 -> 65001 | **PASS** |

That last row is the whole mystery. `session-status.tests.ps1:253` set
`[Console]::OutputEncoding = UTF8` and released it 274 lines later -- and that setter is
`SetConsoleOutputCP`, which is a property of the **console**, not of the process. The gate starts every
suite with `-NoNewWindow`, so all 50 share one console: any suite scheduled inside that window silently
decoded native output as UTF-8. Reproduced deterministically, both directions.

**What that was hiding, and it is a production defect.** `sync-main.ps1` asked git for paths with
`core.quotePath=false`. Measured against git 2.54:

```
core.quotePath=true   ->  "sections/caf\303\251.liquid"    (pure ASCII on the wire)
core.quotePath=false  ->  sections/caf<C3><A9>.liquid      (raw bytes, decoder-dependent)
```

Windows PowerShell 5.1 decodes a native child's stdout with `[Console]::OutputEncoding`. On cp850 -- the
default OEM console here -- those two bytes become two wrong characters, the path then matches no key the
mirror walk produced, and the sync lands in precisely the failure the flag had been added to prevent: the
trunk's copy reads as a path live does not have while live's **identical** file reads as content the trunk
has never held. *Foreign, taken, the trunk's version overwritten.* The flag fixed the **quoting** half and
moved the same bug into the **decoder**, where it was invisible because the answer now depended on who
launched the run.

**So the wire is held to ASCII and the decoding is done in code.** Quoting is forced **on** -- `true`
rather than git's default, because a repo may set `core.quotepath` in its own config -- and
`Convert-GitQuotedPath` in `scripts/lib/sync-rules.ps1` unpacks the octal `\NNN` escapes and the C escapes
into bytes and reads them as UTF-8 once. Every candidate code page agrees below 0x80, so no environment can
reach the result. Both path-producing calls go through it: `ls-tree` and `check-ignore`. An unquoted path
passes through untouched, which is what makes it safe on every line -- git quotes only when it must, so a
path with nothing above 0x7F in it needs no decoding by definition.

Verified at **cp850, cp1252 and cp65001**, green in all three; it was red at cp850 before the change,
which is the negative control.

**The second half: the suite that made the gate lie.** The console mutation is scoped from 274 lines down
to the two asserts that genuinely need it, with its own `finally`, and the comment says plainly that this
**reduces** the hazard rather than removing it. Per-process console isolation -- giving each suite its own
hidden console instead of `-NoNewWindow` -- is the honest fix and is deliberately **not** built here: it
changes how all 50 children are created, for a hazard whose one known instance is now a few lines wide.
`Invoke-TestSuiteGate`'s docstring names it instead, together with the rule the measurement produced:
**a suite that is green under the gate and red standalone is reporting a real defect until proven
otherwise, because the gate is the run with the shared state in it.** The instinct runs the other way --
the gate is what CI trusts -- and that instinct is what bought this bug its cover.

Three things were deliberately **not** repaired, each said out loud rather than left looking covered:
`git status --porcelain` also quotes paths, but its output is counted rather than compared, so the cost is
one cosmetically wrong line in a dirty-tree warning; `check-ignore`'s **input** side, where paths cross
into argv, is a second and unmeasured axis; and the gate's console sharing, above.

The lesson is recorded in three layers: the portable half in
[Tycho's manual](plugins/teams/team-alpha/manuals/04-18-manual.md) (a suite that mutates shared state, and
what a green-under-the-runner/red-standalone pair actually means), the script-layer half in
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md) as the mirror image of the rule
about a character a script must *emit*, and the mechanism itself in the two docstrings that own it.

**Score:** 4

#### What makes this change extra special

A consumer running this sync on a Windows box with the ordinary OEM console had a silent data-loss path on
any theme file with an accent, a diaeresis or an en dash in its **filename** -- and the one test that saw
it reported green in CI, so nothing anywhere would have told them. Storefront section and snippet names
are exactly the population where that happens. The repair also lands the reading rule next to the writing
rule, which is the pair a consumer's own scripts need: this repo has now been bitten once in each
direction by the same boundary.

**Score:** 4

### Pull Request

A git-reported path is decoded off the wire, not off whatever console code page the run inherited
