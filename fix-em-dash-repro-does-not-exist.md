### The em-dash defect was in the test fixture, and the weakened assert was hiding it · Fix · 2026-08-04

**The branch name records a wrong conclusion, kept rather than rewritten.** It was opened as
`fix/em-dash-repro-does-not-exist` after four negative measurements suggested the reported defect was
gone. That was wrong. It reproduces reliably — just not where the report said, and not where those four
measurements were looking. The name stayed because the fold matches on the exact branch name, and
because a corrected record is worth more than a tidy one.

**The symptom was real, the cause was not.** `release-lib.tests.ps1` carried a comment saying an em-dash
in an existing `## Releases` heading is re-emitted on a line of its own, that this *"reproduces against
release-lib as it stands on main"*, and that it therefore was not that change's doing. On the strength of
that, the assert below it was narrowed — *"deliberately NOT on the whole heading line"* — to check only
that the LIVE marker survived. **`release-lib` was never involved.** The defect is in the fixture:

```powershell
@( 'HEAD', '', '### [v1.0.0] - 2026-01-01 ' + $emDash + ' Minor', '', 'TAIL' )   # 7 elements, not 5
```

Inside a comma-separated array literal PowerShell takes the three operands of `'a' + $x + 'b'` as three
**elements**, and the `-join` that follows turns the seams into newlines. Both headings in that fixture
reached `Split-Changelog` already broken across three lines, with the separator alone on the middle one.
The function then passed through faithfully what it was handed. Assigning the concatenation to a variable
first, or interpolating, yields the 5 elements the author wrote.

**And that is why it never reproduced against the real `CHANGELOG.md`.** Checked three times and each
time read as evidence that *"the cause is not isolated yet"* — while it was the opposite: the real file
is **read from disk**, so it never passes through the construction that causes this. Those three
negatives were the clue, not the obstacle. Fed straight through `Convert-ChangelogForRelease` the real
document comes out clean: the `## Releases` section goes from 73 em-dashes to 74 — exactly the one new
heading — all 72 existing headings returned character-for-character, zero lines holding a lone em-dash.

**What the weakening actually cost.** The narrowed assert checked that the marker survived, not that the
heading carrying it came over intact — so nothing in this section was comparing against the document the
author had written. Every assertion here had been running against a fixture broken at both of its
headings, silently, for as long as the comment stood. The strong anchored form runs now, the fixture is
asserted before it is used, and the original report became a standing check on both branches.

**Verified by negative control rather than by passing.** With the fixture put back to its `+` form, five
assertions go red: the two new fixture-shape checks, the strong heading assert, and the bare-separator
check on both the knob-on and knob-off outputs. **203 asserts, up from 199.**

**Three rules to Tycho's portable manual, because none of this is specific to this repo.** Assert a
hand-built fixture's shape before asserting against it — and treat *"this assertion is deliberately
weaker than it could be"* as the tell that a defect is being described instead of caught, with the
fixture as likely a suspect as the code. A weakened assertion needs a **verified** reason, since
narrowing around observed behaviour records that behaviour as a fact about the subject. And a new test
must be **shown to fail**: an assertion only ever seen passing is not known to test anything.

**The history keeps the wrong explanation.** `plugins/specialists/CHANGELOG.md` and the archived v3.2.0
notes still carry it, deliberately — they record what was believed then, and the repo excludes history
from its checks for that reason.
