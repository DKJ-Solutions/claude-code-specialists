### fold-changelog folds into a configurable section heading · Fix · 2026-07-25

`fold-changelog-entry.ps1` hardcoded the section it folds into (`## Pull Requests`) and the section
boundary below it (`## Releases`). A consumer whose changelog uses a different heading got a hard
stop before anything was touched — and `repo-config.ps1` had no slot to say otherwise. In
`djcylow-react` (Keep-a-Changelog: `## [Unreleased]` with released versions as `## [vX.Y.Z]` below
it) the skill simply could not run: five entries were folded by hand there today, each one a chance
to get the merge date, the newest-first ordering or the BOM-less write subtly wrong.

**`Get-ChangelogHeading`, optional and defaulted.** New in `scripts/repo-config.ps1` (and in the
`specialists-init` scaffold, so a fresh consumer gets it): the literal heading line the fold inserts
under, `'## Pull Requests'` by default. `fold-changelog-entry.ps1` reads it through a `Get-Command`
guard exactly the way `open-pr.ps1` handles its optional repo-config functions, so **every existing
consumer keeps working unchanged** — a repo-config that predates this contract simply gets the
default. The not-found message now names both the heading it looked for and the function to set.

**The section boundary is derived, not hardcoded.** The insert position used to be "before the first
`###` entry, or else before `## Releases`". On a Keep-a-Changelog file that second literal does not
exist, so the entry would have landed at the end of the file rather than at the top of
`[Unreleased]`. The boundary is now structural — whichever comes first after the heading, the first
`###` already in the section or the next `##` section — which reproduces the old behaviour exactly
in this workshop and is correct on Keep-a-Changelog too.

**Declared in the script contract as an INFO signal.** `check-script-contract.ps1` gains an
`Optional = $true` record type: a missing optional function reports `[INFO]` naming the fallback
instead of `[ERROR]`, so it never turns a working consumer red — but a Keep-a-Changelog consumer is
told about it before fold time rather than discovering it at fold time.

**Bug found while testing.** The first implementation named its local variable `$changelogHeading`
while `repo-config.ps1` backs the function with `$script:ChangelogHeading`. PowerShell variable
names are case-insensitive and at script top-level the local and script scopes are the same, so the
default assignment silently overwrote the dot-sourced value and the configured heading always read
back as `## Pull Requests`. Renamed to `$foldHeading`, with the reasoning recorded at the call site
— a sibling of the `$RepoRoot`/`$repoRoot` collision already documented in this script.

Covered by `scripts/tests/fold-changelog.tests.ps1` (a Keep-a-Changelog fixture: folds, and lands
below `[Unreleased]` and above the released section; a heading that is not found stops cleanly with
the entry file intact; a repo-config without the function still folds under the default) and
`scripts/tests/script-contract.tests.ps1` (the optional record reports INFO, exit 0). From inbound
issue #178 (source: DaveKJohn/djcylow-react).
