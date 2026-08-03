### Wrap-proof the captured-output asserts in the branch test suites · Fix · 2026-08-03

`new-branch.tests.ps1` failed one assert on this machine while the script under test behaved exactly as
specified, and CI was green on the same commit. The assert is
`-Name main: pointer names the main rule`, matching on `must not be 'main'`.

The cause is formatting, not behaviour. A native child's stderr captured with `2>&1` does not arrive as
plain text: PowerShell wraps each line in a `NativeCommandError`, renders it with a `powershell.exe : `
prefix, and wraps the whole record at the **host width**. So the wrap point moves with the width of the
window the suite happens to run in and with the length of the fixture's temp path — the user name and
`$PID` are both in it — and none of that is a property of `new-branch.ps1`. Measured at width 176, the
break landed **mid-word**: `... Branch name mus` + `t not be 'main'.`

Mid-word is the detail that decides the repair. Collapsing whitespace to a single space, the way
`shared-scripts.tests.ps1` does inline at line ~656, yields `name mus t not be` and still does not match.
Removing the newlines, the way that same file's `Test-OutputContains` does at line ~128, restores the
phrase. That file already held both the right answer and the weaker one, and neither had reached the two
branch suites.

- **`scripts/tests/new-branch.tests.ps1`** — a `Get-FlatOutput` helper used by all three child-capture
  points, plus a synthetic regression assert. Synthetic on purpose: the real wrap only appears at
  particular console widths, so a test that waited for it would pass here and prove nothing elsewhere.
- **`scripts/tests/park-branch.tests.ps1`** — the same helper. Its three phrase asserts (`on main`,
  `parked on origin`, `nothing new to commit`) sit in the same kind of record and were one window width
  away from the same failure.
- **Deliberately not covered, and stated rather than tested into passing:** a wrap landing exactly *on* a
  space. If the formatter drops that space, newline-removal glues the words together. Whether it drops it
  has not been measured — the observed break was mid-word — and the note in the code says what to do if it
  ever bites.

Not caused by the rename. The first reading blamed the longer repo path from `davekjohns-workshop` to
`claude-code-specialists`; that was wrong, because the fixture lives under the temp directory and carries
no repo name at all. The failure reproduces on `main` and is decided by the console width.
