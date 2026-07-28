---
id: 15
group: 05
---

# Sylvester ⚙️ · davekjohns-workshop addendum

> Repo-lens (davekjohns-workshop) accompanying the portable playbook in the `specialists` plugin (`claude-code-plugins/claude-specialists/specialists/manuals/05-15-manual.md`). This file does not describe the craft, but what Sylvester does in this repo.

A system administrator does the same thing everywhere — manage the harness and the tooling the team
works in: scripts, config, the safety guards. **What is repo-specific in davekjohns-workshop is not
that Sylvester maintains the harness, but which scripts, manifests, and config that involves here.**
In this repo that is a large and visible part of the work, because the repo is itself a piece of
infrastructure.

### What Sylvester owns here

- **`scripts/lint/check-plugin-integrity.ps1`** — the PR lint gate: validates `marketplace.json` +
  every `plugin.json` and the agent-def/manual frontmatter (`name`/`id`/`group` + filename match),
  scans for dead links (in `README.md`, `CHANGELOG.md`, the manuals, `SKILL.md`s, and `releases/**`),
  checks that every `scripts/**/*.ps1` parses without errors (catching syntax errors in the
  orchestration that would only break at runtime), guards (check 7) that every shared-block
  region in an agent def still equals its source in `agent-shared/`, and guards (check 9) that
  every plugin's consumer-facing `RELEASE.md` card is present and its `vX.Y.Z` matches that
  plugin's `plugin.json` — since both only ever change together, via `cut-release.ps1`, a
  mismatch can only mean a forgotten regeneration or a hand-edit. This is the safety guard that
  [Derek #05](05-05-extension.md)'s `open-pr.ps1` runs before every push — and that `cut-release.ps1`
  runs before a release.
- **`.github/workflows/ci.yml`** — the CI gate on GitHub: runs the same lint gate + all test suites
  (`scripts/tests/*.tests.ps1`) on every PR and every push to `main`, so the guard also applies to
  work that comes about outside `open-pr.ps1`. Since July 15, 2026, the repo ruleset
  **`main-ci-gate`** (renamed from `main-ci-poort` by Dave on July 26, 2026; found at GitHub →
  Settings → Rules) enforces that gate as a **required status check**: a PR to `main` only merges
  on a green `lint-en-tests` job. The bypass list (Repository admin + the Write role, "Always
  allow") keeps the direct fold/release commits on `main` possible — the work account `davekokbwj`
  has write rights, not admin. That Write bypass is safe as long as there are no external
  collaborators and must be revisited as soon as there are.
- **`scripts/lint/check-consumer-drift.ps1`** — the read-only drift check against a consuming repo
  (`MISSING`/`IDENTICAL`/`DRIFTED`).
- **`scripts/lib/branch-info.ps1`** — the prefix→label→changelog-type table (shared with the
  release scripts). Deliberately no `release` prefix: a release does not go via a branch/PR but
  directly on `main`.
- **`scripts/lib/release-lib.ps1`** — the pure release helpers (version bump, CHANGELOG
  transformation to a `## Releases` reference, and the assembly of the `releases/development/` notes)
  that [`cut-release.ps1`](../../../../scripts/release/cut-release.ps1) dot-sources; deliberately
  pure so [Tycho #18](04-18-extension.md) can test them in isolation. The release *process* is
  [Rendall #06](05-06-extension.md)'s domain; Sylvester guards the script mechanics underneath.
- **`scripts/agents/build-agent-defs.ps1` + `scripts/lib/agent-shared-lib.ps1`** — the generator
  that fills the verbatim-shared bullets from
  `claude-code-plugins/claude-specialists/agent-shared/<name>.md` into all agent defs (between
  `<!-- BEGIN/END shared:… -->` sentinels). Change a shared block →
  run `build-agent-defs.ps1` → all agent defs updated; `-Check` (and the lint gate, check 7) fails
  on drift. The pure expansion logic lives in the lib, so [Tycho #18](04-18-extension.md) can test
  it in isolation — mirroring the `release-lib` setup. **Never edit between the sentinels by hand.**
- **`.claude/settings.json`** — this repo's harness config: the `extraKnownMarketplaces` (the
  `github` source `DaveKJohn/davekjohns-workshop`) and `enabledPlugins` with which the repo enables
  its own `specialists` plugin (group 1).
- **The manifests** `.claude-plugin/marketplace.json` and every `<plugin>/.claude-plugin/plugin.json`
  (structure + `version`) — their *structure/config*; the descriptive *texts* he coordinates with
  [Tessa #16](06-16-extension.md).

### Repo-specific rules

- **The agent-def frontmatter and the `plugin.json` `version` land here first**, never in a consuming
  repo — those pull them in. An agent-def config change is Sylvester's side; the agent-def *text* is
  Tessa's side.
- **The lint gate may never become quieter than the risks.** As the repo grows (more plugins, more
  complex manifests), Sylvester extends the checks — with [Tycho #18](04-18-extension.md) building
  tests alongside.
- **Always read `$LASTEXITCODE` before you pipe a native command through a cmdlet.** A construct like
  `& git … | Select-Object -First 1` cuts the upstream (git) short as soon as the first item is in;
  if the process has not yet exited cleanly at that point, it ends with a non-zero exit code —
  purely timing-dependent. Whoever reads `$LASTEXITCODE` afterwards therefore gets a flaky value and
  builds a non-deterministically red CI. The rule: capture the full output first, record
  `$code = $LASTEXITCODE` immediately, and only then filter (`Select-Object`, `Where-Object`, …) on
  the fixed array. It took three PRs on the git derivation in `bootstrap.ps1` (`Get-DerivedRepoName`) — #94
  (regex coverage), #95 (`insteadOf` rewriting), and #96 — before this pitfall was recognized as the
  root cause; the rule applies to every `scripts/**/*.ps1` that calls a native command.
- **A native command's stderr under `$ErrorActionPreference = 'Stop'` becomes a *terminating*
  error — even when the command exits 0.** `git push` writes its `remote:` progress to stderr, so
  under `Stop` PowerShell 5.1 aborts the script on the push before the `$LASTEXITCODE` check can run
  (this bit `open-pr.ps1`'s push step). Sibling of the rule above: don't lean
  on stderr-as-failure. Run the call with `$ErrorActionPreference = 'Continue'` around it, capture
  `2>&1` (or `2>$null` when you only want stdout, e.g. `gh ... --json`), record `$LASTEXITCODE`,
  restore the preference, and only then judge. Applies to every native call whose stderr is normal
  chatter — `git push`/`git fetch` (`remote:`), **`git add` (the autocrlf LF↔CRLF warning — this
  broke `cut-release.ps1` while cutting v1.12.0)**, `gh` (auth/update notices), … Query commands
  (`git rev-parse`, `git status`) write results to stdout and only real errors to stderr, so `Stop`
  is correct there — don't wrap those. Swept across all release scripts after the v1.12.0 break.
- **Never name a local variable after a `$script:` variable a dot-sourced repo lib owns.** PowerShell
  variable names are case-insensitive, and at script top-level the local scope *is* the script scope
  — so `$changelogHeading = '<default>'` in a script that has dot-sourced `repo-config.ps1`
  overwrites that file's `$script:ChangelogHeading` **before** the `Get-…` accessor is ever called.
  The accessor then dutifully returns the default, and the configured value silently disappears: no
  error, no warning, just the fallback everywhere. This bit the `Get-ChangelogHeading` work for
  inbound #178; the fix is a distinct local name (`$foldHeading`). Sibling of the `$RepoRoot`/
  `$repoRoot` collision already documented at the top of `fold-changelog-entry.ps1`. Rule: when you
  read an optional repo-config value into a local, give the local a name that is not the backing
  variable's — and prove it with a test that sets a *non-default* value, since a test using the
  default passes either way.
- **Never dot-source a consumer's repo-owned lib under `Set-StrictMode`.** A check or hook that
  dot-sources `scripts/lib/branch-info.ps1` or `scripts/repo-config.ps1` to probe it (e.g.
  `check-script-contract.ps1`, `check-roster-sync.ps1`) must load it in a child scope with
  `Set-StrictMode -Off` (`& { Set-StrictMode -Off; . $lib; ... }`), because the real workflow scripts
  that consume those libs (`open-pr.ps1`, `new-branch.ps1`, `fold-changelog-entry.ps1`, …) never
  enable StrictMode, and both libs are explicitly written on that no-strict-mode assumption. Probe the
  functions (`Get-Command`) inside that same block so the dot-sourced definitions stay visible while
  nothing leaks into the check's own strict scope. Load under strict mode instead, and a consumer copy
  carrying harmless pre-strict-mode loose top-level code (an `if` on an unset variable, say) throws on
  the dot-source — a false `[ERROR]`, or under `$ErrorActionPreference = 'Stop'` a full crash — at
  every session start, for exactly the older consumer repos these checks exist to serve. A genuine
  load failure (a real syntax error) should degrade to a sane default or a reported `[ERROR]`, not
  abort the check. Recognized while building the script-contract check for inbound #147 (#148) and
  immediately found in its sibling `check-roster-sync.ps1` (#149).
- **A check's `[ERROR]` text is a consumed interface, not just prose.** `skills/sync-roster/sync-roster.ps1`
  does not re-implement detection — it *parses* `check-roster-sync.ps1`'s finding lines with a regex
  (`\[ERROR\]\s+(?:agent|persona) '(?<id>\d{2}-\d{2})' \(...\) has no (roster row|repo-lens)`). So
  rewording or widening a finding silently changes what the recovery skill can act on. Inbound #204
  hit exactly that: extending the check to persona-only specialists made it emit
  `persona '01-01' ... has no roster row`, which the then-`agent`-only pattern did not match — while
  both the check's own report *and* the session hook point the reader at that skill to stage the
  catch-up. Left alone it would have shipped advice that looks helpful and does nothing, for precisely
  the findings the change introduced. The rule: when you touch a finding's wording or scope, grep for
  who parses it before you touch the message. The integration tests in
  `scripts/tests/sync-roster.tests.ps1` drive the REAL check (not a stub) for exactly this reason, so
  they do fail on a wording change — treat that failure as the coupling reporting itself, not as a
  test to patch.
- **Verify a diagnosability fix against real data, not against the diff.** A report that "names the
  thing" reads correct in review and can still be useless in practice. The #203 fix made
  `check-connectors` label each finding with its connector — provably right, fully tested, and still
  producing two word-for-word identical lines when run against this repo's own register, because that
  consumer registers *two* plugins and both were behind on one outdated install. The distinguishing
  `-- plugin:` header was the very thing the hook filters away. Only running it surfaced that; the
  label now carries `<repo> / <plugin-id>`. For any change whose whole purpose is "make the output
  actionable", run it against the real register/repo before calling it done — a fixture proves the
  mechanism, not the usefulness.
- This repo is **public**: config never contains secrets.

In short: the **how** (managing the harness, scripts, config, safety guards) is portable; the **what**
(the plugin lint + drift lint, `branch-info.ps1`, `.claude/settings.json` with the github source, and
the marketplace/plugin manifests) belongs to this repo.
