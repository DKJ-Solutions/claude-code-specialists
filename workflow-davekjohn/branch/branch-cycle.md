# `fix/git-paths-decode-independently-of-the-console` cycle · 20260821-203936

## PLAN

- [x] Reproduce #821's symptom: the suite is red standalone, n=1 here, same as reported.
- [x] Establish the axis by measuring instead of reasoning. Forced cp65001 -> PASS, cp850 -> FAIL, gate's
      own `Start-Process` from a cp850 parent -> FAIL. So it is the console code page, and the gate's
      launch mechanics are not the difference.
- [x] Find what makes the real gate differ: `session-status.tests.ps1:253` set
      `[Console]::OutputEncoding` -- `SetConsoleOutputCP`, console-WIDE -- for its whole run, and the gate
      shares one console across all suites. Reproduced deterministically: sync-main alone red, sync-main
      started 1.2s after that suite green.
- [x] Check the report's conclusion. #821 says "Not correctness, and not the gate"; measured against
      `git 2.54`, that is exactly inverted -- the standalone red was the true signal.

## CREATE

- [x] `Convert-GitQuotedPath` in `scripts/lib/sync-rules.ps1`: unpacks git's C-quoting (octal `\NNN` plus
      the C escapes) into bytes and reads them as UTF-8, so no console can reach the answer.
- [x] `scripts/task/sync-main.ps1`: both path-producing git calls -- `ls-tree` and `check-ignore` -- now
      force `core.quotePath=true` (ASCII on the wire) and pass every path through the converter. Forced
      rather than left to git's default, because a repo may set `core.quotepath` itself.
- [x] Mirrored both to `plugins/teams/team-shopify/scripts/`, byte-identical.
- [x] `scripts/tests/session-status.tests.ps1`: the console mutation is scoped from 274 lines down to the
      two asserts that need it, with its own `finally`. Stated in the comment that this REDUCES rather
      than removes the hazard -- per-process console isolation is a harness rewrite this repair does not
      carry.
- [~] Isolating the console per suite in `Invoke-TestSuiteGate`: not built. It changes how all 50 children
      are created, for a hazard whose one known instance is now a few lines wide. Named in the docstring
      instead, with the measurement and the rule it produces.
- [~] `git status --porcelain` (`sync-main.ps1:244`) also quotes paths: left alone. Its output is counted,
      not compared, so a mojibake path costs a cosmetically wrong line in a dirty-tree warning and nothing
      else. No pre-emptive fix.
- [~] The `check-ignore` INPUT side -- paths crossing into argv -- is a second, unmeasured axis. Not
      touched, and said out loud rather than assumed fixed.

## TEST

- [x] `sync-rules.tests.ps1`: 10 new unit asserts on the converter, including that the quoted wire form
      carries no byte above 0x7F -- the property the whole repair rests on. 61 asserts, all pass.
- [x] `sync-main.tests.ps1`: the accented case now passes at **cp850, cp1252 and cp65001**, measured in
      all three. It was red at cp850 before the change, which is the negative control.
- [x] `session-status.tests.ps1`: 61 asserts still pass with the narrowed window.
- [x] Lint gate + all suites via `open-pr.ps1`.

## DEPLOY

## Where I left off
