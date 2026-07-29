### What a fresh consumer actually sees at session start, measured · Fix · 2026-07-29

Dave's requirement: it is fine that a consumer still has work to do after installing, **as long as
they are told**. That turns "nul verrassing" into something measurable, so it was measured instead of
reasoned about — and the reasoning had been wrong. The prediction was "three neutral messages that
read as *everything is fine*". The reality is the opposite.

**`scripts/tests/fresh-consumer.measure.ps1`** builds a synthetic consumer in the exact state a real
one is in right after enabling the plugin and restarting — its own `CLAUDE.md`, no lenses, no
repo-config, no orchestrator import — and runs the three `SessionStart` hooks against it the way the
harness does. Committed rather than run ad hoc, because the whole point is that round two is
comparable to round one; a measurement done by hand cannot be repeated identically. The `.measure.ps1`
suffix keeps it out of CI's `*.tests.ps1` glob: it reports numbers, it asserts nothing.

| | before bootstrap | after a successful bootstrap |
|---|---|---|
| `[ERROR]` lines at session start | **44** | **21** |
| lines naming `specialists-init` | **0** | **0** |

A consumer who enables the plugin and restarts gets 44 red lines and no mention of the skill that
resolves them. That does not read as "something still needs doing" — it reads as "this plugin is
broken". Meanwhile the one calmly-worded channel says literally *"no action is needed on your side."*
And the happy path does not end clean either: **21 error lines survive a correctly executed
bootstrap.**

Three defects follow from the numbers and are filed separately, since they are independently fixable:

- **Nothing points at `specialists-init`** — in either state, across all three hooks. The skill itself
  communicates well (five concrete next steps, a paste-ready register block); the defect is that
  nothing leads a consumer to it.
- **The bootstrap fails the plugin's own contract check.** Three of the 21 remaining errors name
  `Test-BranchName`, `Get-RosterPath` and `Get-RosterIgnoredIds` — functions absent from the `VUL-IN`
  scaffolds the bootstrap itself just wrote. The installer produces output its own checks reject.
- **The roster check silently passes Chris.** 18 ids report missing after a bootstrap, not 19: the
  `@`-import line `@.claude/plugins/.../01-01-extension.md` contains the token `01-01`, so
  `check-roster-sync` counts him as rostered. The worst possible id to lose — a persona appears in no
  always-on listing, so the roster row is the only thing making him exist for a session.

What is *not* broken, stated because it is the half worth protecting: nothing crashes, all three hooks
exit 0, and the subagents work. This is a communication failure, not a functional one.

**Two verification lessons recorded in
[Sylvester #15's lens](.claude/plugins/claude-specialists/specialists/05-15-extension.md), both earned
the hard way in this same pass.** `Select-Object -First N` tears a pipeline down and kills the
still-running child process, while `-Last N` must drain the stream and therefore cannot: piping
`bootstrap.ps1` into `-First 1` created zero lenses and reported nothing wrong, into `-First 20` it
wrote 19 lenses and exited 255, and `-Last 25` on the identical command completed cleanly. The harness
then measured an unbootstrapped repo while labelling the numbers "after bootstrap", and the first
hypothesis reached for was a bug in `Get-DerivedRepoName` — tested across three git states, all exit
0, hypothesis wrong. The harness now captures in full before slicing and aborts on a non-zero setup
exit rather than measuring past it. The second lesson generalises the Chris finding: when a check's
evidence is "the token appears in the file", ask what else in that file legitimately contains the
token before trusting a pass.
