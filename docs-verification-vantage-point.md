### Verifying from the wrong vantage point — the false-failure half of the lesson · Docs · 2026-07-29

`roster-sync.tests.ps1` asserts that the git-root fallback lands on the repo the test runs inside. Run
by absolute path out of a linked worktree while the shell's working directory was still the main
checkout, it failed on precisely that assertion: `git rev-parse --show-toplevel` answers for the
*process's* directory, not for the script's, so `$PSScriptRoot` pointed at the worktree while git
pointed at the main tree. Result: 125 pass, 1 fail — a red suite caused entirely by where it was
launched from, and the obvious misreading is "the branch under test broke something". `Push-Location`
around the run (or `git -C`) is the whole fix.

Recorded in [Sylvester #15's lens](.claude/plugins/claude-specialists/specialists/05-15-extension.md) as
the sibling of the `Write-Host` trap logged earlier the same day, because they are the same underlying
mistake seen twice: **verifying from the wrong vantage point.** The `Write-Host` case produced a false
*pass* (an in-process assertion about host output reads 0 whether the line is there or not); this one
produced a false *failure*. So the rule that ties them is not "distrust green" or "distrust red", but:
before believing either verdict, confirm the check was observed from the same place its real consumer
observes it — the hook runs the check as a child process, and a suite judges the tree it was launched
in.

Worth keeping because both happened within a single session on July 29, 2026, and the second one was
nearly reported to Dave as a genuine regression.
