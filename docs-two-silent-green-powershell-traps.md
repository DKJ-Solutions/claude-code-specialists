### two PowerShell traps that fail to green, from the check-11 build · Docs · 2026-07-31

Step 6 of the round, recorded where it will be found rather than left in a session. Building check 11
(PR [#290](https://github.com/DaveKJohn/davekjohns-workshop/pull/290)) cost two debug cycles, and both
had the property this whole test round was about: **the wrong answer arrived as a plausible value
instead of an error.** Both are now rules in
[Sylvester #15's lens](.claude/specialists/lenses/05-15-extension.md), next to the `$LASTEXITCODE`
piping rule, the stderr-under-`Stop` rule and the variable-shadowing rule — the same family, and the
same reason for being written down.

**A fenced code block silently shifts every inline-backtick span after it.** A `` `[^`]+` `` pattern
cannot open a span on the first two backticks of a fence delimiter, opens one on the third, and closes
it on the first backtick of the *closing* fence — after which every real inline span downstream pairs
one position out. Nothing errors. In the measured case a command whose `--scope project` sat on the next
line of its own span came back looking **flagless**, so the gate under-reported instead of raising. The
fix is not a second fence walker: `Get-FenceMaskedText` already exists for check 10 and keeps offsets
and newline positions identical, so a span found in the mask indexes straight back into the real text.
Recorded with its sibling from the code review — judge one command's own arguments, not the whole span,
or two commands in one span let the second borrow the first one's flags.

**`return @($x)` does not return an array when `$x` is one item.** PowerShell unrolls a single-element
array on return, so the caller gets a bare `[string]` and `$result[0]` is its first *letter*. The nasty
part is that `.Count` is `1` either way, so the length guard meant to protect the index passes happily.
Measured in `teardown-protocol.tests.ps1`, where a `check-ignore` line's first field read as `.` instead
of `.gitignore:2:`. Rule: wrap at the **call site** too when you are going to index or slice, rather
than trusting `@()` inside the function.

Deliberately in Sylvester's lens rather than only in the code comments where each was first written
down: a comment sits in the one script that already has the fix, while the next doc-scanning or
fixture-building script is where the trap gets stepped in again.
