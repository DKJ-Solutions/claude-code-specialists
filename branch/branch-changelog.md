## `feat/test-gate-commands` changelog

### Branch title

The test gate can run a consumer's own test commands

### Branch ID

20260813-134353

### Branch type

feat

### What does the change on this branch bring to main?

The shared test gate (`Invoke-TestSuiteGate`) can now see a consumer's whole suite. Inbound
[#644](https://github.com/DaveKJohn/claude-code-specialists/issues/644) measured the gap: the gate
globbed `scripts\tests\*.tests.ps1` and nothing else, while both callers describe it as *"all test
suites green"* — true in this repo, whose suites are all PowerShell, and an overstatement in the
reporting consumer, whose 4 PowerShell suites sit beside 605 Vitest tests the gate never saw. The
release route is where that bites: it is the one route with no later gate that can still stop
anything, since CI fires only after the tagged commit is pushed — a commit this repo's own rules say
is not rewritten.

The seam is the optional `Get-TestCommands` in `scripts/repo-config.ps1`: extra command lines (an
`npm test`, a `pytest`) the gate runs alongside the suites, each as its own child with the native exit
code propagated, a non-zero exit failing the gate exactly like a failing suite. It is read **inside**
the shared gate function rather than at the call sites, so the gates cannot drift into checking
different things — and the callers are **three**, not two, which the pre-PR review caught: `open-pr`
and `cut-release` have `repo-config.ps1` in scope from their own dot-source, while `ci.yml` — the one
caller that actually blocks a merge — dot-sourced only the gate lib and would have been the one gate
that could not see the commands, silently. CI now dot-sources `repo-config.ps1` too, guarded for a
repo that has none. The same review hardened the judging: a command that does not parse is refused
rather than run truncated, and a pure-PowerShell entry that fails without setting a native exit code
(`Write-Error` and stop) fails the gate via `$?` instead of coercing to exit 0. The default is none: a
repo that states nothing keeps
exactly yesterday's gate, and a repo whose whole suite is `Get-TestCommands` (no `scripts\tests` at
all) now runs a real gate instead of a skipped one. The contract gains the record (`Adopt = 'decide'`:
which commands test a repo is a fact about its stack no script can read), the blueprint artefact is
regenerated, and `cut-release.ps1`'s seam list grows to eight.

The doc half of the issue is repaired too: the guardrail list in `releases/README.md` under-reported
the cut's own gates — it named the lint gate and `-SkipTierGate` but not the test gate or `-SkipTests`,
so a reader planning a release from the page did not know a test gate could stop them. The list now
carries both, with the reason the gate sits before the first write: it is the last moment a red suite
can still stop anything.

### Significance

#### Tier 0

This repo's own gate is byte-for-byte the same run — its suites are all PowerShell and it defines no
`Get-TestCommands` — so the change here is the documentation being complete.

**Score:** 1

#### Tier 2

A consumer with an app layer can now put its real suite behind the PR gate and the release gate by
answering one seam, instead of running it as a standing hand-step after every cut — the reporting
consumer ran `npm test` manually after `v2.5.1` because the cut did not know that suite existed, and
its app-layer work has just started earning minors, which is exactly the layer the gate could not see.

**Score:** 4

### Pull Request

