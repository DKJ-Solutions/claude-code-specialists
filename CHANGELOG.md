# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #184 · cut-release skill: the closing-steps checklist, not a mirrored script · Feat · 2026-07-26

Inbound issue #177 (source: `DaveKJohn/djcylow-react`) asked for `cut-release.ps1` as a shared
skill, on the assumption that a shareable version of it exists. It does not: this workshop's own
`scripts/release/cut-release.ps1` is 284 lines of marketplace-specific machinery — it reads
`.claude-plugin/marketplace.json` as the source of truth for what a plugin is, bumps every
`plugin.json` in lockstep, writes per-plugin `CHANGELOG.md` sections and `RELEASE.md` cards, and
fills `releases/README.md` — and dot-sources `scripts/lib/release-lib.ps1`, which is deliberately
not mirrored into the plugin. Mirroring it as-is would have handed a fresh consumer a script that
stops on `.claude-plugin/marketplace.json is missing` on its very first line. Rebecca's research put
three scopes to Dave: mirror a generalized script (a large rebuild of the most sensitive script in
the repo, and more than the issue's real problem needs), add only the config slot without a skill
(leaves the actual forgotten-tag problem unsolved), or codify the closing procedure as a checklist.
Dave picked the recommendation — the checklist.

**What shipped is a checklist, not automation** — the issue's own words: *"not automation, but a
checklist that imposes itself."* The new `cut-release` skill
(`claude-code-plugins/claude-specialists/specialists/skills/cut-release/`) prints the closing steps
of a release as ready-to-paste command blocks, in a fixed order, and mirrors no script:

- **Block 1 — cutting (always):** the annotated tag + push, a `gh release create` +
  `gh release upload` for a Minor/Major bump, and branch cleanup.
- **Block 2 — going live (only where applicable):** the push to the live target, then moving the
  `<- LIVE` marker. Driven by a new optional `Get-LiveStage` in `scripts/repo-config.ps1` (empty by
  default, so this workshop and life-hub get Block 1 only) — the same optional pattern
  `Get-ChangelogHeading` established for #178, added to the `specialists-init` bootstrap scaffold and
  declared in `check-script-contract.ps1` as an `Optional` record, so a consumer without the function
  gets `[INFO]` naming the fallback, never `[ERROR]`.

Bakes in life-hub's hard-won split: the **highlights** become the GitHub Release body, the full
development notes go along as an **attachment** — at life-hub's v2.1.0 the notes were 134,419
characters and `gh` returned HTTP 422 (the release-notes body limit is 125,000 characters). The
skill prescribes that split explicitly so no consumer trips over it again.

Plugins: specialists

[PR #184](https://github.com/DaveKJohn/davekjohns-workshop/pull/184)

---

### #183 · fold-changelog folds into a configurable section heading · Fix · 2026-07-25

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

Plugins: specialists

[PR #183](https://github.com/DaveKJohn/davekjohns-workshop/pull/183)

---

### #181 · Life-hub register: stale notes and four unregistered lenses · Fix · 2026-07-26

`scripts/sync/check-connectors.ps1` flagged four `[INFO]` signals: lenses 06-24, 06-25, 06-29, and
06-30 exist in the life-hub checkout (verified as owned by `specialists@davekjohns-workshop` via
`Get-PluginIds`) but were never added to
`claude-code-plugins/claude-specialists/connectors/life-hub.json`'s extension list. Registered them.

The `notes` field had also gone stale and was being read as current truth — it claimed the
life-hub session ran on "another machine" needing an update to a specific version ("v1.10.0"),
both wrong, and still carried an action item (registering 06-24) this change now performs.
Commit `fde6556` had already removed version bookkeeping from the register on purpose (the check
reads the installed version from the machine record instead), so a version number in `notes` didn't
just go stale, it contradicted the register's own design. Rewrote `notes` down to the one thing
that is still timeless: the lens-only model for the four personas (01-01, 03-02, 05-05, 05-06) —
no machine claims, no version numbers, no dangling to-do.

[PR #181](https://github.com/DaveKJohn/davekjohns-workshop/pull/181)

---

### #180 · Lens path: the family segment is a constant, and every reader shares it · Fix · 2026-07-25

`specialists-init` and the roster check disagreed about **where a repo lens lives**: one wrote a
derived path, the other read a hardcoded one, and they only lined up by coincidence.
`bootstrap.ps1` derived the family segment from the install path, which in the plugin-cache layout
(`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`) yields the **marketplace name** — so a
repo installed through `specialists@davekjohns-workshop` got its lenses in
`.claude/plugins/davekjohns-workshop/specialists/`, where `check-roster-sync.ps1` never looked. In
`djcylow-react` that produced **30 errors of which 24 were false**: 12 perfectly good lenses, each
counted twice (missing lens + missing roster row). Worse than a plain miss — the fix the report
suggested would have left the repo with two copies of every lens on two paths, with the `@`-import
in `CLAUDE.md` still pointing at the wrong one.

**One source, used by writers and readers alike.** `scripts/lib/check-report-lib.ps1` (mirrored into
the plugin) gains two helpers:

- **`Get-LensFamily`** — the family segment as a **constant** (`claude-specialists`). It is a
  property of the plugin family, not of the marketplace the plugin was fetched from, so it is no
  longer derived from anything. The writers use it: `bootstrap.ps1` (both the lens path and the
  `@`-import it writes into `CLAUDE.md`) and `sync-roster.ps1`.
- **`Get-LensDirCandidates`** — the ordered locations a lens may be read from: the canonical path
  first, then any other family segment a pre-fix bootstrap left behind, then the legacy
  `.claude/extensions/`. Every reader now walks that list: `check-roster-sync.ps1`,
  `check-connectors.ps1`, and `check-consumer-drift.ps1` — the last two carried the same hardcoded
  segment and therefore the same false-missing bug.

Consequence: **no migration needed.** A consumer bootstrapped before this fix keeps working — its
lenses are found and counted as present, and the check adds one soft `[INFO]` per directory (not per
lens) pointing at the misalignment. `sync-roster` additionally refuses to write a scaffold when a
lens for that id already exists on a non-canonical path, so it can never produce the second copy.

Covered by regression tests in `scripts/tests/roster-sync.tests.ps1` (scenario 9b: off-path lenses
are found, no false `[ERROR]`, exactly one `[INFO]` per directory) and
`scripts/tests/bootstrap-drift.tests.ps1` (the version-cache scenario now asserts the canonical path,
no lenses under the marketplace name, and a canonical `@`-import). From inbound issue #179 (source:
DaveKJohn/djcylow-react).

Plugins: specialists

[PR #180](https://github.com/DaveKJohn/davekjohns-workshop/pull/180)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
