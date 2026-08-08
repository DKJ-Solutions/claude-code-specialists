---
id: 15
group: 05
---

# Sylvester ⚙️ · claude-code-specialists addendum

> Repo-lens (claude-code-specialists) accompanying the portable playbook in the `specialists` plugin (`plugins/specialists/manuals/05-15-manual.md`). This file does not describe the craft, but what Sylvester does in this repo.

A system administrator does the same thing everywhere — manage the harness and the tooling the team
works in: scripts, config, the safety guards. **What is repo-specific in claude-code-specialists is not
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
  mismatch can only mean a forgotten regeneration or a hand-edit. **Check 11 is the one that guards a
  doc against reality rather than against itself:** every printed `claude plugin
  install`/`update`/`uninstall` — recognised by its `@`-target, which is what separates an instruction
  from prose discussing the command — must carry `--scope project`, and `install`/`update` must name
  the marketplace refresh nearby. Both fail *silently* when missing, which is why three adoption
  rounds in a row found this same class and four doc fixes only ever closed the instances. History
  (`CHANGELOG.md`, `releases/**`, `RELEASE.md`, root entry files) is excluded permanently: it records
  what was true then. Since #315 the scope rule is **verb-specific** — `uninstall` also accepts
  `--scope local`, because that is the only command that removes a record a session start left at that
  scope, and a gate demanding `project` there would have rejected the correct instruction and enforced the
  assumption round v8 disproved. **Check 12 is check 11's sibling, the same idea one level up:** a fenced
  block that reads `installed_plugins.json` *in code* must select `projectPath`, `scope`, `version` **and**
  `gitCommitSha`. It came out of round v8, whose three findings (#313/#314/#315) read as unrelated and were
  one class — the family's own verification query printed a green that could not distinguish the release
  from `main` after it, one record from two, or `project` from `local`. Closing those three by hand would
  have been the fourth round in a row to close *instances* of a class that kept coming back. Both checks
  answer the same **mention vs. use** question with a positional discriminator (check 11 the `@`-target,
  check 12 "does the block actually parse the file"), which makes this the third instance of that reasoning
  in this file. **Check 18 guards the shared source against its own documentation:** every parameter of a
  mirrored entry point must be named in the skill that documents it, because a consumer has only the mirror
  and that page — so a parameter the page never names does not exist for them, escape valves included. It
  is a repair with a measured cause (August 4, 2026): the `fold-changelog` skill told consumers to commit
  the fold *by hand* for two days after the script gained `-Commit`/`-Push`, since that improvement was
  written into this repo's lens. Four more surfaced immediately, `-Bump` and `-NoPush` among them — the
  latter being the only step where a human sees the assembled release before it is public. Two design notes
  worth keeping: the mapping and the per-parameter exemptions are declared **in the registry beside the
  registration**, the same reasoning `LibOnly` already carries, so a newly shared script cannot fall out of
  the check silently; and parameters are read via the **PowerShell parser**, because the regex first used
  for it missed a `[Parameter(...)]`-attributed parameter and would have given the gate the exact blind
  spot it exists to close. An entry point declaring *no* skill is reported in the coverage line rather than
  as an error — `ship-pr`, `fix-mojibake`, `verify-resolved-issues` and `check-script-contract` are in that
  state today, and the first three are real gaps rather than deliberate ones. This is the safety guard that
  [Derek #05](05-05-extension.md)'s `open-pr.ps1` runs before every push — and that `cut-release.ps1`
  runs before a release.
- **`.github/workflows/ci.yml`** — the CI gate on GitHub: runs the same lint gate + all test suites
  (`scripts/tests/*.tests.ps1`) on every PR and every push to `main`, so the guard also applies to
  work that comes about outside `open-pr.ps1`. **"The same" is literal since August 7, 2026** — the step
  dot-sources `native-capture-lib.ps1` and calls `Invoke-TestSuiteGate`, the one function `open-pr.ps1`
  and `cut-release.ps1` also call. It held its own inline `foreach` until then, which is how a gate
  improvement can land in both local callers and miss the only one that actually blocks a merge; the
  asserts that keep it from coming back are in `cut-release-guardrail.tests.ps1`. It passes
  `-MaxParallel ([Environment]::ProcessorCount)` deliberately: the lib's default holds two cores back so a
  developer's machine stays usable, and on a four-core runner nobody is sitting at, that reservation would
  cost half the box. Since July 15, 2026, the repo ruleset
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
- **`scripts/lib/pr-issues-lib.ps1`** — the pure decision table of the **resolves gate**: which issues
  a text mentions, which a body actually *closes*, and whether a PR may open without declaring either.
  Deliberately pure (no `git`, no `gh`, no filesystem) so [Tycho #18](04-18-extension.md) can assert
  every branch of it offline; the one impure part — asking GitHub which issues are open — stays in
  `open-pr.ps1`. Shared/mirrored, since `open-pr.ps1` dot-sources it. The rule it enforces and the
  incident behind it are [Derek #05](05-05-extension.md#opening-a-pull-request)'s.
  **Two traps that cost real debugging while building this lib**, both measured and both now pinned by
  asserts:
  - **`powershell -File` cannot bind an `[int[]]`.** `-Resolves 332,340` arrives as the string
    `'332,340'` and is cast to the single number **332340** — the comma read as a *thousands
    separator*. No error, just a wrong issue. Hence a `[string]` parameter parsed by
    `ConvertTo-IssueNumberList`, and hence the fixture passes it over that same `-File` hop.
  - **`@(… | ConvertFrom-Json)` does not flatten a JSON array in PowerShell 5.1.** 5.1 emits the
    parsed array as *one* pipeline object, so `@()` collects a single element that IS the array, and
    `$_.number` then does member enumeration and hands `[int]` an `Object[]` that throws. Assign
    first, then wrap: `$parsed = … | ConvertFrom-Json; @(@($parsed) | …)`. That throw was swallowed by
    a `catch` that degrades the gate to "cannot check" — so the gate silently never blocked **while
    every pure unit test stayed green**. Only the wiring fixture caught it, which is the general
    lesson: a pure decision table proves the decision, never that it is reached.
- **`scripts/lib/release-lib.ps1`** — the pure release helpers (version bump, emptying `CHANGELOG.md` down
  to its intro, and the assembly of the `releases/development/` notes)
  that [`cut-release.ps1`](../../../scripts/release/cut-release.ps1) dot-sources; deliberately
  pure so [Tycho #18](04-18-extension.md) can test them in isolation. The release *process* is
  [Rendall #06](05-06-extension.md)'s domain; Sylvester guards the script mechanics underneath.
- **`scripts/agents/build-agent-defs.ps1` + `scripts/lib/agent-shared-lib.ps1`** — the generator
  that fills the verbatim-shared bullets from
  `plugins/agent-shared/<name>.md` into all agent defs (between
  `<!-- BEGIN/END shared:… -->` sentinels). Change a shared block →
  run `build-agent-defs.ps1` → all agent defs updated; `-Check` (and the lint gate, check 7) fails
  on drift. The pure expansion logic lives in the lib, so [Tycho #18](04-18-extension.md) can test
  it in isolation — mirroring the `release-lib` setup. **Never edit between the sentinels by hand.**
- **`.claude/settings.json`** — this repo's harness config: the `extraKnownMarketplaces` (the
  `github` source `DaveKJohn/claude-code-specialists`) and `enabledPlugins` with which the repo enables
  its own `specialists` plugin (group 1).
- **The manifests** `.claude-plugin/marketplace.json` and every `<plugin>/.claude-plugin/plugin.json`
  (structure + `version`) — their *structure/config*; the descriptive *texts* he coordinates with
  [Tessa #16](06-16-extension.md).

### Repo-specific rules

- **The shared-scripts registry spans TWO plugins since August 8, 2026, and the plugin is read off the
  mirror path rather than declared.** `Get-SharedScriptPairs` maps each source to a mirror in either
  `plugins/specialists/` (the core: `check-roster-sync`, `check-report-lib`) or
  `plugins/specialists-workflow-davekjohn/` (everything branch- and release-shaped). Three things to
  know before touching it:
  - **`SkillRel` is derived from `MirrorRel`, not stored.** Check 18 and `shared-scripts.tests.ps1`
    both used to look for a script's documenting page at a hardcoded `plugins\specialists\skills\…`,
    and the moment nine entry points moved, the gate reported every one of their existing skills as a
    typo. A second field naming the plugin would have been free to disagree with the path beside it;
    deriving it means a script that moves takes its page lookup with it.
  - **`check-report-lib` is registered TWICE on purpose** — one source, two mirrors — because
    `check-roster-sync` stayed in the core while `check-script-contract` went to the pack. The
    alternative, a mirror reaching into the other plugin's cache, was rejected on sight: separately
    versioned, separately installed, so a version mismatch breaks it silently. **A duplicate entry
    needs a distinct `Name`**: the suite looks pairs up with `Where-Object { $_.Name -eq … }` in
    eleven places and would get an array back.
  - **The thing that parked this work for days was a MENTION read as a USE — the fifth instance in
    this file.** The note that stopped it said `check-report-lib` and `native-capture-lib` each had
    readers in both halves. Neither did: `open-pr`/`fold-changelog-entry` name the first only in a
    comment, and `check-report-lib` names the second to say it *needs none of* its EAP dance. Both
    rows dissolved on being read. The assert that now refuses any mirror dot-sourcing a lib from the
    other plugin is in `shared-scripts.tests.ps1` — write the check that would have caught the
    misreading, not just the fix.
- **A scaffold with nothing to fill in is invisible to a placeholder test.** The same split gave a
  core-only consumer a `repo-config.ps1` holding just the roster pair — complete as generated, so no
  `VUL-IN` value anywhere. `specialists-teardown` classifies by placeholder VALUE (the #333 lesson),
  so it read that file as authored and would have kept it forever, making adoption exactly as
  irreversible as that skill promises it is not. The second recognised shape keys on "still exactly
  what the bootstrap wrote", which is conservative in the right direction: every way an owner can
  touch that file ADDS something. **General rule: when a generator gains a mode that emits no
  placeholder, check every consumer that classifies its output by one.**
- **The agent-def frontmatter and the `plugin.json` `version` land here first**, never in a consuming
  repo — those pull them in. An agent-def config change is Sylvester's side; the agent-def *text* is
  Tessa's side.
- **The lint gate may never become quieter than the risks.** As the repo grows (more plugins, more
  complex manifests), Sylvester extends the checks — with [Tycho #18](04-18-extension.md) building
  tests alongside.
- **The test gate is bound by its SLOWEST SINGLE SUITE, not by their sum — so the next second saved is
  bought inside one file.** Measured August 7, 2026 on the same machine within one session, all 27 suites
  green every time: **510s one at a time, against 128–263s parallel over six runs (median 159s)**
  ([#512](https://github.com/DaveKJohn/claude-code-specialists/issues/512)). **That spread is the mechanism,
  not noise** — a sum averages its own variance out, a maximum does the opposite, so a gate bound by its
  slowest suite is inherently less predictable than one bound by the total. Quote the range rather than the
  best run: the first parallel measurement taken was the 128s one, and on its own it would have promised a
  4× improvement the gate delivers only sometimes. **CI gains less, and for a stated reason:** its runner
  has four cores against this machine's eighteen, so the throttle is four wide and the `lint-en-tests` job
  went from about eleven minutes to **7m2s**. What made that safe rather than
  lucky was checked before it was built, not after: no suite writes into the repo tree (every `$RepoRoot`
  reference is a read, or a `Copy-Item` *out of* it into a fixture), and no two suites share a fixture path
  — the fixed-name ones each own their name, the rest key on `$PID`. **Re-check both before adding a suite
  that touches either.** The remaining half of #512 is now the whole critical path:
  `check-plugin-integrity.tests.ps1` spends its ~154s on **86** `Invoke-Integrity` calls, each a fresh
  `powershell` start (~0.18s) plus a full lint over its fixture (~1.6s) — real work, not waste, and it
  cannot be parallelised the way the gate was, because all 86 scenarios mutate **one** fixture directory in
  sequence. `-MaxParallel 1` is the valve, and it is worth reaching for before believing a suite that only
  fails with 26 siblings competing for the disk.
- **Renaming or moving this checkout unlinks its own plugin install — plan the re-install into the same
  move.** Because this repo consumes itself, it is a consumer like any other, and the install record is
  keyed on `projectPath`. Measured August 3, 2026: after the directory was renamed from
  `davekjohns-workshop` to `claude-code-specialists`, `.claude/settings.json` still enabled
  `specialists@claude-code-specialists` correctly while the machine's only record named the old folder,
  so the session loaded no subagent, skill or hook at all. Recognize it by a **deliberate** run of
  [`check-roster-sync.ps1`](../../../scripts/sync/check-roster-sync.ps1) reporting
  `[NOT-INSTALLED-HERE]` — the session-start hook cannot report it, because that hook ships in the
  plugin that did not load. The repair is `claude plugin marketplace update claude-code-specialists`
  followed by `claude plugin install specialists@claude-code-specialists --scope project` from the new
  root, after which a leftover record naming the old folder is expected and inert. The mechanism, the
  other two ways a record goes missing, and why that leftover is not a stray duplicate are in the
  family's [INSTALL.md](../../../plugins/INSTALL.md#staying-up-to-date);
  don't restate them here.
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
- **Mask fenced code blocks before you pair inline backticks — a fence silently shifts every span
  after it.** A `` `[^`]+` `` pattern cannot open a span on the first two backticks of a ``` `` ``` run,
  opens one on the third, and closes it on the *first* backtick of the closing fence; from there every
  real inline span in the file pairs one position out. Nothing errors, so a scan built on those spans
  reads the wrong text and reports a plausible answer. Measured on July 31, 2026 while building check
  11: a command whose flag sat on the next line of its own span came back looking **flagless**, i.e.
  the gate under-reported rather than raising. `Get-FenceMaskedText` in
  [`check-plugin-integrity.ps1`](../../../scripts/lint/check-plugin-integrity.ps1) already solves this
  and keeps offsets and newline positions identical, so a span found in the mask indexes straight back
  into the real text — reuse it rather than writing a second fence walker. Sibling rule for the same
  scan: judge one command's own arguments, not the whole span, or two commands in one span let the
  second borrow the first one's flags (Victor, same build).
- **`return @($x)` does not return an array when `$x` is one item — and indexing the result then yields
  a character.** PowerShell unrolls a single-element array on return, so a helper written as
  `return @(...)` hands back a bare `[string]`; `$result[0]` is then its first *letter*, and
  `$result.Count` is `1` either way, so the length guard that was supposed to protect the index passes.
  Measured the same day in `teardown-protocol.tests.ps1`, where a check-ignore line's first field read
  as `.` instead of `.gitignore:2:`. Rule: wrap at the **call site** too — `$r = @(Get-Thing ...)` —
  whenever you are going to index or slice, and do not rely on `@()` inside the function. Same family
  as the two rules above: the wrong answer arrives as a plausible value instead of an error, which is
  the failure mode this repo's gates exist to catch and therefore the one its own tooling must not
  have.
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
- **A documented rule is not a mechanism, and a silent signal is not a signal.** The connectors README
  had carried "after a refresh, also update the manifest" for days when a deliberate run of
  `check-connectors.ps1` found eleven inventory-drift findings at once — six in this repo's own
  register, where the lenses had landed with PR #212 and the inventory was never updated alongside. The
  rule was on the books and had been followed exactly zero times, because the finding is an `[INFO]` and
  the session hook surfaces only `[ERROR]`: nothing ever reported the omission, so nothing ever
  prompted anyone. Writing the rule down more firmly would have changed nothing. What changed it was the
  non-counting `[INVENTORY]` marker (July 29, 2026) — the third instance of the
  `[UNREGISTERED]`/`[ORPHANS]` shape. **When a rule depends on someone remembering a follow-up step, ask
  what would report the omission; if the answer is "a deliberate run nobody has a reason to make",
  the rule needs a mechanism, not a sharper sentence.**
- **`Write-Host` output is invisible to a same-process pipeline, so an in-process assertion about it
  silently passes.** While verifying the `[INVENTORY]` marker by hand, `$out = .\check-connectors.ps1;
  @($out | Where-Object { $_ -cmatch '\[INVENTORY\]' }).Count` returned 0 for the case that *should*
  emit it — the line was plainly visible on the console, but `Write-Host` writes to the host and never
  enters the pipeline. Both the positive and the negative case therefore "passed", which is the
  dangerous half: a scoping test that can only ever read 0 proves nothing. The checks use `Write-Host`
  throughout (deliberately — it carries `-ForegroundColor`), and the hook only captures it because it
  runs the check as a **child process**, whose stdout *is* captured. So: verify these scripts the way
  the hook consumes them, via `& powershell -File …`, and treat a negative assertion that cannot
  distinguish "absent" from "uncapturable" as no assertion at all. The suite in
  `scripts/tests/connectors.tests.ps1` already does this correctly through `Invoke-Ps`.
- **Run a suite from the tree it is meant to judge — `$PSScriptRoot` follows the file, the working
  directory does not.** `roster-sync.tests.ps1` asserts that the git-root fallback lands on the repo the
  test runs inside. Invoked by absolute path out of a linked worktree while the shell's CWD was still
  the main checkout, it failed on exactly that assertion: `git rev-parse --show-toplevel` answers for
  the *process's* directory, not for the script's. 125 pass, 1 fail — a red suite caused entirely by
  where it was launched from, and the temptation is to read it as a real regression in the branch under
  test. `Push-Location <worktree>` around the run (or `git -C`) is the whole fix. **Sibling of the
  `Write-Host` trap above, and the same underlying mistake: verifying from the wrong vantage point.**
  One produced a false pass, this one a false failure — so the rule is not "distrust green" or
  "distrust red" but: before believing either verdict, confirm the check was observed from the same
  place its real consumer observes it. Both instances happened on July 29, 2026, within one session.
- **The non-counting marker is a standing pattern now, not a series of exceptions.** Five instances:
  `[ORPHANS]` (inbound #204), `[UNREGISTERED]` (#208), `[INVENTORY]` (#220), `[BOOTSTRAP]` (#225) and
  `[RECORD-SHAPE]` (#314/#315 — reached for rather than invented, which is this bullet working as intended).
  Each solves the same problem — a finding that is **real, actionable, and about the repo the session is
  in**, but that would be wrong as an `[ERROR]` because nothing is broken and a red line plus exit 1
  would be a lie. Each is also the answer to a specific failure: an `[INFO]` the session hook suppresses
  is, from the reader's seat, indistinguishable from no finding at all. **The recipe:** emit a dedicated
  bracketed token with `Write-Host` (never through `Write-Failure`/`Write-Info`, so the summary count
  and the exit code stay untouched), have the hook match it with its own `-cmatch` outside the
  `$signals` list, and give it **its own verdict line** rather than folding it under an existing one —
  `[BOOTSTRAP]` arrives on an exit-0 run, so without that branch it would have fallen through to
  "roster in sync", which for a repo with no roster is a flat untruth. When a fifth case appears, reach
  for this shape before inventing a new one, and ask the classification question first: if the finding
  could indicate tampering or a genuine breach it must be an `[ERROR]`, per the connectors README rule.
- **A repo-wide verdict must be computed where the evidence is complete, not where it is convenient.**
  The first `[BOOTSTRAP]` implementation short-circuited *before* the plugin-resolution loop, since that
  is where the predicate (no lenses, no roster rows) is cheapest to evaluate. It shipped a regression
  immediately: a repo whose plugin is enabled but **not present in the cache** was told to run
  `specialists-init`, when the real cause was that the plugin is not installed on that machine at all —
  two states that look identical from outside the loop and need opposite advice. The fix was to let the
  loop run, suppress only the two findings the marker replaces, count them, and emit the marker
  afterwards; everything else the check knows (not-in-cache, orphans, off-path lenses) still reports.
  `roster-sync.tests.ps1` caught this within one run, which is the argument for adding the guard case in
  the same commit as the feature rather than after it.
- **`Select-Object -First N` kills a child process mid-run; `-Last N` cannot.** The `$LASTEXITCODE`
  rule above says not to pipe a native command through a cmdlet — this is the sharpest instance and
  the discriminator that makes it predictable. `-First N` tears the pipeline down the moment N items
  are in, and the still-running upstream process dies with it; `-Last N` has to drain the entire
  stream to know what the last N are, so it is harmless. Measured on July 29, 2026 while measuring the
  fresh-consumer install: piping `bootstrap.ps1` into `-First 1` created **zero** lenses and reported
  nothing wrong, and into `-First 20` it wrote 19 lenses and exited **255** — while `-Last 25` on the
  identical command completed normally with exit 0. Both truncations look like display choices in the
  diff. The consequence was worse than a crash: the harness went on to measure an *unbootstrapped*
  repo and label the numbers "after bootstrap", and the first explanation reached for was a bug in
  `Get-DerivedRepoName` — a real hypothesis, tested across three git states (no repo / repo without
  remote / repo with remote), all exit 0. **So: capture a child process's output into a variable in
  full, then slice the variable — and when setup runs before a measurement, check its exit code and
  abort rather than measuring past it.**
- **MENTION vs USE — the day's recurring defect, and the rule that covers all three.** Three separate
  checks were satisfied by text that merely *named* the thing they look for, rather than *using* it:
  `check-roster-sync` counted an `@`-import path as a roster row because the path contains the id
  (#227); the lint gate's check 10 read a marker quoted in changelog prose as a real enumeration, on
  `main`, where no PR gate could see it (#235); and `specialists-teardown` classified a fully configured
  `repo-config.ps1` as an unfilled scaffold because the scaffold's own **docstring** still says "fill in
  the remaining VUL-IN values" — which is the *normal* state of a filled-in scaffold, not an edge case.
  That third one would have **deleted** the file `open-pr`, `fold-changelog`, `new-branch` and
  `check-roster-sync` all depend on, and only a dry run against a real consumer
  (`davekokbwj/smartwatchbanden`, July 29, 2026) surfaced it — every fixture had scaffolds that were
  either untouched or rewritten, never the real-world middle state.
  **The rule: when a check's evidence is "this string appears in the file", ask what else in that file
  legitimately contains it — docstrings, prose, links, paths — and key on the string in a POSITION that
  only real use produces.** A placeholder in an assignment's *value*, an unfilled slot *heading*, an
  empty table. And for a script that deletes, resolve every remaining doubt toward keeping: a false
  keep leaves clutter, a false remove destroys someone's work.
- **A gate can only fail on the files it scans — and a *transient* file is where that goes wrong.** The
  lint gate's scan set (`$linkFiles`, feeding both check 4's link scan and check 10's skill spans) listed
  every permanent doc but not the root changelog **entry** files. So an entry's text was invisible while
  the PR was open and became visible only at **fold** time — directly on `main`, in one of the two
  sanctioned direct-on-`main` actions, past every PR gate. The error then surfaced at the next full gate
  run, `cut-release.ps1`, which is why v2.13.0 was blocked by a changelog sentence. Note the shape: no
  check was wrong, the *timing* was — the gate's verdict was "green so far", not "green" (#234, closed
  July 29, 2026 by adding root entry files to the set, keyed on the entry format's `###` heading, so a
  permanent root doc with its `#` heading never joins). **The rule: when a gate checks file A and some
  other step copies text into A, the gate must also check where that text was authored.** Ask which file
  the content was *written* in, not which file it ends up in.
- **A check that scans a file for a token can be satisfied by a *path* containing that token.**
  `check-roster-sync` looks for each `<group>-<id>` in the roster file, and the bootstrap wrote
  `@.claude/plugins/claude-specialists/specialists/01-01-extension.md` into `CLAUDE.md` (the pre-seam
  lens path of the time; since #253 it writes the one seam line instead). That import
  line contains `01-01`, so Chris counts as rostered without a roster row ever existing — measured
  July 29, 2026: 18 ids reported missing after a bootstrap, not 19, with `01-01` the one silently
  passing. It is the worst possible id to lose, because a persona appears in no always-on listing at
  all and the roster row is the *only* thing that makes him exist for a session. Same class as the
  roster token-boundary fix in v2.6.0, so treat that fix as incomplete rather than done: **when a
  check's evidence is "the token appears in the file", ask what else in that file legitimately
  contains the token — a path, a link, a changelog line — before trusting a pass.**
- **Restoring a file with `Set-Content -Encoding utf8` is not a restore.** PowerShell 5.1's `utf8`
  means *with BOM*, so writing a captured `$orig` back leaves a byte-level diff (`M-oM-;M-?{`) on a
  file that was BOM-less — a "clean" restore that shows up as a modified file. When a probe needs to
  mutate a tracked file temporarily, undo it with `git checkout -- <path>` rather than rewriting the
  captured content.
- **`claude plugin marketplace remove` rewrites the *project* `settings.json` of the working directory you
  run it from — not only the scope the marketplace was declared in.** Measured on July 29, 2026 while
  cleaning up the two throwaway plugins of the [#215](https://github.com/DaveKJohn/claude-code-specialists/issues/215)
  experiment: it emptied the test consumer's `enabledPlugins` **and** `extraKnownMarketplaces`. So run it
  from a throwaway directory, never from a repo whose `.claude/settings.json` you want to keep. The full
  account, including how the damage was spotted, is in
  [PR #256](https://github.com/DaveKJohn/claude-code-specialists/pull/256)'s changelog entry.
  **And the lookup lesson that came with it:** the first version of this bullet declared the mechanism
  unrecorded and left it at an operating rule, because it went looking in the lenses and the manuals. It
  was on record all along — in that PR's entry, folded into `CHANGELOG.md` one commit earlier. Before
  writing "this was never captured", grep `CHANGELOG.md` and `releases/**` too: an entry body is where
  this repo's findings land *first*, and a lens is usually the second home, not the first.
- **When a tool refuses with "auto mode cannot determine the safety", retry it — do not route around it
  via the Bash tool.** A recurring platform fault on July 29, 2026 made PowerShell and Edit calls refuse
  intermittently; it comes and goes, and a plain retry clears it. That the Bash tool can usually do the
  same work is exactly the trap, because it makes the workaround feel like resourcefulness: reaching for
  it converts a transient refusal into a deliberate bypass of the safety decision that produced the
  refusal. The refusal is not the obstacle to route around — it is the mechanism working. Wait it out.
- This repo is **public**: config never contains secrets.

In short: the **how** (managing the harness, scripts, config, safety guards) is portable; the **what**
(the plugin lint + drift lint, `branch-info.ps1`, `.claude/settings.json` with the github source, and
the marketplace/plugin manifests) belongs to this repo.
